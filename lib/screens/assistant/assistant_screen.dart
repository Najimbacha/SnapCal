import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../data/services/premium_conversion_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/assistant_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';
import '../../widgets/premium_prompt_card.dart';
import '../../data/services/premium_gate_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  AnimationController? _staggerController;
  AssistantProvider? _assistantProvider;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _assistantProvider = context.read<AssistantProvider>();
    _assistantProvider?.addListener(_scrollToBottom);
    _staggerController?.forward();
    _loadInitialRecommendations();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _staggerController?.dispose();
    _assistantProvider?.removeListener(_scrollToBottom);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialRecommendations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<ConnectivityService>().isOnline) return;
      _fetchRecommendations(clearPrevious: true);
    });
  }

  void _fetchRecommendations({
    String? query,
    Uint8List? imageBytes,
    bool clearPrevious = false,
    bool forceFetch = false,
  }) {
    final assistantProvider = context.read<AssistantProvider>();
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    assistantProvider.fetchRecommendations(
      currentCalories: mealProvider.todaysTotalCalories,
      targetCalories: settingsProvider.dailyCalorieGoal,
      currentMacros: {
        'protein': mealProvider.todaysTotalMacros.protein,
        'carbs': mealProvider.todaysTotalMacros.carbs,
        'fat': mealProvider.todaysTotalMacros.fat,
      },
      targetMacros: {
        'protein': settingsProvider.dailyProteinGoal,
        'carbs': settingsProvider.dailyCarbGoal,
        'fat': settingsProvider.dailyFatGoal,
      },
      mealNames: mealProvider.todaysMeals.map((m) => m.foodName).toList(),
      dietaryRestriction: settingsProvider.dietaryRestriction,
      userQuery: query,
      imageBytes: imageBytes,
      clearPrevious: clearPrevious,
      forceFetch: forceFetch,
      language: settingsProvider.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isPro = settings.isPro;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.pop();
      },
      child: AppPageScaffold(
        title: "AI Coach",
        padding: EdgeInsets.zero,
        trailing: _RefreshHeaderButton(
          onTap:
              () =>
                  _fetchRecommendations(clearPrevious: true, forceFetch: true),
        ),
        bottomBar: _buildInputArea(context, isPro),
        child: Consumer<AssistantProvider>(
          builder: (context, assistant, _) {
            final content = _buildChatContent(context, assistant);
            final hasReachedLimit = PremiumGateService().hasReachedAiLimit(
              isPro,
            );
            if (!isPro && hasReachedLimit) {
              return Stack(
                children: [
                  content,
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: PremiumPromptCard(
                      style: PremiumPromptStyle.glass,
                      title: l10n.coach_limit_title,
                      subtitle: l10n.coach_limit_subtitle,
                      buttonText: l10n.coach_limit_btn,
                      icon: LucideIcons.sparkles,
                      onTap:
                          () => PremiumConversionService().openPaywall(
                            context,
                            PaywallEntryPoint.aiCoachLimit,
                            featureName: 'ai_coach',
                          ),
                    ),
                  ),
                ],
              );
            }
            if (!isPro && assistant.history.isEmpty) {
              return const _LockedCoachPreview();
            }
            return content;
          },
        ),
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, AssistantProvider assistant) {
    if (assistant.error != null && assistant.history.isEmpty) {
      return Center(
        child: AppInlineFallback(
          icon: LucideIcons.alertTriangle,
          title: AppLocalizations.of(context)!.assistant_title,
          message: AppLocalizations.of(context)!.error_generic,
          actionLabel: AppLocalizations.of(context)!.assistant_retry,
          onAction: _loadInitialRecommendations,
        ),
      );
    }
    if (assistant.history.isEmpty && assistant.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: AppSectionSkeleton(rows: 4),
      );
    }
    if (assistant.history.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Icon(
                LucideIcons.sparkles,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.assistant_initial_prompt,
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.assistant_initial_body,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _RecommendationGrid(
                onSelect:
                    (q) => _fetchRecommendations(query: q, clearPrevious: true),
              ),
            ],
          ),
        ),
      );
    }
    return AppAsyncOverlay(
      state: assistant.uiState,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: assistant.history.length,
        itemBuilder: (context, index) {
          return _ChatMessageTile(message: assistant.history[index]);
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isPro) {
    final l10n = AppLocalizations.of(context)!;

    if (!isPro && PremiumGateService().hasReachedAiLimit(isPro)) {
      return const SizedBox.shrink();
    }
    if (!isPro) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(
            top: BorderSide(color: context.dividerColor.withValues(alpha: 0.1)),
          ),
        ),
        child: AppScaleTap(
          onTap:
              () => PremiumConversionService().openPaywall(
                context,
                PaywallEntryPoint.aiCoachLimit,
                featureName: 'ai_coach',
              ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                l10n.coach_see_options,
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(color: context.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.backgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.assistant_input_hint,
                  border: InputBorder.none,
                ),
                onSubmitted: (q) {
                  if (q.trim().isNotEmpty) {
                    _fetchRecommendations(query: q);
                    _searchController.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppScaleTap(
            onTap: () async {
              final q = _searchController.text;
              if (q.trim().isNotEmpty) {
                _fetchRecommendations(query: q);
                _searchController.clear();
                if (!isPro) {
                  await PremiumGateService().incrementAiMessages();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshHeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RefreshHeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Icon(
          LucideIcons.refreshCw,
          size: 20,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _LockedCoachPreview extends StatelessWidget {
  const _LockedCoachPreview();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.cardBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.24 : 0.06,
                        ),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.sparkles,
                          color: colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.coach_locked_title,
                        style: AppTypography.heading2.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.coach_locked_desc,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _CoachPreviewCard(
                  icon: LucideIcons.utensils,
                  title: l10n.coach_preview_meal_title,
                  body: l10n.coach_preview_meal_body,
                ),
                const SizedBox(height: 10),
                _CoachPreviewCard(
                  icon: LucideIcons.barChart3,
                  title: l10n.coach_preview_macro_title,
                  body: l10n.coach_preview_macro_body,
                ),
                const SizedBox(height: 10),
                _CoachPreviewCard(
                  icon: LucideIcons.messageCircle,
                  title: l10n.coach_preview_feedback_title,
                  body: l10n.coach_preview_feedback_body,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoachPreviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _CoachPreviewCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.textSecondaryColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageTile extends StatelessWidget {
  final dynamic message;
  const _ChatMessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isUser;
    final String content;

    if (message is Map) {
      isUser = message['role'] == 'user' || message['type'] == 'user';
      content = message['content'] as String? ?? '';
    } else if (message is AssistantResponse) {
      isUser = false;
      content = message.content;
    } else {
      isUser = false;
      content = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 14,
              child: Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : context.cardColor,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.bodyMedium.copyWith(
                    color: isUser ? Colors.white : context.textPrimaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  final Function(String) onSelect;
  const _RecommendationGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final queries = [
      l10n.assistant_starter_cal_desc,
      l10n.assistant_starter_meal_desc,
      l10n.assistant_starter_plans_desc,
      l10n.assistant_starter_tips_desc,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          queries
              .map((q) => _QueryChip(label: q, onTap: () => onSelect(q)))
              .toList(),
    );
  }
}

class _QueryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QueryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
