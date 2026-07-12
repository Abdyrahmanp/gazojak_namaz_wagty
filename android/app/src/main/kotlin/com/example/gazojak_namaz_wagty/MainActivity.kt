package com.example.gazojak_namaz_wagty

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val BATTERY_CHANNEL = "com.example.gazojak_namaz_wagty/battery"
    private val PANEL_CHANNEL   = "com.example.gazojak_namaz_wagty/panel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Battery optimization channel ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBatteryOptimization" -> {
                        val pkg = call.argument<String>("package") ?: applicationContext.packageName
                        openBatteryOptimization(pkg)
                        result.success(true)
                    }
                    "isBatteryOptimizationIgnored" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(applicationContext.packageName))
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Native panel update channel ───────────────────────────────────────
        // Flutter passes the NEXT TWO prayer transitions so the native receiver
        // can keep the panel correct for at least two steps without Dart running.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PANEL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    /**
                     * schedulePanelChain — schedules a two-step alarm chain.
                     *
                     * Args (all required):
                     *   atMs          Long   — epoch ms when first transition fires
                     *   title         String — notification title for first step
                     *   bodyHtml      String — HTML body for first step
                     *   whenMs        Long   — chronometer target for first step (next prayer)
                     *   nextAtMs      Long   — epoch ms when second transition fires
                     *   nextTitle     String — title for second step
                     *   nextBodyHtml  String — HTML body for second step
                     *   nextWhenMs    Long   — chronometer target for second step
                     */
                    "schedulePanelChain" -> {
                        try {
                            PrayerPanelReceiver.schedule(
                                context          = applicationContext,
                                atMs             = (call.argument<Number>("atMs")!!).toLong(),
                                title            = call.argument<String>("title")!!,
                                bodyHtml         = call.argument<String>("bodyHtml")!!,
                                whenMs           = (call.argument<Number>("whenMs")!!).toLong(),
                                nextAtMs         = (call.argument<Number>("nextAtMs")!!).toLong(),
                                nextTitle        = call.argument<String>("nextTitle")!!,
                                nextBodyHtml     = call.argument<String>("nextBodyHtml")!!,
                                nextWhenMs       = (call.argument<Number>("nextWhenMs")!!).toLong(),
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SCHEDULE_ERROR", e.message, null)
                        }
                    }

                    "cancelPanelChain" -> {
                        PrayerPanelReceiver.cancel(applicationContext)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun openBatteryOptimization(packageName: String) {
        try {
            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
            return
        } catch (_: Exception) {}

        try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
            return
        } catch (_: Exception) {}

        try {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
        } catch (_: Exception) {}
    }
}
