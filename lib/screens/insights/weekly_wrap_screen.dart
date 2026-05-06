import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:snapcal/core/theme/app_colors.dart';
import 'package:snapcal/core/theme/app_typography.dart';
import 'package:snapcal/providers/insights_provider.dart';
import 'package:snapcal/widgets/app_page_scaffold.dart';
import 'package:snapcal/widgets/glass_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/week_chart.dart';

class WeeklyWrapScreen extends StatefulWidget {
  const WeeklyWrapScreen({super.key});

  @override
  State<WeeklyWrapScreen> createState() => _WeeklyWrapScreenState();
}

class _WeeklyWrapScreenState extends State<WeeklyWrapScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareReport() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/weekly_wrap.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: l10n.feature_insights_share_text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightsProvider = context.watch<InsightsProvider>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (insightsProvider.isGenerating) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                l10n.feature_insights_generating,
                style: AppTypography.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    final report = insightsProvider.currentReport;
    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.feature_insights_title)),
        body: Center(
          child: Text('No data for this week yet.', style: AppTypography.titleMedium),
        ),
      );
    }

    return AppPageScaffold(
      title: l10n.feature_insights_title,
      subtitle: l10n.feature_insights_desc,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              color: colorScheme.surface,
              child: Column(
                children: [
                  // Hero Stat
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            l10n.feature_insights_avg_cal(report.avgCalories.round().toString()),
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.feature_insights_on_track(report.daysOnTrack.toString()),
                            style: AppTypography.titleMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calorie Chart
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calorie Trend',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        WeekChart(dailyCalories: report.dailyCalories),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // AI Insights
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Coach Insights',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...report.aiInsights.map((insight) => InsightCard(insight: insight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.share2, size: 18),
            label: Text(l10n.feature_insights_share),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _shareReport,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
