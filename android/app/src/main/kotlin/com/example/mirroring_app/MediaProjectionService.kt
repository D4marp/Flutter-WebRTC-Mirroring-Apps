package com.example.mirroring_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class MediaProjectionService : Service() {
    
    companion object {
        private const val TAG = "MediaProjectionService"
        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "media_projection_channel"
        private const val CHANNEL_NAME = "Screen Mirroring Service"
        private const val CHANNEL_DESCRIPTION = "Service for screen mirroring"
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "MediaProjectionService created")
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "MediaProjectionService onStartCommand: ${intent?.action}")
        
        when (intent?.action) {
            "START_MEDIA_PROJECTION" -> {
                Log.d(TAG, "Starting MediaProjection service...")
                startForegroundService()
                Log.d(TAG, "MediaProjection service started successfully")
            }
            "STOP_MEDIA_PROJECTION" -> {
                Log.d(TAG, "Stopping MediaProjection service...")
                stopSelf()
            }
            else -> {
                Log.d(TAG, "Starting default MediaProjection service...")
                startForegroundService()
            }
        }
        
        return START_NOT_STICKY
    }
    
    private fun startForegroundService() {
        try {
            Log.d(TAG, "Creating notification for foreground service...")
            val notification = createNotification()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // Android 14+ (API 34)
                Log.d(TAG, "Starting foreground service with MEDIA_PROJECTION type for Android 14+")
                startForeground(
                    NOTIFICATION_ID, 
                    notification, 
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                )
                Log.d(TAG, "✓ Foreground service started successfully (Android 14+)")
                
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { // Android 10+ (API 29)
                Log.d(TAG, "Starting foreground service with MEDIA_PROJECTION type for Android 10+")
                startForeground(
                    NOTIFICATION_ID, 
                    notification, 
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                )
                Log.d(TAG, "✓ Foreground service started successfully (Android 10+)")
                
            } else {
                Log.d(TAG, "Starting foreground service for legacy Android")
                startForeground(NOTIFICATION_ID, notification)
                Log.d(TAG, "✓ Foreground service started successfully (legacy)")
            }
            
            // Send confirmation back to main activity
            val intent = Intent("MediaProjectionServiceReady")
            sendBroadcast(intent)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ CRITICAL ERROR starting foreground service", e)
            // Send error broadcast
            val intent = Intent("MediaProjectionServiceError")
            intent.putExtra("error", e.message)
            sendBroadcast(intent)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = CHANNEL_DESCRIPTION
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created for MediaProjectionService")
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Screen Mirroring Active")
            .setContentText("Your screen is being mirrored")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "MediaProjectionService destroyed")
    }
}
