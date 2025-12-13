import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/progress_screen.dart';
import 'screens/daily_tasks_screen.dart';
import 'screens/gym_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const GoalifyApp());
}

class GoalifyApp extends StatelessWidget {
  const GoalifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  // 0:Groups, 1:Daily, 2:Progress, 3:Gym, 4:Profile
  int currentIndex = 1;

  final _screens = const [
    //GroupListScreen(),
    DailyTasksScreen(),
    ProgressScreen(),
    GymScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.pink,
        items: const [
         //BottomNavigationBarItem(icon: Icon(Icons.group),          label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle),   label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart),     label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Gym'),
          BottomNavigationBarItem(icon: Icon(Icons.person),         label: 'Profile'),
        ],
      ),
    );
  }
}
