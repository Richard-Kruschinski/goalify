import 'package:flutter/material.dart';

import 'screens/group_list_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/daily_tasks_screen.dart';
import 'screens/gym_screen.dart';
import 'screens/login_screen.dart'; // falls du Login vorschaltest

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
      // Wenn du den Login zuerst willst:
      // home: const LoginScreen(),
      home: const MainNav(), // sonst direkt Tabs
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});
  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  // 0:Groups, 1:Daily, 2:Progress, 3:Gym, 4:Leaderboard
  int currentIndex = 2; // <- Progress als Starttab; ändere auf 0 falls Groups zuerst

  final _screens = const [
    GroupListScreen(),
    DailyTasksScreen(),
    ProgressScreen(),
    GymScreen(),
    LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 5 Items
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: Colors.pink,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group),            label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle),     label: 'Daily'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart),       label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center),   label: 'Gym'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard),      label: 'Leaderboard'),
        ],
      ),
    );
  }
}
