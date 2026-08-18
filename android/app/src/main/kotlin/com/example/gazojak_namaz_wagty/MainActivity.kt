package com.example.gazojak_namaz_wagty

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val BATTERY_CHANNEL    = "com.example.gazojak_namaz_wagty/battery"
    private val PANEL_CHANNEL      = "com.example.gazojak_namaz_wagty/panel"
    private val AUTOSTART_CHANNEL  = "com.example.gazojak_namaz_wagty/autostart"

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

        // ── Autostart channel ─────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOSTART_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAutoStartSettings" -> {
                        val opened = openAutoStartSettings()
                        result.success(opened)
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

    /**
     * Attempts to open OEM-specific autostart / background-launch settings.
     * Returns true if any intent was successfully launched.
     */
    private fun openAutoStartSettings(): Boolean {
        val autostartIntents = listOf(
            // Xiaomi (MIUI)
            Intent().setComponent(ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity"
            )),
            // Huawei (EMUI)
            Intent().setComponent(ComponentName(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
            )),
            // Oppo (ColorOS)
            Intent().setComponent(ComponentName(
                "com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity"
            )),
            // Vivo (Funtouch OS)
            Intent().setComponent(ComponentName(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"
            )),
            // Samsung
            Intent().setComponent(ComponentName(
                "com.samsung.android.lool",
                "com.samsung.android.sm.battery.ui.BatteryActivity"
            )),
            // Letv
            Intent().setComponent(ComponentName(
                "com.letv.android.letvsafe",
                "com.letv.android.letvsafe.AutobootManageActivity"
            )),
            // OnePlus (OxygenOS)
            Intent().setComponent(ComponentName(
                "com.oneplus.security",
                "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"
            )),
            // Asus ZenUI
            Intent().setComponent(ComponentName(
                "com.asus.mobilemanager",
                "com.asus.mobilemanager.autostart.AutoStartActivity"
            )),
        )

        for (intent in autostartIntents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // This OEM intent not available, try next
            }
        }

        // Fallback: open app details settings
        try {
            startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${applicationContext.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            })
            return true
        } catch (_: Exception) {}

        return false
    }
}
