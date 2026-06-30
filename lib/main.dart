import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation.dart';
import 'services/notification_service.dart';
import 'utils/colors.dart';
import 'utils/tk_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appState = AppState();
  await appState.initialize();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatefulWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.appState.tickPrayerTimer();
    }
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
            'bildiriş rugsadyny bermegiňizi haýyş edýäris.',
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final isDark = widget.appState.isDarkMode;

        return MaterialApp(
          title: TkTranslations.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
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
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontSize: 16),
              bodyMedium: TextStyle(fontSize: 14),
              bodySmall: TextStyle(fontSize: 12),
            ),
          ),
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
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(fontSize: 16),
              bodyMedium: TextStyle(fontSize: 14),
              bodySmall: TextStyle(fontSize: 12),
            ),
          ),
          home: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _requestNotificationPermission(context);
              });
              return MainNavigation(appState: widget.appState);
            },
          ),
        );
      },
    );
  }
}
