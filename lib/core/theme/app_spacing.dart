import 'package:flutter/material.dart';

/// Defines our rigid 8-Point Grid Spacing System and standard border radiuses.
/// 
/// In Flutter UI layouts, instead of wrapping every child in a Padding widget,
/// putting simple `SizedBox` spacers between elements inside a Row or Column
/// makes your layout much cleaner and easier to read!
class AppSpacing {
  AppSpacing._();

  // --- Spacing Constants (8-point grid) ---
  static const double xxs = 4.0;
  static const double xs  = 8.0;
  static const double sm  = 16.0;
  static const double md  = 24.0;
  static const double lg  = 32.0;
  static const double xl  = 48.0;

  // --- Border Radius Constants ---
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;

  // --- Reusable Horizontal Spacers (For Rows) ---
  static const SizedBox gapW4  = SizedBox(width: xxs);
  static const SizedBox gapW8  = SizedBox(width: xs);
  static const SizedBox gapW16 = SizedBox(width: sm);
  static const SizedBox gapW24 = SizedBox(width: md);
  static const SizedBox gapW32 = SizedBox(width: lg);
  static const SizedBox gapW48 = SizedBox(width: xl);

  // --- Reusable Vertical Spacers (For Columns) ---
  static const SizedBox gapH4  = SizedBox(height: xxs);
  static const SizedBox gapH8  = SizedBox(height: xs);
  static const SizedBox gapH16 = SizedBox(height: sm);
  static const SizedBox gapH24 = SizedBox(height: md);
  static const SizedBox gapH32 = SizedBox(height: lg);
  static const SizedBox gapH48 = SizedBox(height: xl);
}
