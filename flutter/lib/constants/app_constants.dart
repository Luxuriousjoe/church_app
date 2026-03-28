import 'package:flutter/material.dart';

class AppConstants {
  // ─── API ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://your-backend.onrender.com/api';
  // For local development: 'http://10.0.2.2:5000/api'

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName    = 'SHARE GRACE FAMILY CHURCH';
  static const String appTagline = 'Media Ministry';
  static const String appVersion = '1.0.0';

  // ─── Storage Keys ─────────────────────────────────────────────────────────
  static const String kAccessToken   = 'access_token';
  static const String kRefreshToken  = 'refresh_token';
  static const String kUserData      = 'user_data';

  // ─── Workmanager Task Names ────────────────────────────────────────────────
  static const String kUploadTask     = 'church_media_upload_task';
  static const String kUploadTaskTag  = 'church_upload';

  // ─── Pagination ───────────────────────────────────────────────────────────
  static const int pageSize = 20;

  // ─── Media Types ──────────────────────────────────────────────────────────
  static const String typeVideo = 'video';
  static const String typePhoto = 'photo';
  static const String typeAudio = 'audio';

  // ─── Upload Status ────────────────────────────────────────────────────────
  static const String statusPending   = 'pending';
  static const String statusUploading = 'uploading';
  static const String statusUploaded  = 'uploaded';
  static const String statusFailed    = 'failed';
}

// ─── Color Palette ──────────────────────────────────────────────────────────
class AppColors {
  // Deep Navy + Warm Gold — inspired by sacred architecture
  static const Color primary      = Color(0xFF0D1B2A);   // Deep midnight navy
  static const Color primaryLight = Color(0xFF1B2E45);
  static const Color accent       = Color(0xFFD4AF37);   // Sacred gold
  static const Color accentLight  = Color(0xFFF0D060);
  static const Color accentDark   = Color(0xFFB8960C);

  static const Color surface      = Color(0xFF0F2035);
  static const Color surfaceCard  = Color(0xFF162840);
  static const Color surfaceLight = Color(0xFF1E3655);

  static const Color textPrimary  = Color(0xFFF5F0E8);   // Warm white
  static const Color textSecondary= Color(0xFFAAB8C8);
  static const Color textMuted    = Color(0xFF5E7A94);

  static const Color success      = Color(0xFF4CAF82);
  static const Color warning      = Color(0xFFFFB347);
  static const Color error        = Color(0xFFE05B5B);
  static const Color info         = Color(0xFF5BA4E0);

  static const Color divider      = Color(0xFF1E3655);
  static const Color overlay      = Color(0x99000000);

  // Gradient stops
  static const List<Color> primaryGradient = [Color(0xFF0D1B2A), Color(0xFF1A3050)];
  static const List<Color> goldGradient    = [Color(0xFFD4AF37), Color(0xFFF0D060)];
  static const List<Color> heroGradient    = [Color(0xFF0A1628), Color(0xFF0D1B2A), Color(0xFF1A3050)];
}

// ─── Text Styles ────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Lato',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Lato',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Lato',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle labelGold = TextStyle(
    fontFamily: 'Lato',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    letterSpacing: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Lato',
    fontSize: 11,
    fontWeight: FontWeight.w300,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
}

// ─── App Theme ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary:   AppColors.accent,
      secondary: AppColors.accentLight,
      surface:   AppColors.surface,
      background:AppColors.primary,
      error:     AppColors.error,
      onPrimary: AppColors.primary,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.primary,
    fontFamily: 'Lato',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.titleLarge,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
cardTheme: const CardThemeData(
  color: AppColors.surfaceCard,
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  ),
  margin: EdgeInsets.all(8),
),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      labelStyle: AppTextStyles.bodyMedium,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Lato'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Lato',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}
