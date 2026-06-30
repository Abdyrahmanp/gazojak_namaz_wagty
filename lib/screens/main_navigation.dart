import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/app_state.dart';
import '../utils/colors.dart';
import '../utils/tk_translations.dart';
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
    // Wersiýa barlagy diňe ulanyjy islese — açylyşda internet soramaýar
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
          physics: const ClampingScrollPhysics(),
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
