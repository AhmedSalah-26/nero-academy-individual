package com.neroacademy.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val notificationChannelId = "nero_academy_media"
    private val notificationId = 1204
    private val permissionRequestCode = 2401

    private var methodChannel: MethodChannel? = null

    // ------------------------------------------------------------------ //
    //  Flutter engine setup
    // ------------------------------------------------------------------ //

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    showMediaNotification(call.arguments as? Map<*, *>)
                    result.success(null)
                }
                "hide" -> {
                    hideMediaNotification()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Store reference so MediaActionReceiver can reach us
        instance = this

        createNotificationChannel()
        handleMediaIntent(intent)
    }

    // ------------------------------------------------------------------ //
    //  Lifecycle
    // ------------------------------------------------------------------ //

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleMediaIntent(intent)
    }

    override fun onDestroy() {
        if (instance == this) instance = null
        hideMediaNotification()
        super.onDestroy()
    }

    // ------------------------------------------------------------------ //
    //  Media notification — simple "Continue Lesson" button only
    // ------------------------------------------------------------------ //

    private fun showMediaNotification(args: Map<*, *>?) {
        if (args == null) return
        if (!hasNotificationPermission()) {
            requestNotificationPermission()
            return
        }

        val title    = args["title"]    as? String ?: getString(R.string.app_name)
        val subtitle = args["subtitle"] as? String ?: ""

        // "Continue Lesson" button opens the app / brings it to foreground
        val continueLessonLabel = args["continueLabel"] as? String ?: "Continue Lesson"

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setOnlyAlertOnce(true)
            .setOngoing(false)
            .setShowWhen(false)
            .setAutoCancel(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            // Tap notification body → open app
            .setContentIntent(broadcastIntent("open", requestCode = 10))
            // Swipe-dismiss → close
            .setDeleteIntent(broadcastIntent("close", requestCode = 14))
            // Single action: Continue Lesson
            .addAction(
                android.R.drawable.ic_media_play,
                continueLessonLabel,
                broadcastIntent("open", requestCode = 10)
            )
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }

    private fun hideMediaNotification() {
        NotificationManagerCompat.from(this).cancel(notificationId)
    }

    // ------------------------------------------------------------------ //
    //  Intent routing
    // ------------------------------------------------------------------ //

    private fun broadcastIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MediaActionReceiver::class.java).apply {
            this.action = "$ACTION_PREFIX$action"
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getBroadcast(this, requestCode, intent, flags)
    }

    private fun handleMediaIntent(intent: android.content.Intent?) {
        val action = intent?.action ?: return
        if (!action.startsWith(ACTION_PREFIX)) return

        val mediaAction = action.removePrefix(ACTION_PREFIX)
        if (mediaAction == "open") return   // just bring app to foreground

        methodChannel?.invokeMethod("mediaAction", mediaAction)
    }

    // ------------------------------------------------------------------ //
    //  Notification channel & permissions
    // ------------------------------------------------------------------ //

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            notificationChannelId,
            "Video playback",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Video playback progress"
            setSound(null, null)
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ActivityCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            permissionRequestCode
        )
    }

    // ------------------------------------------------------------------ //
    //  Companion — static helpers used by MediaActionReceiver
    // ------------------------------------------------------------------ //

    companion object {
        const val CHANNEL_NAME  = "nero_academy/media_notification"
        const val ACTION_PREFIX = "com.neroacademy.app.MEDIA_"

        @Volatile
        private var instance: MainActivity? = null

        fun onMediaAction(action: String): Boolean {
            val activity = instance ?: return false
            if (action == "open") return true

            activity.runOnUiThread {
                activity.methodChannel?.invokeMethod("mediaAction", action)
            }
            return true
        }
    }
}
