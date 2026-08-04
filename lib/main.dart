import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/welcome_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clone GPT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Defaulting to sleek ChatGPT dark mode
      home: const WelcomeScreen(),
    );
  }
}
