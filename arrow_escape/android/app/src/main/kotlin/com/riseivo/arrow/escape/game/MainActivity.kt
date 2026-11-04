package com.riseivo.arrow.escape.game

import android.os.Bundle
import com.facebook.FacebookSdk
import com.facebook.LoggingBehavior
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Dev builds log Meta app events to logcat (tag "FacebookSDK"), so
        // the CI emulator test can confirm events are sent.
        if (BuildConfig.FLAVOR == "dev") {
            FacebookSdk.setIsDebugEnabled(true)
            FacebookSdk.addLoggingBehavior(LoggingBehavior.APP_EVENTS)
            FacebookSdk.addLoggingBehavior(LoggingBehavior.REQUESTS)
        }
        super.onCreate(savedInstanceState)
    }
}
