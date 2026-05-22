import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _groupId = 'group.com.najim.snapcal'; // Replace with your app group
  static const String _iosWidgetName = 'SnapCalWidget';
  static const String _androidWidgetName = 'SnapCalWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_groupId);
  }

  static Future<void> updateWidgetData({
    required int remainingCalories,
    required double progress,
    required String status,
    required bool isLocked,
  }) async {
    try {
      // Save data for the widget to read
      await HomeWidget.saveWidgetData('remaining_calories', remainingCalories);
      await HomeWidget.saveWidgetData('calorie_progress', progress);
      await HomeWidget.saveWidgetData('calorie_status', status);
      await HomeWidget.saveWidgetData('is_locked', isLocked);

      // Trigger native refresh
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
      
      debugPrint("✅ WidgetService: Data updated for $remainingCalories kcal (Locked: $isLocked)");
    } catch (e) {
      debugPrint("❌ WidgetService: Update Error: $e");
    }
  }
}
