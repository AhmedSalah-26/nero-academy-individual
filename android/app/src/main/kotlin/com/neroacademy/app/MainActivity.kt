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
import androidx.media.app.NotificationCompat.MediaStyle
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "nero_academy/media_notification"
    private val notificationChannelId = "nero_academy_media"
    private val notificationId = 1204
    private val permissionRequestCode = 2401

    private var methodChannel: MethodChannel? = null
    private var mediaSession: MediaSessionCompat? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
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

        createNotificationChannel()
        handleMediaIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleMediaIntent(intent)
    }

    override fun onDestroy() {
        hideMediaNotification()
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }

    private fun showMediaNotification(args: Map<*, *>?) {
        if (args == null) return
        if (!hasNotificationPermission()) {
            requestNotificationPermission()
            return
        }

        val title = args["title"] as? String ?: getString(R.string.app_name)
        val subtitle = args["subtitle"] as? String ?: ""
        val isPlaying = args["isPlaying"] as? Boolean ?: false
        val position = (args["position"] as? Number)?.toInt() ?: 0
        val duration = (args["duration"] as? Number)?.toInt() ?: 0

        val session = mediaSession ?: MediaSessionCompat(this, "NeroAcademyVideo").also {
            mediaSession = it
        }
        session.isActive = true
        session.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_PLAY or
                        PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_SEEK_TO
                )
                .setState(
                    if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                    else PlaybackStateCompat.STATE_PAUSED,
                    position.toLong(),
                    if (isPlaying) 1f else 0f
                )
                .build()
        )

        val playPauseIcon = if (isPlaying) {
            android.R.drawable.ic_media_pause
        } else {
            android.R.drawable.ic_media_play
        }
        val playPauseTitle = if (isPlaying) "Pause" else "Play"

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setOnlyAlertOnce(true)
            .setOngoing(isPlaying)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(activityIntent("open", 10))
            .setDeleteIntent(activityIntent("close", 14))
            .addAction(
                android.R.drawable.ic_media_rew,
                "-10",
                activityIntent("rewind10", 11)
            )
            .addAction(
                playPauseIcon,
                playPauseTitle,
                activityIntent("playPause", 12)
            )
            .addAction(
                android.R.drawable.ic_media_ff,
                "+10",
                activityIntent("forward10", 13)
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Close",
                activityIntent("close", 14)
            )
            .setStyle(
                MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setProgress(duration, position.coerceAtMost(duration), duration <= 0)
            .build()

        NotificationManagerCompat.from(this).notify(notificationId, notification)
    }

    private fun hideMediaNotification() {
        NotificationManagerCompat.from(this).cancel(notificationId)
        mediaSession?.isActive = false
    }

    private fun handleMediaIntent(intent: Intent?) {
        val action = intent?.action ?: return
        if (!action.startsWith(actionPrefix)) return

        val mediaAction = action.removePrefix(actionPrefix)
        if (mediaAction == "open") return
        methodChannel?.invokeMethod("mediaAction", mediaAction)
    }

    private fun activityIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            this.action = "$actionPrefix$action"
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            notificationChannelId,
            "Video playback",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Video playback controls"
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

    companion object {
        private const val actionPrefix = "com.neroacademy.app.MEDIA_"
    }
}
