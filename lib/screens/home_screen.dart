import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
import '../widgets/turkmen_date_picker.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showTurkmenDatePicker(
      context: context,
      initialDate: widget.appState.selectedDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 10, 12, 31),
      isDark: widget.appState.isDarkMode,
    );
    if (picked != null) {
      widget.appState.setSelectedDate(picked);
    }
  }

  void _changeDay(int delta) {
    HapticFeedback.lightImpact();
    widget.appState.setSelectedDate(
      widget.appState.selectedDate.add(Duration(days: delta)),
    );
  }

  void _showMekruhExplanation(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: bg,
        elevation: isDark ? 24 : 8,
        shadowColor: isDark ? Colors.black54 : Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Mekruh Wagty barada',
                style: TextStyle(color: tc, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Gün ýaşmazdan (Agşam namazyndan) öňki 20 minutlyk wagt Kerahet (Mekruh) wagty diýlip hasaplanylýar.\n\n'
                'Fikh ylmyna görä, bu wagt aralygynda hiç hili nafile (meýletin) ýa-da sünnet namazlaryny okamak bolmaz. Diňe şol günüň ikindi namazynyň parzyny okamaga gäç galan bolsaňyz okap bilersiňiz.\n\n'
                'Bu wagt aralygynda namaz okamaklygyň gadagan edilmegi Pygamberimiziň (s.a.w.) hadyslaryna esaslanýar.',
                style: TextStyle(color: tc, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ýap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final appState = widget.appState;
    final isDark = appState.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final selectedDate = appState.selectedDate;
    final today = DateTime.now();
    final isShowingToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final dailyTimes = appState.prayerService.getTimesForDate(selectedDate);
    final offsets = appState.offsets;
    final countdownStr = appState.countdownStr;
    final nextPrayerKey = appState.nextPrayerKey;
    final activePrayerKey = appState.activePrayerKey;
    final isMekruh = appState.isMekruh;
    final mekruhMinutesLeft = appState.mekruhMinutesLeft;

    String getDisplayTime(String key, String baseTimeStr) {
      final offset = offsets[key] ?? 0;
      if (offset == 0) return baseTimeStr;

      final parts = baseTimeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final baseDate = DateTime(2026, 1, 1, hour, minute);
      final adjusted = baseDate.add(Duration(minutes: offset));
      return '${adjusted.hour.toString().padLeft(2, '0')}:${adjusted.minute.toString().padLeft(2, '0')}';
    }

    const sortedKeys = ['bamdat', 'gun', 'oyle', 'ikindi', 'agsam', 'yasy'];

    final countdownBorderColor = isMekruh
        ? Colors.redAccent.withValues(alpha: 0.6)
        : borderColor;
    final countdownBgColor = isMekruh
        ? Colors.redAccent.withValues(alpha: 0.04)
        : cardBg;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TkTranslations.cityHeader,
                      style: textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isShowingToday)
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          appState.resetToToday();
                        },
                        icon: const Icon(Icons.today_rounded, color: AppColors.emeraldGreen, size: 18),
                        label: const Text(
                          'Bugün',
                          style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.emeraldGreen, size: 28),
                      onPressed: () => _changeDay(-1),
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.emeraldGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              TkTranslations.formatFullDate(selectedDate),
                              style: textTheme.titleMedium?.copyWith(
                                color: AppColors.emeraldGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.emeraldGreen, size: 28),
                      onPressed: () => _changeDay(1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: countdownBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: countdownBorderColor,
                      width: isMekruh ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMekruh) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Mekruh wagty (Agşama $mekruhMinutesLeft min)',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => _showMekruhExplanation(context),
                                child: const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        '${TkTranslations.prayerNamesShort[nextPrayerKey]} namazyna',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        countdownStr,
                        style: textTheme.displayMedium?.copyWith(
                          color: isMekruh ? Colors.redAccent : textColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 42,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        TkTranslations.remainingTimeLabel,
                        style: textTheme.bodySmall?.copyWith(color: subColor, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      final rawTime = dailyTimes.getTimeByKey(key);
                      final displayTime = getDisplayTime(key, rawTime);
                      final displayName = TkTranslations.prayerNames[key] ?? key;
                      final isCurrent = key == activePrayerKey;

                      IconData iconData;
                      switch (key) {
                        case 'bamdat':
                          iconData = Icons.nights_stay_outlined;
                          break;
                        case 'gun':
                          iconData = Icons.wb_sunny_outlined;
                          break;
                        case 'oyle':
                          iconData = Icons.wb_sunny;
                          break;
                        case 'ikindi':
                          iconData = Icons.filter_drama_outlined;
                          break;
                        case 'agsam':
                          iconData = Icons.wb_twilight;
                          break;
                        case 'yasy':
                          iconData = Icons.brightness_3;
                          break;
                        default:
                          iconData = Icons.access_time;
                      }

                      if (isCurrent) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.activePrayerGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(iconData, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              displayName,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white30,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Häzir',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  displayTime,
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.emeraldGreen.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.emeraldGreen,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            displayName,
                            style: textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Text(
                            displayTime,
                            style: textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
