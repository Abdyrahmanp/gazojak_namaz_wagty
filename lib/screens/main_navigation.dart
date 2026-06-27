import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
import '../services/version_service.dart';
import 'home_screen.dart';
import 'compass_screen.dart';
import 'tasbih_screen.dart';
import 'faq_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  final AppState appState;

  const MainNavigation({super.key, required this.appState});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final versionService = VersionService();
    final remoteInfo = await versionService.fetchRemoteVersion();
    if (remoteInfo == null) return;

    final isUpdateAvail = await versionService.isUpdateAvailable(remoteInfo);
    if (!isUpdateAvail) return;

    final isDismissed = await versionService.isUpdateDismissed(remoteInfo.versionCode);
    if (isDismissed) return;

    if (!mounted) return;

    final isDark = widget.appState.isDarkMode;
    final tc = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final sc = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bg = isDark ? AppColors.darkDialogBg : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: bg,
          elevation: isDark ? 24 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.emeraldGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        TkTranslations.updateTitle,
                        style: TextStyle(
                          color: tc,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${TkTranslations.currentVersionText}${VersionService.currentVersionName}\n'
                  '${TkTranslations.remoteVersionText}${remoteInfo.versionName}\n'
                  '${TkTranslations.updateDateText}${remoteInfo.releaseDate}',
                  style: TextStyle(
                    color: tc,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (remoteInfo.whatsNew.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    TkTranslations.whatsNewText,
                    style: TextStyle(
                      color: tc,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remoteInfo.whatsNew,
                      style: TextStyle(
                        color: sc,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await versionService.dismissUpdate(remoteInfo.versionCode);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        TkTranslations.updateLater,
                        style: TextStyle(color: sc, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final uri = Uri.parse(remoteInfo.apkUrl);
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } catch (_) {}
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emeraldGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        TkTranslations.updateNow,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    
    // Select background gradient depending on Dark/Light theme
    final bgGradient = isDark 
        ? AppColors.darkBackgroundGradient 
        : AppColors.lightBackgroundGradient;

    final navBarBgColor = isDark 
        ? AppColors.darkCardBg 
        : AppColors.lightCardBg;

    final navBarBorderColor = isDark 
        ? AppColors.darkCardBorder 
        : AppColors.lightCardBorder;

    final unselectedItemColor = isDark 
        ? AppColors.darkTextSecondary 
        : AppColors.lightTextSecondary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: [
            HomeScreen(appState: widget.appState),
            CompassScreen(appState: widget.appState),
            TasbihScreen(appState: widget.appState),
            FaqScreen(appState: widget.appState),
            SettingsScreen(appState: widget.appState),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarBgColor,
          border: Border(
            top: BorderSide(
              color: navBarBorderColor,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.access_time_rounded, Icons.access_time_filled, TkTranslations.navHome, unselectedItemColor),
                _buildNavItem(1, Icons.explore_outlined, Icons.explore_rounded, TkTranslations.navCompass, unselectedItemColor),
                _buildNavItem(2, Icons.radio_button_checked_outlined, Icons.radio_button_checked_rounded, TkTranslations.navTasbih, unselectedItemColor),
                _buildNavItem(3, Icons.question_answer_outlined, Icons.question_answer_rounded, TkTranslations.navFAQ, unselectedItemColor),
                _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, TkTranslations.navSettings, unselectedItemColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, Color unselectedColor) {
    final isSelected = _currentIndex == index;
    final iconColor = isSelected ? AppColors.emeraldGreen : unselectedColor;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with micro scale animation
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Text Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.1,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
