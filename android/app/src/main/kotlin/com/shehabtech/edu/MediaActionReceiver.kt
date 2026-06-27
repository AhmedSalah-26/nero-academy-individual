package com.shehabtech.edu

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives media-action broadcasts sent from the notification buttons
 * and forwards them to [MainActivity] via a static callback.
 *
 * Only "open" and "close" actions are used now that the notification
 * shows a single "Continue Lesson" button.
 */
class MediaActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (!action.startsWith(ACTION_PREFIX)) return

        val mediaAction = action.removePrefix(ACTION_PREFIX)

        // If the main activity is alive, dispatch directly
        val handled = MainActivity.onMediaAction(mediaAction)

        if (!handled) {
            // App is not in foreground – bring it to front
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                this.action = action
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(launchIntent)
        }
    }

    companion object {
        const val ACTION_PREFIX = "com.shehabtech.edu.MEDIA_"
    }
}
