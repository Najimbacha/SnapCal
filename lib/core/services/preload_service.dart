import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/camera_service.dart';
import '../../providers/meal_provider.dart';

/// Central service to coordinate all preloading/warming tasks
class PreloadService {
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  bool _hasPreloaded = false;

  /// Main entry point for preloading. Call this after first frame of Home Screen.
  Future<void> preloadAll(BuildContext context) async {
    if (_hasPreloaded) return;
    _hasPreloaded = true;

    debugPrint('🚀 PreloadService: Starting background preloading tasks...');

    // 1. Warm up camera hardware early
    CameraService().warmup();

    // 2. Pre-cache static assets (Logo, etc)
    _precacheStaticAssets(context);

    // 3. Pre-cache user-specific dynamic data (Recent meal images)
    _precacheUserImages(context);

    debugPrint('✅ PreloadService: Background tasks dispatched');
  }

  void _precacheStaticAssets(BuildContext context) {
    // Preload the app logo
    precacheImage(const AssetImage('assets/icon/icon.png'), context);
  }

  void _precacheUserImages(BuildContext context) {
    try {
      final mealProvider = (context.read<MealProvider>());
      // Pre-cache the top 3 most recent meals to avoid flickering on dashboard
      final recentMeals = mealProvider.recentMeals.take(3);

      for (final meal in recentMeals) {
        if (meal.imageUri != null && meal.imageUri!.isNotEmpty) {
          // Pre-cache local file images
          precacheImage(FileImage(File(meal.imageUri!)), context);
        }
      }
    } catch (e) {
      debugPrint('⚠️ PreloadService: User image preloading skipped ($e)');
    }
  }
}
