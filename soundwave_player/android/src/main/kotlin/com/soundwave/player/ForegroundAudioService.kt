package com.soundwave.player

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ForegroundAudioService : Service() {
  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    ensureChannel()
    val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("SoundWave playback")
      .setContentText("Playing audio")
      .setSmallIcon(android.R.drawable.ic_media_play)
      .setOngoing(true)
      .build()
    startForeground(NOTIFICATION_ID, notification)
    return START_STICKY
  }

  override fun onDestroy() {
    stopForeground(STOP_FOREGROUND_REMOVE)
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun ensureChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val nm = getSystemService(NotificationManager::class.java)
      val channel = NotificationChannel(
        CHANNEL_ID,
        "SoundWave Playback",
        NotificationManager.IMPORTANCE_LOW
      )
      nm.createNotificationChannel(channel)
    }
  }

  companion object {
    private const val CHANNEL_ID = "soundwave_playback"
    private const val NOTIFICATION_ID = 1001
  }
}
