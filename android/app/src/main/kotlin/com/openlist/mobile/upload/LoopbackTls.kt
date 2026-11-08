package com.openlist.mobile.upload

import android.annotation.SuppressLint
import android.util.Base64
import com.openlist.mobile.model.openlist.OpenListConfigManager
import java.io.File
import java.io.IOException
import java.security.MessageDigest
import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/**
 * Trust for HTTPS uploads to the embedded core on loopback.
 *
 * The core serves a self-signed certificate, so system trust cannot verify
 * it. Instead the server's leaf certificate must equal, byte for byte, the
 * first certificate in the core's configured `cert_file`. Anything else,
 * including a missing or unreadable file, fails the connection.
 */
object LoopbackTls {
    private const val PEM_BEGIN = "-----BEGIN CERTIFICATE-----"
    private const val PEM_END = "-----END CERTIFICATE-----"

    fun isLoopbackHost(host: String?): Boolean =
        when (host?.trim('[', ']')?.lowercase()) {
            "127.0.0.1", "::1", "0:0:0:0:0:0:0:1", "localhost" -> true
            else -> false
        }

    /**
     * Pins [conn] to the core's certificate.
     *
     * @param onReject receives the reason a server certificate was refused,
     *   so the caller can report it instead of a generic handshake error.
     * @throws IOException when the configured certificate cannot be loaded.
     */
    fun pin(conn: HttpsURLConnection, onReject: (String) -> Unit) {
        val trust = PinnedTrustManager(coreCertificate(), onReject)
        val ctx = SSLContext.getInstance("TLS")
        ctx.init(null, arrayOf<TrustManager>(trust), null)
        conn.sslSocketFactory = ctx.socketFactory
        // The pin proves identity; the self-signed certificate need not name
        // the loopback address.
        conn.hostnameVerifier = HostnameVerifier { host, _ -> isLoopbackHost(host) }
    }

    /** DER bytes of the leaf in `cert_file`, resolved the way the core does. */
    private fun coreCertificate(): ByteArray {
        val config = OpenListConfigManager.configOrNull()
            ?: throw IOException("cannot read config.json for the server certificate")
        val path = config.scheme.certFile
        if (path.isBlank()) throw IOException("server certificate is not configured")
        // The core joins a relative path to its working directory. Both
        // processes are forked from zygote and never chdir, so user.dir is
        // that same directory.
        val file = File(path).let {
            if (it.isAbsolute) it else File(System.getProperty("user.dir") ?: "/", path)
        }
        val text = try {
            file.readText()
        } catch (e: IOException) {
            throw IOException("cannot read server certificate: ${e.message}", e)
        }
        val start = text.indexOf(PEM_BEGIN)
        val end = if (start < 0) -1 else text.indexOf(PEM_END, start)
        if (end < 0) throw IOException("no certificate found in ${file.name}")
        return try {
            val base64 = text.substring(start + PEM_BEGIN.length, end).filterNot { it.isWhitespace() }
            val der = Base64.decode(base64, Base64.DEFAULT)
            // Parsing rejects garbage that happens to be valid base64.
            CertificateFactory.getInstance("X.509").generateCertificate(der.inputStream()).encoded
        } catch (e: Exception) {
            throw IOException("invalid server certificate in ${file.name}", e)
        }
    }

    @SuppressLint("CustomX509TrustManager")
    private class PinnedTrustManager(
        private val pinned: ByteArray,
        private val onReject: (String) -> Unit,
    ) : X509TrustManager {
        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            val leaf = chain?.firstOrNull()?.encoded
            // Constant-time compare of the full DER encoding.
            if (leaf == null || !MessageDigest.isEqual(leaf, pinned)) {
                val reason = "server certificate does not match the configured certificate"
                onReject(reason)
                throw CertificateException(reason)
            }
        }

        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            throw CertificateException("client certificates are not trusted")
        }

        override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
    }
}
