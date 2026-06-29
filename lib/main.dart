import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'utils/colors.dart';
import 'utils/tk_translations.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations (portrait only for premium feel)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppState _appState = AppState();
  bool _isLoading = true;
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appState.tickPrayerTimer();
    }
  }

  Future<void> _initializeApp() async {
    await _appState.initialize();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    if (_permissionRequested) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _permissionRequested = true;

    final granted = await NotificationService().requestPermissions();
    if (!granted && context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bildiriş rugsady'),
          content: const Text(
            'Namaz wagty habarlandyryşlary we yzygiderli wagtlar paneli işlemegi üçin '
            'bildiriş rugsadyny bermegiňizi haýyş edýäris. Sazlamalar bölüminden hem açyp bilersiňiz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bolýar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar colors to transparent for full bleed screen design
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));

    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: AppColors.darkBg,
        ),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mosque_rounded,
                  color: AppColors.emeraldGreen,
                  size: 64,
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  color: AppColors.emeraldGreen,
                ),
                SizedBox(height: 16),
                Text(
                  "Gazojak Namaz Wagty",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final isDark = _appState.isDarkMode;

        return MaterialApp(
          title: TkTranslations.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          
          // Premium Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: AppColors.emeraldGreen,
            scaffoldBackgroundColor: AppColors.darkBg,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.emeraldGreen,
              secondary: AppColors.mintGreen,
              surface: AppColors.darkCardBg,
              onPrimary: Colors.white,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.emeraldGreen;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.emeraldGreen.withOpacity(0.5);
                }
                return null;
              }),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16),
              bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14),
              bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
          
          // Premium Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: AppColors.emeraldGreen,
            scaffoldBackgroundColor: AppColors.lightBg,
            colorScheme: const ColorScheme.light(
              primary: AppColors.emeraldGreen,
              secondary: AppColors.mintGreen,
              surface: AppColors.lightCardBg,
              onPrimary: Colors.white,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.emeraldGreen;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.emeraldGreen.withOpacity(0.5);
                }
                return null;
              }),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16),
              bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14),
              bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
          
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _requestNotificationPermission(context);
              });
              return MainNavigation(appState: _appState);
            },
          ),
        );
      },
    );
  }
}
