package com.openlist.utils

object NativeLib {
    external fun getLocalIp(): String

    init {
        System.loadLibrary("utils")
    }

}