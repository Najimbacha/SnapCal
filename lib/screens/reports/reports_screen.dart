import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/body_report_view.dart';
import 'widgets/nutrition_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _timeRange = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: AppPageScaffold(
        title: 'Insights',
        subtitle:
            'Trend analysis and health progress data.',
        trailing: PopupMenuButton<String>(
          onSelected: (value) => setState(() => _timeRange = value),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          itemBuilder:
              (context) => const [
                PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
              ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: ShapeDecoration(
              color: colorScheme.surfaceContainerHigh,
              shape: StadiumBorder(
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.calendar, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _timeRange,
                  style: AppTypography.labelLarge.copyWith(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionCard(
              padding: const EdgeInsets.all(6),
              color: colorScheme.surfaceContainerLow,
              child: TabBar(
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(28),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: AppTypography.labelLarge,
                unselectedLabelStyle: AppTypography.labelLarge,
                dividerColor: Colors.transparent,
                tabs: const [Tab(text: 'Nutrition'), Tab(text: 'Body')],
              ),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: TabBarView(
                children: [NutritionReportView(), BodyReportView()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
