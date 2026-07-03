import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';

/// A fully-Turkmen date-picker dialog replacing the system showDatePicker.
/// Shows month name and weekday headers in Turkmen, and respects firstDate/lastDate.
class TurkmenDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool isDark;

  const TurkmenDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.isDark,
  });

  @override
  State<TurkmenDatePickerDialog> createState() =>
      _TurkmenDatePickerDialogState();
}

class _TurkmenDatePickerDialogState
    extends State<TurkmenDatePickerDialog> {
  late DateTime _displayed; // first day of the displayed month
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _displayed = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  bool get _canGoPrev {
    final prev = DateTime(_displayed.year, _displayed.month - 1, 1);
    return !prev.isBefore(
        DateTime(widget.firstDate.year, widget.firstDate.month, 1));
  }

  bool get _canGoNext {
    final next = DateTime(_displayed.year, _displayed.month + 1, 1);
    return !next.isAfter(
        DateTime(widget.lastDate.year, widget.lastDate.month, 1));
  }

  void _prevMonth() {
    if (!_canGoPrev) return;
    HapticFeedback.selectionClick();
    setState(() {
      _displayed =
          DateTime(_displayed.year, _displayed.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    HapticFeedback.selectionClick();
    setState(() {
      _displayed =
          DateTime(_displayed.year, _displayed.month + 1, 1);
    });
  }

  bool _isSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final first = DateTime(
        widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(
        widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return !d.isBefore(first) && !d.isAfter(last);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // How many days in the displayed month
    final daysInMonth =
        DateUtils.getDaysInMonth(_displayed.year, _displayed.month);
    // Weekday of first day (1=Mon … 7=Sun); offset for Monday-first grid
    final firstWeekday = _displayed.weekday; // 1=Mon
    final leadingBlanks = firstWeekday - 1;

    final totalCells = leadingBlanks + daysInMonth;
    const rows = 6;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200 && _canGoPrev) {
          _prevMonth();
        } else if (velocity < -200 && _canGoNext) {
          _nextMonth();
        }
      },
      child: Dialog(
      backgroundColor: bg,
      elevation: isDark ? 24 : 8,
      shadowColor: isDark ? Colors.black54 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _canGoPrev ? _prevMonth : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _canGoPrev ? AppColors.emeraldGreen : subColor,
                ),
                Column(
                  children: [
                    Text(
                      TkTranslations.months[_displayed.month],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      _displayed.year.toString(),
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _canGoNext ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: _canGoNext ? AppColors.emeraldGreen : subColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Weekday headers ───────────────────────────────────────────────
            Row(
              children: TkTranslations.weekdayHeaders
                  .map(
                    (h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: TextStyle(
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),

            // ── Day grid ──────────────────────────────────────────────────────
            for (int row = 0; row < rows; row++) ...[
              Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - leadingBlanks + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final day = DateTime(
                      _displayed.year, _displayed.month, dayNum);
                  final isSelected = day.year == _selected.year &&
                      day.month == _selected.month &&
                      day.day == _selected.day;
                  final isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;
                  final selectable = _isSelectable(day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: selectable
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(() => _selected = day);
                            }
                          : null,
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.emeraldGreen
                              : isToday
                                  ? AppColors.emeraldGreen.withValues(alpha: 0.12)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : selectable
                                      ? textColor
                                      : subColor.withValues(alpha: 0.4),
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 16),

            // ── Action buttons ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('Ýatyr',
                      style: TextStyle(color: subColor)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Saýla'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Helper function – mirrors showDatePicker API but shows Turkmen UI.
Future<DateTime?> showTurkmenDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required bool isDark,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => TurkmenDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      isDark: isDark,
    ),
  );
}
