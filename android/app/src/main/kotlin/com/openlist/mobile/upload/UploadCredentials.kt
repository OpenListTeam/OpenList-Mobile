package com.openlist.mobile.upload

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object UploadCredentials {
    private const val STORE = "openlist_upload_credentials"
    private const val KEY_ALIAS = "openlist_upload_credentials_key"
    private const val WORK_PREFIX = "work:"
    private const val TRANSFORMATION = "AES/GCM/NoPadding"

    fun store(context: Context, headers: Map<String, String>): String {
        val id = java.util.UUID.randomUUID().toString()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val encrypted = JSONObject(headers).toString().toByteArray(Charsets.UTF_8)
        val value = Base64.encodeToString(cipher.iv + cipher.doFinal(encrypted), Base64.NO_WRAP)
        check(context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .edit().putString(id, value).commit())
        return id
    }

    fun bind(context: Context, id: String, workId: String) {
        check(context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .edit().putString(WORK_PREFIX + workId, id).commit())
    }

    fun forWork(context: Context, workId: String): String? =
        context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .getString(WORK_PREFIX + workId, null)

    fun read(context: Context, id: String): List<Pair<String, String>> {
        val encoded = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
            .getString(id, null) ?: return emptyList()
        val bytes = Base64.decode(encoded, Base64.NO_WRAP)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, bytes, 0, 12))
        val headers = JSONObject(String(cipher.doFinal(bytes, 12, bytes.size - 12), Charsets.UTF_8))
        return headers.keys().asSequence().map { it to headers.getString(it) }.toList()
    }

    fun delete(context: Context, id: String) {
        val preferences = context.getSharedPreferences(STORE, Context.MODE_PRIVATE)
        val editor = preferences.edit().remove(id)
        preferences.all.forEach { (key, value) ->
            if (key.startsWith(WORK_PREFIX) && value == id) editor.remove(key)
        }
        editor.apply()
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            ).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build()
        )
        return generator.generateKey()
    }
}
