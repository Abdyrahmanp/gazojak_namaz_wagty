# Gazojak Namaz Wagty 🕌

**Version:** `1.1.0+2` · **Platform:** Android (primary) · **Language:** Dart / Flutter · **Min SDK:** Android 21 (Lollipop)

> A **fully offline** Islamic prayer-times (namaz) application built exclusively for **Gazojak, Turkmenistan** (Darganata District, Lebap Province). The entire UI, all notifications, and every piece of displayed text is in **Turkmen (tk)**. No internet connection is required for core functionality.

---

## Table of Contents

1. [Project Purpose & Scope](#1-project-purpose--scope)
2. [Technology Stack & Dependencies](#2-technology-stack--dependencies)
3. [Directory Structure](#3-directory-structure)
4. [Architecture Overview](#4-architecture-overview)
5. [Core Data Contracts](#5-core-data-contracts)
6. [State Management (`AppState`)](#6-state-management-appstate)
7. [Notification System](#7-notification-system)
8. [Screen Reference](#8-screen-reference)
9. [Key Algorithms & Constants](#9-key-algorithms--constants)
10. [Settings & Persistence (`SharedPreferences` keys)](#10-settings--persistence-sharedpreferences-keys)
11. [Android Native Layer (Kotlin)](#11-android-native-layer-kotlin)
12. [Known Patterns & Gotchas](#12-known-patterns--gotchas)
13. [Build & Run](#13-build--run)

---

## 1. Project Purpose & Scope

| Property | Value |
|---|---|
| Target city | Gazojak, Turkmenistan |
| Latitude | `41.08° N` |
| Longitude | `60.03° E` |
| Timezone | UTC +5 (no DST, never changes) |
| Qibla bearing | `228.3°` South-West |
| Prayer convention | Fajr angle `-18°`, Isha angle `-17°`, Asr shadow factor `2.0` (Hanafi) |
| Localization | 100% Turkmen — no i18n framework used; strings are in `lib/utils/tk_translations.dart` |

The app ships a **366-day pre-calculated prayer schedule** (`assets/data/gazojak_times.json`) so it works completely offline including on leap years. Sunrise time (`gun`) is the only value computed dynamically at runtime via the US Naval Observatory solar algorithm.

---

## 2. Technology Stack & Dependencies

```yaml
# pubspec.yaml — key runtime dependencies
flutter_local_notifications: ^22.0.1   # Persistent panel + prayer alerts
timezone: ^0.11.0                      # TZDateTime scheduling
shared_preferences: ^2.2.3             # All user settings persistence
flutter_compass: ^0.8.1                # Magnetometer stream for Qibla
vibration: ^3.1.3                      # Strong hardware vibration on Tasbih completion
url_launcher: ^6.3.2                   # Battery settings intents, mailto links
share_plus: ^12.0.1                    # Native share sheet for FAQ answers
flutter_markdown: ^0.7.0               # Markdown rendering in FAQ detail screen
```

> **Important — `vibration` package API:** In the resolved version `3.2.0`, vibration features return non-nullable `Future<bool>`. The `Vibration.vibrate()` single-pulse API uses `duration` and `amplitude` named parameters (NOT `amplitudes` / `intensities`).

---

## 3. Directory Structure

```
gazojak_namaz_wagty/
├── assets/
│   ├── data/
│   │   ├── gazojak_times.json     # 366-day prayer schedule (MM-dd keyed)
│   │   └── faq.json               # Offline Turkmen Islamic Q&A database
│   └── icon/
│       └── app_icon.png           # Launcher icon source (green mosque silhouette)
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml    # Permissions: SCHEDULE_EXACT_ALARM, POST_NOTIFICATIONS, VIBRATE, RECEIVE_BOOT_COMPLETED, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
│   │   ├── kotlin/.../
│   │   │   └── MainActivity.kt    # MethodChannel: 'com.example.gazojak_namaz_wagty/battery'
│   │   └── res/drawable/
│   │       └── ic_notification.png  # Monochrome status-bar icon (alpha-channel only)
└── lib/
    ├── main.dart                  # App entry point, MaterialApp + ChangeNotifierProvider<AppState>
    ├── config/                    # App-wide constants (colors, theme data)
    ├── models/
    │   ├── prayer_time.dart       # Parses gazojak_times.json; exposes getTimeByKey(key)
    │   └── faq_item.dart          # FaqItem + FaqCategory; fromJson/toJson
    ├── providers/
    │   └── app_state.dart         # Central ChangeNotifier — timer, offsets, panel state
    ├── services/
    │   ├── prayer_time_service.dart   # DB loading, sunrise calc, next-prayer logic, mekruh check
    │   ├── notification_service.dart  # Persistent panel (ID 8888) + prayer alerts (IDs 1000–1030)
    │   └── faq_service.dart           # SharedPreferences cache + remote JSON sync
    ├── screens/
    │   ├── main_navigation.dart   # PageView shell with BottomNavigationBar (5 tabs)
    │   ├── home_screen.dart       # Prayer timetable dashboard (viewport-constrained, no scroll)
    │   ├── compass_screen.dart    # Qibla compass with magnetometer + 1.5s fallback
    │   ├── tasbih_screen.dart     # Digital Dhikr counter with hardware vibration
    │   ├── faq_screen.dart        # Categorized offline Q&A with real-time Turkmen search
    │   ├── faq_detail_screen.dart # Full-screen Q&A detail + related recommendations
    │   └── settings_screen.dart   # All settings: offsets, theme, sound, battery, about, version
    ├── widgets/
    │   └── turkmen_date_picker.dart  # Custom calendar dialog with full Turkmen month/weekday names
    └── utils/
        ├── tk_translations.dart   # All Turkmen UI strings, prayer names, short labels
        ├── app_colors.dart        # Color palette for Dark (Obsidian/Emerald) + Light (Teal) themes
        └── agent_debug_log.dart   # Development-only structured debug logger (agentDebugLog())
```

---

## 4. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        main.dart                         │
│  ChangeNotifierProvider<AppState>  →  MaterialApp        │
└───────────────────────────┬─────────────────────────────┘
                            │
                     AppState (ChangeNotifier)
                     ├── PrayerTimeService        ← reads gazojak_times.json
                     ├── NotificationService      ← flutter_local_notifications
                     └── Timer (1s tick)          ← _computePrayerState()
                            │
          ┌─────────────────┼───────────────────┐
          ▼                 ▼                   ▼
    HomeScreen        CompassScreen       TasbihScreen
    FaqScreen         FaqDetailScreen     SettingsScreen
          │
    Swipe navigation via PageView (main_navigation.dart)
    with BouncingScrollPhysics — left/right swipe on any screen
```

**Data flow on startup:**
1. `AppState.initialize()` → loads JSON → first `_computePrayerState()` → sets `_isReady = true` → loads `SharedPreferences` → second compute → initializes `NotificationService` → starts 1-second `Timer`.
2. Every second, `_computePrayerState()` updates: active prayer key, next prayer key, countdown string, mekruh flag, and triggers `_updatePersistentPanel()` (which is a no-op if panel state hasn't changed via composite key check).

---

## 5. Core Data Contracts

### `assets/data/gazojak_times.json`

```json
{
  "MM-dd": {
    "bamdat": "HH:mm",
    "oyle":   "HH:mm",
    "ikindi": "HH:mm",
    "agsam":  "HH:mm",
    "yasy":   "HH:mm"
  }
}
```

- Key format: `"MM-dd"` (e.g. `"01-01"`, `"02-29"`)
- **`gun` (Sunrise) is NOT in this file** — computed dynamically in `PrayerTimeService`
- All times are local UTC+5; no timezone conversion needed

### Prayer Key → Turkmen Name mapping (in `TkTranslations`)

| Key | Full name | Short label |
|---|---|---|
| `bamdat` | Ertir | Ertir |
| `gun` | Günüň dogmagy | Gün |
| `oyle` | Öýle | Öýle |
| `ikindi` | Ikindi | Ikindi |
| `agsam` | Agşam | Agşam |
| `yasy` | Ýassy | Ýassy |

### `assets/data/faq.json`

```json
[
  {
    "category": "string",
    "icon": "mosque | water_drop | auto_stories",
    "items": [
      { "question": "string", "answer": "string (markdown supported)" }
    ]
  }
]
```

Icon identifiers map to `Icons.mosque_rounded`, `Icons.water_drop_rounded`, `Icons.auto_stories_rounded`. Unknown icons fall back to `Icons.question_answer_rounded`.

---

## 6. State Management (`AppState`)

**File:** `lib/providers/app_state.dart`

`AppState` is a single `ChangeNotifier` consumed via `Provider.of<AppState>(context)` or `context.watch<AppState>()`.

### Key state fields

| Field | Type | Description |
|---|---|---|
| `_isDarkMode` | `bool` | Dark (default: true) vs Light theme |
| `_selectedDate` | `DateTime` | Date shown in HomeScreen calendar nav |
| `_persistentNotificationEnabled` | `bool` | Controls status-bar prayer panel |
| `_notificationSoundEnabled` | `bool` | Global sound toggle (master) |
| `_prayerSoundEnabled` | `Map<String, bool>` | Per-prayer sound toggles |
| `_offsets` | `Map<String, int>` | Per-prayer minute offsets (±15 min) |
| `_activePrayerKey` | `String` | The prayer currently "active" (in progress) |
| `_nextPrayerKey` | `String` | The next upcoming prayer key |
| `_countdownStr` | `String` | `"HH:MM:SS"` formatted countdown string |
| `_isMekruh` | `bool` | True when ≤30 min remain until Agşam |
| `_mekruhMinutesLeft` | `int` | Minutes remaining until Agşam (≤30) |

### Panel dirty-check (important for AI context)

To avoid redundant notification API calls, `_updatePersistentPanel()` uses a composite cache key:
```dart
final panelState = '${whenMs}_${activeKey}_$nextKey';
// Early return if unchanged
```
When `setSelectedDate()`, `setOffset()`, `resetOffsets()`, or `refreshOnResume()` are called, all three cache fields are set to `null` to force an immediate panel redraw.

---

## 7. Notification System

**File:** `lib/services/notification_service.dart`

### Notification ID allocation

| ID | Purpose |
|---|---|
| `8888` | Active persistent panel (ongoing, non-dismissible by default) |
| `8889–8910` | Scheduled background panel-refresh transition alarms |
| `1000–1030` | Prayer alert pop-ups (auto-cancel on tap) |

### Persistent panel channels

```dart
// Channel: 'persistent_prayer_times'
// Importance: low (silent, no heads-up)
// Ongoing: true, AutoCancel: true (tapping dismisses card; refreshOnResume re-shows it)
// usesChronometer: true, chronometerCountDown: true
// Icon: '@drawable/ic_notification' (monochrome alpha PNG)
// HTML body format: <font color="#CBD5E1"> for inactive, <font color="#greenHex"><b> for active
```

### Prayer alert channel

```dart
// Channel: 'prayer_alerts'
// Importance: max, Priority: max
// audioAttributesUsage: AudioAttributesUsage.alarm  ← bypasses DND/silent mode
// AutoCancel: true
```

### Panel title logic

```dart
// For nextPrayerKey == 'gun': "Günüň dogmagyna galdy"  (NOT "wagty boldy" — that's the alert)
// For all others: "${prayerName} namazyna galdy"
```

### Key method signatures

```dart
Future<void> initialize()
Future<void> requestPermissions()
Future<void> showPersistentNotification({
  required String nextPrayerKey,
  required DateTime nextPrayerDateTime,
  required PrayerTime dailyTimes,
  required Map<String, int> offsets,
  required String activePrayerKey,
})
Future<void> schedulePrayerNotifications({
  required PrayerTimeService prayerService,
  required Map<String, int> offsets,
  required bool soundEnabled,
  required Map<String, bool> prayerSoundEnabled,
  required bool persistentPanelEnabled,
})
Future<void> rescheduleNextPanelRefresh({...})
Future<void> cancelPersistentNotification()
Future<void> _cancelScheduledPanelRefreshes()   // only 8889–8910, keeps 8888 alive
Future<void> _cancelAllPanelNotifications()     // 8888 + 8889–8910 (for settings toggle)
static void Function()? onPanelTapped;          // callback set in AppState.initialize()
```

### Exact alarm fallback (Android 13+)

On devices where `SCHEDULE_EXACT_ALARM` is denied, `schedulePrayerNotifications` falls back to `AndroidScheduleMode.inexact`. This prevents silent crashes and ensures at least approximate delivery.

---

## 8. Screen Reference

### `home_screen.dart` — Wagtlar (Prayer Times)

- **Viewport-constrained**: No vertical scroll. All content (header, Mekruh banner, Hero countdown card, 6 prayer rows) fits within screen height via dynamic `MediaQuery`-based sizing.
- **Mekruh alert banner**: Shown when `appState.isMekruh == true`. Contains an `(i)` button that opens a dialog with a deep-link to FAQ entry "Haçan namaz okamaly däl?".
- **Hero countdown card**: Displays `appState.countdownStr` and `appState.nextPrayerKey`.
- **Active prayer highlight**: The row matching `appState.activePrayerKey` gets a vibrant gradient + "Häzir" (Now) tag.
- **Date navigation**: Left/right chevrons call `appState.setSelectedDate()`. Resets to today via `appState.resetToToday()`.

### `compass_screen.dart` — Kybla (Qibla Compass)

- Streams `FlutterCompass.events` for real-time bearing.
- **Fallback**: 1.5-second timeout. If sensor unavailable, shows static instructions with exact bearing (`228.3°`).
- Alignment success: emerald glow + haptic feedback + checkmark ("Kybla tarapa öwrüldiňiz!").

### `tasbih_screen.dart` — Tesbih (Dhikr Counter)

- Multi-zikir selector (Subhanallah, Alhamdulillah, Allahu Akbar, custom).
- Target counts: 33, 66, 99 (configurable).
- On target hit: calls `_triggerTargetVibration()` → `Vibration.vibrate(duration: 400, amplitude: 255)`.
- State fully in `AppState` (`zikirCount`, `selectedZikirIndex`, `zikirTarget`).

### `settings_screen.dart` — Sazlamalar (Settings)

Key sections (all in one long `ListView`):
1. **Per-prayer offset controls** (±15 min, +/- buttons) → `appState.setOffset(key, val)`
2. **Per-prayer sound toggles** → `appState.setPrayerSoundEnabled(key, val)`
3. **Global notification sound toggle** → `appState.toggleNotificationSound(val)`
4. **Persistent panel toggle** → `appState.togglePersistentNotification(val)`
5. **Theme toggle** → `appState.toggleTheme()`
6. **Battery optimization accordion** (`ExpansionTile`) — dismissible via `SharedPreferences` key `battery_warning_dismissed`. Button routes via Kotlin `MethodChannel` (see §11).
7. **Version update checker** — queries `version.json` from companion website.
8. **Support contact form accordion** — `url_launcher` mailto.
9. **About Us dialog** — developer story, data reliability info.

### `faq_screen.dart` — Sorag-Jogap (Q&A)

- Loads instantly from `SharedPreferences` cache → falls back to `assets/data/faq.json`.
- Background sync via `FaqService.updateFaqDataFromServer()` (non-blocking).
- **Turkmen character normalizer** in search: `ä→a`, `ü→u`, `ý→y`, `ň→n`, `ö→o`, `ş→s`, `ç→c`, `ž→z` — allows users to type without special characters.
- Category chips with icon mapping.
- Tapping a question navigates to `FaqDetailScreen` (not an inline expand).

### `faq_detail_screen.dart`

- Renders `answer` as Markdown via `flutter_markdown`.
- Footer shows 3 related "Maslahat" (recommendations).
- Share button via `share_plus`.
- "Report Error" → mailto link.

---

## 9. Key Algorithms & Constants

### Astronomical Sunrise (`PrayerTimeService`)

Sunrise is computed using solar declination, mean anomaly, and local hour angle:

```dart
// Coordinates: lat=41.08, lng=60.03, utcOffset=5.0
// Algorithm: US Naval Observatory solar position formulas
// Called every time getTimesForDate() or getAdjustedDateTimes() is called
```

### Mekruh (Kerahet) Check

```dart
// Triggered in AppState._computePrayerState()
final diffToAgsam = agsamDt.difference(targetDateTime);
if (targetDateTime.isBefore(agsamDt) &&
    diffToAgsam.inMinutes <= 30 &&
    diffToAgsam.inMinutes >= 0) {
  isMekruh = true;
}
// Threshold: 30 minutes (NOT 20 — was changed and must stay at 30)
```

### Negative countdown guard

```dart
final rawDiff = nextDateTime.difference(now);
final difference = rawDiff.isNegative ? Duration.zero : rawDiff;
```

---

## 10. Settings & Persistence (`SharedPreferences` keys)

| Key | Type | Default | Description |
|---|---|---|---|
| `is_dark_mode` | bool | `true` | Theme selection |
| `persistent_notification_enabled` | bool | `true` | Status-bar prayer panel on/off |
| `notification_sound_enabled` | bool | `true` | Global prayer alert sound |
| `prayer_sound_bamdat` | bool | `true` | Per-prayer sound toggle |
| `prayer_sound_gun` | bool | `true` | Per-prayer sound toggle |
| `prayer_sound_oyle` | bool | `true` | Per-prayer sound toggle |
| `prayer_sound_ikindi` | bool | `true` | Per-prayer sound toggle |
| `prayer_sound_agsam` | bool | `true` | Per-prayer sound toggle |
| `prayer_sound_yasy` | bool | `true` | Per-prayer sound toggle |
| `offset_bamdat` | int | `0` | Minutes offset for Fajr (±15) |
| `offset_gun` | int | `0` | Minutes offset for Sunrise (±15) |
| `offset_oyle` | int | `0` | Minutes offset for Dhuhr (±15) |
| `offset_ikindi` | int | `0` | Minutes offset for Asr (±15) |
| `offset_agsam` | int | `0` | Minutes offset for Maghrib (±15) |
| `offset_yasy` | int | `0` | Minutes offset for Isha (±15) |
| `zikir_count` | int | `0` | Tasbih counter current value |
| `selected_zikir_index` | int | `0` | Selected dhikr phrase index |
| `zikir_target` | int | `33` | Tasbih target count |
| `battery_warning_dismissed` | bool | `false` | Hides battery optimization banner |
| `cached_faq_data` | String | *(asset fallback)* | Cached remote FAQ JSON |
| `faq_remote_url` | String | GitHub raw URL | Custom FAQ data source URL |
| `last_checked_version` | String | `""` | Suppresses repeated update prompts |

---

## 11. Android Native Layer (Kotlin)

**File:** `android/app/src/main/kotlin/.../MainActivity.kt`

### MethodChannel: `com.example.gazojak_namaz_wagty/battery`

Registered in `configureFlutterEngine`. Handles one method:

```kotlin
"openBatteryOptimization" → {
    val packageName = call.argument<String>("package") ?: applicationContext.packageName
    // Tries sequentially:
    // 1. Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS (direct whitelist dialog)
    // 2. Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS (general page)
    // 3. Settings.ACTION_APPLICATION_DETAILS_SETTINGS (app detail page)
    result.success(true)
}
```

Called from `settings_screen.dart`:
```dart
const channel = MethodChannel('com.example.gazojak_namaz_wagty/battery');
await channel.invokeMethod('openBatteryOptimization', {'package': 'com.example.gazojak_namaz_wagty'});
```

### Required AndroidManifest.xml permissions

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

---

## 12. Known Patterns & Gotchas

### ❗ Do NOT cancel notification ID 8888 inside `_cancelScheduledPanelRefreshes()`
`_cancelScheduledPanelRefreshes()` must only iterate over IDs `8889–8910`. Cancelling `8888` here causes the visible panel to vanish on app resume. Only `_cancelAllPanelNotifications()` should touch ID `8888`.

### ❗ Persistent panel uses `autoCancel: true` intentionally
Even though the panel is "ongoing", `autoCancel: true` is set so tapping the notification collapses the drawer cleanly. `refreshOnResume()` in `AppState` (called by the `WidgetsBindingObserver.didChangeAppLifecycleState` handler) immediately re-posts the panel when the app comes to the foreground.

### ❗ Next prayer countdown is always computed from `DateTime.now()`
`_computePrayerState()` computes the countdown from the **real system clock**, not `_selectedDate`. `_selectedDate` is only used for displaying the active prayer highlight and mekruh check relative to the viewed calendar date.

### ❗ Mekruh threshold is 30 minutes (not 20)
The threshold was explicitly changed from 20 to 30 minutes. Do not revert.

### ❗ Do NOT use `Color.withOpacity()` in new code
Use `Color.withValues(alpha: ...)` — `withOpacity()` is deprecated in Flutter 3.22+.

### ❗ `vibration` package v3.2.0 API
Use `Vibration.vibrate(duration: 400, amplitude: 255)` for a single pulse — not `amplitudes` or `intensities` (those are for pattern arrays).

### ❗ `gun` is not a namaz (prayer)
`gun` = Sunrise. It is a temporal marker, not a prayer time. Notification titles and panel text must reflect this distinction:
- Panel countdown title: `"Günüň dogmagyna galdy"` ✅
- Alert at sunrise: `"Günüň dogmagy wagty boldy"` ✅
- ~~`"Günüň dogmagy namazy"`~~ ❌

### ❗ FAQ data source default URL
`FaqService.defaultRemoteUrl` points to a raw GitHub URL. If the repo is renamed or the branch changes, update this constant in `lib/services/faq_service.dart`.

### ❗ Battery settings intent on Android 11+ (API 30+)
Do NOT use `canLaunchUrl()` with `android.settings.*` URIs — it returns `false` due to package visibility rules. Use direct `launchUrl()` wrapped in `try-catch`, or use the Kotlin `MethodChannel` (preferred).

### ❗ `agentDebugLog()` calls in production code
`lib/utils/agent_debug_log.dart` contains a debug logger used during development. These calls are harmless in release builds but should be removed or gated behind `kDebugMode` if APK size is a concern.

---

## 13. Build & Run

```bash
# Get dependencies
flutter pub get

# Run in debug mode (requires connected Android device or emulator)
flutter run

# Generate launcher icons (after changing pubspec.yaml icon config)
dart run flutter_launcher_icons

# Build release APK
flutter build apk --release

# Build release APK (split per ABI for smaller download size)
flutter build apk --split-per-abi --release
```

### Launcher icon configuration (`pubspec.yaml`)

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#1B5E20"   # Deep green background
  adaptive_icon_foreground: "assets/icon/app_icon.png"
  remove_alpha_ios: true
```

---

## Companion Website

The app has a companion download/landing page hosted externally. It serves:
- APK download: `gnw.alwaysdata.net/gazojak-namaz-wagty.apk`
- `version.json` — queried by the in-app version checker in `SettingsScreen`

---

*Developed by **Abdyrahman Döwletgulyýew** for the Gazojak community.*
