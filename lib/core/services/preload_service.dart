import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/camera_service.dart';
import '../../data/repositories/meal_repository.dart';

class PreloadService {
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  bool _hasPreloaded = false;

  Future<void> preloadAll(BuildContext context) async {
    if (_hasPreloaded) return;
    _hasPreloaded = true;

    debugPrint('🚀 PreloadService: Starting background preloading tasks...');

    CameraService().warmup();
    _precacheStaticAssets(context);
    _precacheUserImages(context);

    debugPrint('✅ PreloadService: Background tasks dispatched');
  }

  void _precacheStaticAssets(BuildContext context) {
    precacheImage(const AssetImage('assets/icon/icon.png'), context);
  }

  void _precacheUserImages(BuildContext context) {
    try {
      final repo = MealRepository();
      repo.init();
      final recentMeals = repo.getRecentMeals(count: 3);

      for (final meal in recentMeals) {
        if (meal.imageUri != null && meal.imageUri!.isNotEmpty) {
          precacheImage(FileImage(File(meal.imageUri!)), context);
        }
      }
    } catch (e) {
      debugPrint('⚠️ PreloadService: Failed to pre-cache images: $e');
    }
  }
}
