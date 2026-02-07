import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import 'widgets/nutrition_report_view.dart';
import 'widgets/body_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _timeRange = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.backgroundColor,
        appBar: AppBar(
          backgroundColor: context.backgroundColor,
          title: Text('$_timeRange Insights'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(text: 'Nutrition'), Tab(text: 'Body')],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _timeRange = value),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
                    const PopupMenuItem(
                      value: 'Monthly',
                      child: Text('Monthly'),
                    ),
                  ],
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: const TabBarView(
          children: [NutritionReportView(), BodyReportView()],
        ),
      ),
    );
  }
}
