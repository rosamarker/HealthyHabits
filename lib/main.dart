import 'package:flutter/material.dart';

import 'view/home_view.dart';

void main() {
  runApp(const HealthyHabitsApp());
}

/// Application root.
class HealthyHabitsApp extends StatelessWidget {
  const HealthyHabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthy Habits',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightGreen,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
