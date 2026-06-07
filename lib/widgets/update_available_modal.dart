import 'package:flutter/material.dart';
import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/widgets/app_icon.dart';

class UpdateAvailableModal {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onUpdate,
    VoidCallback? onDismiss,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.warmDarkSurface : AppColors.minimalBg;
    final textColor = isDark ? Colors.white : AppColors.warmInk;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.legacyDeepForest.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppSymbols.refreshCw,
                        color: AppColors.legacyGreenText,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onUpdate();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.legacyDeepForest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Update Now',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        onDismiss?.call();
                      },
                      child: Text(
                        'Remind Later',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
