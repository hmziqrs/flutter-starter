package com.example.starter

import android.view.KeyEvent

class TvActivity : PlatformAwareFlutterActivity() {
    override val isAuthoritativeTvLaunch = true

    // Consume the standard remote Back key before Flutter turns it into both a
    // raw key event and an Activity Back callback. Dispatch one platform pop on
    // key-up so editors, dialogs, and routes retain Flutter's PopScope ordering.
    @Suppress("DEPRECATION")
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.keyCode == KeyEvent.KEYCODE_BACK) {
            if (event.action == KeyEvent.ACTION_UP && !event.isCanceled) {
                onBackPressed()
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    // A television remote emits a discrete Back key rather than a predictive
    // touch gesture. Route it through Flutter's navigation channel so nested
    // branch routes pop before Android finishes the TV activity.
    @Suppress("DEPRECATION")
    override fun commitBackGesture() {
        onBackPressed()
    }
}
