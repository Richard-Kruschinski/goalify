import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/progress/presentation/pages/progress_screen.dart';
import 'features/tasks/presentation/pages/daily_tasks_screen.dart';
import 'features/gym/presentation/pages/gym_screen.dart';
import 'features/functions/presentation/pages/functions_screen.dart';
import 'features/functions/pomodoro/presentation/controllers/pomodoro_controller.dart';
import 'features/functions/distraction_blocker/presentation/controllers/distraction_blocker_controller.dart';
import 'features/functions/music_timer/presentation/controllers/music_timer_controller.dart';
import 'features/functions/interval_timer/presentation/controllers/interval_timer_controller.dart';
import 'core/services/timer_live_presentation_service.dart';
import 'core/settings/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialise the MethodChannel handler for native → Flutter timer actions
  // and notification-tap navigation.
  TimerLivePresentationService.instance.init();
  final settings = SettingsController();
  await settings.load();
  runApp(GoalifyApp(settings: settings));
}

class GoalifyApp extends StatelessWidget {
  const GoalifyApp({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global app settings (theme mode, language)
        ChangeNotifierProvider.value(value: settings),
        // Global PomodoroController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => PomodoroController(),
        ),
        // Global DistractionBlockerController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => DistractionBlockerController(),
        ),
        // Global MusicTimerController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => MusicTimerController(),
        ),
        // Global IntervalTimerController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => IntervalTimerController(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.pink,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF141619),
          ),
          themeMode: settings.themeMode,
          // Country codes are chosen so weeks start on Monday (de_DE, en_GB)
          locale: settings.locale,
          supportedLocales: SettingsController.supportedLanguages
              .map((l) => l.materialLocale)
              .toList(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainNav(), //LoginScreen() Wenn login screen
        ),
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  // 0:Progress, 1:Daily, 2:Gym, 3:Functions
  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    // Listen for notification-tap navigation requests from native side
    TimerLivePresentationService.navigateToTabNotifier
        .addListener(_onTimerNavigation);
  }

  @override
  void dispose() {
    TimerLivePresentationService.navigateToTabNotifier
        .removeListener(_onTimerNavigation);
    super.dispose();
  }

  void _onTimerNavigation() {
    final tab = TimerLivePresentationService.navigateToTabNotifier.value;
    if (tab != null && mounted) {
      setState(() => currentIndex = tab);
      TimerLivePresentationService.navigateToTabNotifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ProgressScreen(),
      DailyTasksScreen(
        onNavigateToTab: (index) {
          setState(() => currentIndex = index);
        },
      ),
      const GymScreen(),
      const FunctionsScreen(),
    ];

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.pink,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.show_chart),     label: l10n.progressTitle),
          BottomNavigationBarItem(icon: const Icon(Icons.check_circle),   label: l10n.navDaily),
          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center), label: l10n.gymTitle),
          BottomNavigationBarItem(icon: const Icon(Icons.settings),       label: l10n.functionsTitle),
        ],
      ),
    );
  }
}
