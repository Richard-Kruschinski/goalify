import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'features/progress/presentation/screens/progress_screen.dart';
import 'features/tasks/presentation/screens/daily_tasks_screen.dart';
import 'features/gym/presentation/screens/gym_screen.dart';
import 'features/functions/presentation/screens/functions_screen.dart';
import 'features/functions/pomodoro/controllers/pomodoro_controller.dart';
import 'features/functions/distraction_blocker/controllers/distraction_blocker_controller.dart';

void main() {
  runApp(const GoalifyApp());
}

class GoalifyApp extends StatelessWidget {
  const GoalifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Global PomodoroController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => PomodoroController(),
        ),
        // Global DistractionBlockerController - persists across navigation
        ChangeNotifierProvider(
          create: (_) => DistractionBlockerController(),
        ),
      ],
      child: MaterialApp(
        title: 'Goalify',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        ),
        // German localization to start weeks on Monday and format dates accordingly
        locale: const Locale('de', 'DE'),
        supportedLocales: const [Locale('de', 'DE')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainNav(), //LoginScreen() Wenn login screen
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
  int currentIndex = 2;

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

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.pink,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.show_chart),     label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle),   label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Gym'),
          BottomNavigationBarItem(icon: Icon(Icons.settings),       label: 'Funktionen'),
        ],
      ),
    );
  }
}
