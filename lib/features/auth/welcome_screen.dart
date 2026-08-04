import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The Welcome Screen is the first screen a user sees when opening Clone GPT.
/// 
/// Core Flutter Concepts Used Here:
/// 1. `Scaffold`: The canvas of any mobile screen. It automatically applies our theme's
///    background color (#202123 in dark mode!) and handles safe area boundaries.
/// 2. `Column`: Stacks widgets vertically (like Flexbox flex-direction: column in web).
/// 3. `SafeArea`: Keeps our UI away from mobile device notches and camera punch-outs.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We get text styling dynamically from our AppTheme via Theme.of(context)
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // --- App Icon / Logo Placeholder ---
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome, 
                  color: Colors.white, 
                  size: 40,
                ),
              ),
              
              AppSpacing.gapH24,

              // --- Welcome Title ---
              Text(
                'Welcome to Clone GPT',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              AppSpacing.gapH16,

              // --- Subtitle Description ---
              Text(
                'An advanced mobile AI assistant built with Flutter & Dart. '
                'Experience smart streaming conversations, rich markdown, and instant answers.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // --- Get Started Action Button ---
              SizedBox(
                width: double.infinity, // Forces button to stretch full width of container
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // TODO: Next phase - Navigate to Home / Chat Screen!
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Next step: Navigation & Auth Screen!'),
                        backgroundColor: AppColors.accent,
                      ),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              AppSpacing.gapH32,
            ],
          ),
        ),
      ),
    );
  }
}
