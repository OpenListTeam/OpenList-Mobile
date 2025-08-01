package com.openlist.mobile.constant

import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.openlist.mobile.app
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json

object AppConst {
    @OptIn(ExperimentalSerializationApi::class)
    val json = Json {
        ignoreUnknownKeys = true
        allowStructuredMapKeys = true
        prettyPrint = true
        isLenient = true
        explicitNulls = false
    }

    val localBroadcast by lazy {
        LocalBroadcastManager.getInstance(app)
    }

//    val fileProviderAuthor = BuildConfig.APPLICATION_ID + ".fileprovider"
}