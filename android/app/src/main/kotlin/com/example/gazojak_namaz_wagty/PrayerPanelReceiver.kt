package com.example.gazojak_namaz_wagty

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.text.Html
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Native BroadcastReceiver that fires at each prayer time transition and
 * updates the persistent panel notification (id=8888) directly, without
 * needing Dart/Flutter to be running. Also schedules the next transition.
 *
 * This is the key piece that keeps the panel correct even when the app is
 * fully in the background or killed.
 */
class PrayerPanelReceiver : BroadcastReceiver() {

    companion object {
        const val NOTIFICATION_ID = 8888
        const val CHANNEL_ID    = "persistent_prayer_times"
        const val ACTION        = "com.example.gazojak_namaz_wagty.PANEL_UPDATE"

        // Intent extras for the current transition
        const val EXTRA_TITLE        = "title"
        const val EXTRA_BODY_HTML    = "bodyHtml"
        const val EXTRA_WHEN_MS      = "whenMs"

        // Intent extras for the NEXT transition (so receiver can chain)
        const val EXTRA_NEXT_AT_MS   = "nextAtMs"
        const val EXTRA_NEXT_TITLE   = "nextTitle"
        const val EXTRA_NEXT_BODY    = "nextBodyHtml"
        const val EXTRA_NEXT_WHEN_MS = "nextWhenMs"

        // Fixed request code — only ONE alarm chain at a time
        private const val REQ_CODE = 9900

        /** Called from Flutter (via MethodChannel) to prime the first alarm. */
        fun schedule(
            context: Context,
            atMs: Long,
            title: String,
            bodyHtml: String,
            whenMs: Long,
            nextAtMs: Long,
            nextTitle: String,
            nextBodyHtml: String,
            nextWhenMs: Long,
        ) {
            val intent = buildIntent(
                context, title, bodyHtml, whenMs,
                nextAtMs, nextTitle, nextBodyHtml, nextWhenMs,
            )
            val pi = pendingIntent(context, intent)
            setAlarm(context, atMs, pi)
        }

        /** Cancel any pending alarm (called when panel is disabled). */
        fun cancel(context: Context) {
            val intent = Intent(context, PrayerPanelReceiver::class.java).apply {
                action = ACTION
            }
            val pi = PendingIntent.getBroadcast(
                context, REQ_CODE, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            ) ?: return
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi)
            pi.cancel()
        }

        // ── helpers ───────────────────────────────────────────────────────────

        private fun buildIntent(
            context: Context,
            title: String,
            bodyHtml: String,
            whenMs: Long,
            nextAtMs: Long,
            nextTitle: String,
            nextBodyHtml: String,
            nextWhenMs: Long,
        ) = Intent(context, PrayerPanelReceiver::class.java).apply {
            action = ACTION
            putExtra(EXTRA_TITLE,        title)
            putExtra(EXTRA_BODY_HTML,    bodyHtml)
            putExtra(EXTRA_WHEN_MS,      whenMs)
            putExtra(EXTRA_NEXT_AT_MS,   nextAtMs)
            putExtra(EXTRA_NEXT_TITLE,   nextTitle)
            putExtra(EXTRA_NEXT_BODY,    nextBodyHtml)
            putExtra(EXTRA_NEXT_WHEN_MS, nextWhenMs)
        }

        private fun pendingIntent(context: Context, intent: Intent) =
            PendingIntent.getBroadcast(
                context, REQ_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

        private fun setAlarm(context: Context, atMs: Long, pi: PendingIntent) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pi)
                } else {
                    am.setExact(AlarmManager.RTC_WAKEUP, atMs, pi)
                }
            } catch (e: SecurityException) {
                // Fallback: inexact alarm (may fire a few minutes late)
                am.set(AlarmManager.RTC_WAKEUP, atMs, pi)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return

        val title     = intent.getStringExtra(EXTRA_TITLE)     ?: return
        val bodyHtml  = intent.getStringExtra(EXTRA_BODY_HTML) ?: ""
        val whenMs    = intent.getLongExtra(EXTRA_WHEN_MS, 0L)

        // 1. Update the persistent panel notification
        showPanel(context, title, bodyHtml, whenMs)

        // 2. Chain: schedule the next transition if it's in the future
        val nextAtMs   = intent.getLongExtra(EXTRA_NEXT_AT_MS, 0L)
        val nextTitle  = intent.getStringExtra(EXTRA_NEXT_TITLE)
        val nextBody   = intent.getStringExtra(EXTRA_NEXT_BODY) ?: ""
        val nextWhenMs = intent.getLongExtra(EXTRA_NEXT_WHEN_MS, 0L)

        if (nextAtMs > System.currentTimeMillis() && nextTitle != null) {
            // For the chained alarm we don't have a third step here — Flutter
            // will re-prime the chain next time the app opens. This gives us
            // at least a TWO-STEP lookahead from the last Flutter session.
            val nextIntent = buildIntent(
                context, nextTitle, nextBody, nextWhenMs,
                0L, "", "", 0L,   // no third step; Flutter re-primes on resume
            )
            val pi = pendingIntent(context, nextIntent)
            setAlarm(context, nextAtMs, pi)
        }
    }

    // ── notification builder ─────────────────────────────────────────────────

    private fun showPanel(context: Context, title: String, bodyHtml: String, whenMs: Long) {
        ensureChannel(context)

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentPi = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val bigText = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Html.fromHtml(bodyHtml, Html.FROM_HTML_MODE_LEGACY)
        } else {
            @Suppress("DEPRECATION")
            Html.fromHtml(bodyHtml)
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText("")
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setOngoing(true)
            .setAutoCancel(false)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setWhen(whenMs)
            .setUsesChronometer(true)
            .setColor(Color.parseColor("#2E7D32"))
            .setContentIntent(contentPi)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, builder.build())
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted — silently ignore
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Yzygiderli wagtlar paneli",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Namaz wagtlary we galan wagty görkezýär"
            setSound(null, null)
            enableVibration(false)
        }
        context.getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
