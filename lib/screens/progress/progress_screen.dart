import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../providers/metrics_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import 'widgets/photo_capture_flow.dart';
import 'widgets/photo_comparison_sheet.dart';
import 'widgets/progress_card.dart';
import 'widgets/weight_trend_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/transformation_video_service.dart';
import 'package:share_plus/share_plus.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<Animation<double>> _itemAnims = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < 8; i++) {
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

  void _handleCapture(BuildContext context, bool canAdd) {
    if (canAdd) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PhotoCaptureFlow()),
      );
    } else {
      context.push('/paywall');
    }
  }

  bool _isGenerating = false;

  Future<void> _generateJourney(List<dynamic> photos) async {
    if (photos.length < 2) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.progress_video_min_photos)));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final paths =
          photos
              .map((m) => m.photoFrontPath ?? m.photoSidePath)
              .whereType<String>()
              .toList();

      final videoPath = await TransformationVideoService().generateVideo(paths);

      if (videoPath != null) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(videoPath)],
            text: l10n.progress_video_share_text,
          ),
        );
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.progress_video_failed)));
        }
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<MetricsProvider>(
      builder: (context, provider, _) {
        final photos = provider.metricsWithPhotos;
        final trend = provider.recentTrend;
        final canAdd = provider.canAddPhoto;

        final l10n = AppLocalizations.of(context)!;

        return AppPageScaffold(
          title: l10n.report_tab_body,
          subtitle: null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (photos.length >= 2)
                _ScaleTap(
                  onTap: () => _generateJourney(photos),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child:
                        _isGenerating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              LucideIcons.video,
                              color: AppColors.primary,
                              size: 20,
                            ),
                  ),
                ),
              _ScaleTap(
                onTap: () => _handleCapture(context, canAdd),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              if (trend.isNotEmpty)
                _staggeredSlide(
                  _itemAnims[0],
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppSectionCard(
                      glass: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: WeightTrendChart(metrics: trend),
                    ),
                  ),
                ),
              Expanded(
                child:
                    photos.isEmpty
                        ? _staggeredSlide(
                          _itemAnims[1],
                          _buildEmpty(context, canAdd),
                        )
                        : _buildList(context, photos),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, bool canAdd) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: AppEmptyState(
        icon: LucideIcons.image,
        title: l10n.report_no_weight_title,
        body: l10n.progress_take_photos_desc,
        actionLabel:
            canAdd ? l10n.progress_tap_to_snap : l10n.planner_upgrade_pro,
        onAction: () => _handleCapture(context, canAdd),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<dynamic> photos) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      physics: const BouncingScrollPhysics(),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final metric = photos[i];
        final startDelay = ((i + 2) % 10) * 0.1;
        final endDelay = (startDelay + 0.4).clamp(0.0, 1.0);
        
        final anim = CurvedAnimation(
          parent: _animController,
          curve: Interval(
            startDelay,
            endDelay,
            curve: Curves.easeOutQuart,
          ),
        );

        return _staggeredSlide(
          anim,
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ProgressCard(
              metric: metric,
              onCompare:
                  (i < photos.length - 1)
                      ? () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (_) => PhotoComparisonSheet(
                                current: metric,
                                previous: photos[i + 1],
                              ),
                        );
                      }
                      : null,
            ),
          ),
        );
      },
    );
  }
}

Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap>
    with SingleTickerProviderStateMixin {
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
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
