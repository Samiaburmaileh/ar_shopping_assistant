import 'package:flutter/material.dart';

// App colors
class AppColors {
  static const Color primary = Color(0xFF4A6FFF);
  static const Color secondary = Color(0xFF00C2FF);
  static const Color tertiary = Color(0xFFFF4D6A);
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
}

// App dimensions
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double buttonHeight = 52.0;
}

// App assets
class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String userPlaceholder = 'assets/images/user_placeholder.png';
}

// App strings
class AppStrings {
  static const String appName = 'AR Shopping Assistant';
  static const String welcomeMessage = 'Welcome to AR Shopping Assistant';
  static const String loginPrompt = 'Sign in to continue';
  static const String emailHint = 'Email';
  static const String passwordHint = 'Password';
  static const String loginButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String orContinueWith = 'Or continue with';
  static const String searchHint = 'Search for products...';
}

// Shared preferences keys
class PrefsKeys {
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String onboardingComplete = 'onboarding_complete';
  static const String darkModeEnabled = 'dark_mode_enabled';
}