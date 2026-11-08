package com.openlist.mobile.utils

import java.net.Inet4Address
import java.net.NetworkInterface

object NetworkUtils {
    /**
     * Non-loopback IPv4 addresses of interfaces that are up. Uses the Java API
     * because Go's net.Interfaces needs netlink, which Android 11+ denies.
     */
    fun localIPv4Addresses(): List<String> = runCatching {
        NetworkInterface.getNetworkInterfaces()?.toList().orEmpty()
            .filter { it.isUp && !it.isLoopback }
            .flatMap { it.inetAddresses.toList() }
            .filterIsInstance<Inet4Address>()
            .map { it.hostAddress.orEmpty() }
            .filter { it.isNotEmpty() }
            .distinct()
    }.getOrDefault(emptyList())
}
