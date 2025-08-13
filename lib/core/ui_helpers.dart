import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UIHelpers {
  /// Ensures proper safe area handling for all screens
  static Widget safeAreaWrapper({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }

  /// Gets the safe area padding for manual calculations
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Gets the bottom safe area height (for navigation bars)
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Gets the top safe area height (for status bars)
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Sets the system UI overlay style for consistent appearance
  static void setSystemUIOverlayStyle({
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.light,
        systemNavigationBarColor: systemNavigationBarColor ?? const Color(0xFF1F2937),
        systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ?? Brightness.light,
      ),
    );
  }

  /// Ensures minimum touch target size for accessibility
  static Widget ensureMinTouchTarget({
    required Widget child,
    double minSize = 48.0,
  }) {
    return SizedBox(
      width: minSize,
      height: minSize,
      child: child,
    );
  }

  /// Adds consistent padding that respects safe areas
  static EdgeInsets getScreenPadding(BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
    bool respectSafeArea = true,
  }) {
    if (!respectSafeArea) {
      return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
    }

    final safeArea = MediaQuery.of(context).padding;
    return EdgeInsets.only(
      left: horizontal + safeArea.left,
      right: horizontal + safeArea.right,
      top: vertical + safeArea.top,
      bottom: vertical + safeArea.bottom,
    );
  }
}