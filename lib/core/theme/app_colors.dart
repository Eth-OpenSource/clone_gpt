import 'package:flutter/material.dart';

/// AppColors holds all the cohesive Hex Color tokens for our application.
/// Since you know Dart: notice we use `static const` so that these Color
/// objects are evaluated at compile-time and incur zero runtime allocation cost!
class AppColors {
  AppColors._(); // Private constructor prevents instantiation of this utility class.

  // --- Core & Accent Colors ---
  // In Flutter, Hex colors are written as 0xAARRGGBB, where AA is Alpha (FF = 100% opacity)
  static const Color accent = Color(0xFF10A37F);       // #10A37F - ChatGPT signature green
  static const Color accentHover = Color(0xFF0E8A6B);  // Slightly darker green for interactive states
  static const Color purpleAccent = Color(0xFFAB68FF); // Accent color from spec
  static const Color blueAccent = Color(0xFF3B82F6);   // Accent color from spec

  // --- Background Colors ---
  static const Color lightBackground = Color(0xFFFFFFFF); // #FFFFFF
  static const Color lightSurface = Color(0xFFF7F7F8);    // Subtle gray for light mode message bubbles / sidebar
  
  static const Color darkBackground = Color(0xFF202123);  // #202123 - Deep ChatGPT dark background
  static const Color darkSurface = Color(0xFF343541);     // Dark gray for AI message bubbles / drawer
  static const Color darkInputSurface = Color(0xFF40414F); // Input bar surface color in dark mode

  // --- Text Colors ---
  static const Color textPrimaryLight = Color(0xFF202123);
  static const Color textSecondaryLight = Color(0xFF6E6E80);
  
  static const Color textPrimaryDark = Color(0xFFECECF1);
  static const Color textSecondaryDark = Color(0xFF8E8EA0);
  static const Color textDisabled = Color(0xFF6B7280);

  // --- Status Colors ---
  static const Color error = Color(0xFFEF4444);   // #EF4444
  static const Color success = Color(0xFF22C55E); // #22C55E
  
  // --- Borders & Dividers ---
  static const Color dividerLight = Color(0xFFE5E5E5);
  static const Color dividerDark = Color(0xFF4E4F60);
}
