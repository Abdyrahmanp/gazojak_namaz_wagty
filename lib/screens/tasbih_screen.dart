import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';

class TasbihScreen extends StatefulWidget {
  final AppState appState;

  const TasbihScreen({super.key, required this.appState});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapCircle() {
    // Animate scale down and up
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Check if target is met before incrementing
    final countBefore = widget.appState.zikirCount;
    final target = widget.appState.zikirTarget;
    
    widget.appState.incrementZikir();
    
    final countAfter = countBefore + 1;

    // Haptic feedback
    if (target > 0 && countAfter % target == 0) {
      // High vibration when target reached
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.heavyImpact();
      });
      _showTargetReachedDialog();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showTargetReachedDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${TkTranslations.shortDhikrs[widget.appState.selectedZikirIndex]} zikri ${widget.appState.zikirTarget} gezek gaýtalandy!",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.emeraldGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showZikirSelector() {
    final isDark = widget.appState.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  TkTranslations.selectZikir,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: TkTranslations.defaultDhikrs.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == widget.appState.selectedZikirIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.emeraldGreen.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () {
                          widget.appState.setSelectedZikirIndex(index);
                          Navigator.pop(context);
                        },
                        title: Text(
                          TkTranslations.defaultDhikrs[index],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.emeraldGreen
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkCardBg : AppColors.lightCardBg;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final zikirCount = widget.appState.zikirCount;
    final target = widget.appState.zikirTarget;
    final zikirName = TkTranslations.defaultDhikrs[widget.appState.selectedZikirIndex];

    // Calculate progress fraction
    double progress = 0.0;
    if (target > 0) {
      progress = (zikirCount % target) / target;
      if (progress == 0 && zikirCount > 0) progress = 1.0;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TkTranslations.tasbihTitle,
                    style: textTheme.headlineMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // Reset Button
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.appState.resetZikir();
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
                    label: const Text(
                      TkTranslations.resetLabel,
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active Zikir Card Selector
              GestureDetector(
                onTap: _showZikirSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreen.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.emeraldGreen),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Okalýan Zikir",
                              style: textTheme.bodySmall?.copyWith(color: subColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              zikirName,
                              style: textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: subColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 35),

              // Giant Circular Counter Button
              Expanded(
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GestureDetector(
                      onTap: _onTapCircle,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardBg,
                          border: Border.all(color: borderColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular Progress Indicator
                            if (target > 0)
                              SizedBox(
                                width: 232,
                                height: 232,
                                child: CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 8,
                                  color: AppColors.emeraldGreen,
                                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                            
                            // Inside Texts
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$zikirCount",
                                  style: textTheme.displayLarge?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (target > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "${TkTranslations.targetCount}: $target",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: subColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Çäksiz",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: subColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Target Selector Row & Total statistics
              Column(
                children: [
                  // Target Select Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [33, 99, 0].map((t) {
                      final isSelected = widget.appState.zikirTarget == t;
                      final label = t == 0 ? "Çäksiz" : "$t";
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: ChoiceChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.emeraldGreen,
                          backgroundColor: cardBg,
                          side: BorderSide(color: isSelected ? AppColors.emeraldGreen : borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            widget.appState.setZikirTarget(t);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Instruction Tip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.03) : AppColors.emeraldGreen.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Sanalgyjy artdyrmak üçin tegelege basyň.",
                        style: textTheme.bodySmall?.copyWith(color: subColor),
                      ),
                    ),
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
