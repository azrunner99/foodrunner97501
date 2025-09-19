/// Enhanced Theme System for Food Runs Counter
/// Provides consistent, optimized, and beautiful theming across the entire app
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Primary color palette
  static const Color primaryColor = Color(0xFF00B4D8);
  static const Color primaryLight = Color(0xFF33C2E0);
  static const Color primaryDark = Color(0xFF0090A8);

  // Secondary colors
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8760);
  static const Color accentDark = Color(0xFFE55A2B);

  // Team colors (optimized for accessibility)
  static const Color teamBlue = Color(0xFF2196F3);
  static const Color teamPurple = Color(0xFF9C27B0);
  static const Color teamSilver = Color(0xFF757575);

  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Neutral colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Create the main theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.transparent,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cardColor,
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.25,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(
          color: textHint,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 16,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        backgroundColor: surfaceColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: textSecondary,
          height: 1.4,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 8,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        backgroundColor: surfaceColor,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        dense: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0.25,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 1.25,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 1.5,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 8,
        shape: CircleBorder(),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return Colors.grey.shade300;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.grey.shade400;
        }),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Colors.grey,
        circularTrackColor: Colors.grey,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Utility methods for consistent styling
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryLight, primaryColor, primaryDark],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentLight, accentColor, accentDark],
      );

  // Team-specific styling
  static Color getTeamColor(String team) {
    switch (team.toLowerCase()) {
      case 'blue':
        return teamBlue;
      case 'purple':
        return teamPurple;
      case 'silver':
        return teamSilver;
      default:
        return Colors.grey;
    }
  }

  static BoxDecoration getTeamDecoration(String team) {
    final color = getTeamColor(team);
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color, width: 2),
    );
  }

  // Status-specific styling
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'online':
        return successColor;
      case 'warning':
      case 'pending':
        return warningColor;
      case 'error':
      case 'inactive':
      case 'offline':
        return errorColor;
      case 'info':
      case 'neutral':
        return infoColor;
      default:
        return textSecondary;
    }
  }

  // Consistent spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Consistent border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 9999.0;

  // Icon sizes
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Level progression colors that represent advancement and achievement
  // Colors progressively darken within each tier as players approach the next level
  static Color getLevelBubbleColor(int level) {
    // Define level ranges and their base colors
    final tierData = _getLevelTierData(level);
    final baseColor = tierData['baseColor'] as Color;
    final tierStart = tierData['tierStart'] as int;
    final tierEnd = tierData['tierEnd'] as int;

    // Calculate progression within the tier (0.0 to 1.0)
    final tierProgress = (level - tierStart) / (tierEnd - tierStart);

    // Create extremely dramatic progression: start almost original color to very dark
    // This gives the most noticeable visual progression possible
    final darkeningFactor =
        0.005 + (tierProgress * 0.895); // 0.005 to 0.9 darkening

    return _darkenColor(baseColor, darkeningFactor);
  }

  // Helper function to get tier information for a given level
  static Map<String, dynamic> _getLevelTierData(int level) {
    if (level <= 5) {
      // Beginner - Green (fresh start, growth)
      return {
        'baseColor': const Color(0xFF4CAF50),
        'tierStart': 1,
        'tierEnd': 5,
        'tierName': 'Beginner'
      };
    } else if (level <= 15) {
      // Developing - Blue (steady progress)
      return {
        'baseColor': const Color(0xFF2196F3),
        'tierStart': 6,
        'tierEnd': 15,
        'tierName': 'Developing'
      };
    } else if (level <= 30) {
      // Intermediate - Purple (gaining expertise)
      return {
        'baseColor': const Color(0xFF9C27B0),
        'tierStart': 16,
        'tierEnd': 30,
        'tierName': 'Intermediate'
      };
    } else if (level <= 50) {
      // Advanced - Orange (experienced)
      return {
        'baseColor': const Color(0xFFFF9800),
        'tierStart': 31,
        'tierEnd': 50,
        'tierName': 'Advanced'
      };
    } else if (level <= 75) {
      // Expert - Red (mastery)
      return {
        'baseColor': const Color(0xFFF44336),
        'tierStart': 51,
        'tierEnd': 75,
        'tierName': 'Expert'
      };
    } else if (level <= 100) {
      // Master - Deep Purple (exceptional skill)
      return {
        'baseColor': const Color(0xFF673AB7),
        'tierStart': 76,
        'tierEnd': 100,
        'tierName': 'Master'
      };
    } else if (level <= 125) {
      // Legendary - Gold (prestige)
      return {
        'baseColor': const Color(0xFFFFD700),
        'tierStart': 101,
        'tierEnd': 125,
        'tierName': 'Legendary'
      };
    } else {
      // Mythical - Cyan (ultimate achievement)
      return {
        'baseColor': const Color(0xFF00BCD4),
        'tierStart': 126,
        'tierEnd': 150, // Assuming max level 150
        'tierName': 'Mythical'
      };
    }
  }

  // Helper function to darken a color by a given factor (0.0 = no change, 1.0 = black)
  static Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final darkenedLightness = (hsl.lightness * (1.0 - factor)).clamp(0.0, 1.0);
    return hsl.withLightness(darkenedLightness).toColor();
  }

  // Level progression gradients with progressive darkening within each tier
  static LinearGradient getLevelBubbleGradient(int level) {
    // Get tier data and calculate progressive darkening
    final tierData = _getLevelTierData(level);
    final baseColor = tierData['baseColor'] as Color;
    final tierStart = tierData['tierStart'] as int;
    final tierEnd = tierData['tierEnd'] as int;

    // Calculate progression within the tier (0.0 to 1.0)
    final tierProgress = (level - tierStart) / (tierEnd - tierStart);

    // Create gradient with extremely dramatic progression from almost original to very dark
    // Light shade: start with almost no darkening to light darkening
    // Dark shade: start with slight darkening to extremely dark
    final lightDarkeningFactor =
        0.002 + (tierProgress * 0.348); // 0.002 to 0.35
    final darkDarkeningFactor = 0.08 + (tierProgress * 0.87); // 0.08 to 0.95

    final lightColor = _darkenColor(baseColor, lightDarkeningFactor);
    final darkColor = _darkenColor(baseColor, darkDarkeningFactor);

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [lightColor, darkColor],
    );
  }
}
