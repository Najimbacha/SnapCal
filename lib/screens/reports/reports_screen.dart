import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/utils/responsive_utils.dart';
import '../../widgets/app_page_scaffold.dart';
import 'widgets/body_report_view.dart';
import 'widgets/nutrition_report_view.dart';
import '../../data/services/report_pdf_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  String _timeRange = 'Weekly';
  late final AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 6; i++) {
      _itemAnims.add(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1, (i * 0.1) + 0.4, curve: Curves.easeOutQuart),
        ),
      );
    }
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _exportPdfReport() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final mealProvider = context.read<MealProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final authProvider = context.read<AuthProvider>();
      
      final userName = authProvider.user?.displayName ?? 
                       authProvider.user?.email?.split('@').first ?? 
                       'Valued User';

      await ReportPdfService.generateAndShareReport(
        userName: userName,
        meals: mealProvider.getWeeklyMeals(),
        settings: settingsProvider,
        streak: settingsProvider.currentStreak,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: AppPageScaffold(
        title: 'Insights',
        subtitle: 'Advanced analytics for your health journey.',
        padding: EdgeInsets.zero,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScaleTap(
              onTap: _exportPdfReport,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(LucideIcons.share, size: 20, color: colorScheme.primary),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                HapticFeedback.mediumImpact();
                setState(() => _timeRange = value);
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              offset: const Offset(0, 48),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Weekly', child: Text('Weekly Review')),
                PopupMenuItem(value: 'Monthly', child: Text('Monthly Audit')),
              ],
              child: _ScaleTap(
                onTap: () {}, // Handled by PopupMenuButton
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.calendarRange, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        _timeRange,
                        style: AppTypography.labelLarge.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _staggeredSlide(
              _itemAnims[0],
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.hPadding(context)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: context.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: context.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: context.textSecondaryColor,
                    labelStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [Tab(text: 'Nutrition'), Tab(text: 'Body Metrics')],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _staggeredSlide(
                _itemAnims[1],
                const TabBarView(
                  physics: BouncingScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: NutritionReportView(),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: BodyReportView(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}
