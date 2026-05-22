import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  Uint8List? _selectedImageBytes;

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

  Future<bool> _fetchRecommendations({
    String? query,
    Uint8List? imageBytes,
    bool clearPrevious = false,
    bool forceFetch = false,
  }) {
    final assistantProvider = context.read<AssistantProvider>();
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    return assistantProvider.fetchRecommendations(
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
        title: l10n.assistant_title,
        headerHeight: 56,
        padding: EdgeInsets.zero,
        leading: const _CoachBackButton(),
        trailing: _NewChatHeaderButton(
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
            if (!isPro && assistant.history.isEmpty && hasReachedLimit) {
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
      return _CoachWelcomeExperience(
        onSelect: (q) => _fetchRecommendations(query: q, clearPrevious: true),
      );
    }
    return AppAsyncOverlay(
      state: assistant.uiState,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
        itemCount: assistant.history.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _CoachThreadHeader();
          }
          return _ChatMessageTile(message: assistant.history[index - 1]);
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, bool isPro) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (!isPro && PremiumGateService().hasReachedAiLimit(isPro)) {
      return const SizedBox.shrink();
    }

    Future<void> submitCoachQuery([String? preset]) async {
      final q = (preset ?? _searchController.text).trim();
      if (q.isEmpty && _selectedImageBytes == null) return;

      final finalQuery = q.isEmpty ? l10n.assistant_analyze_image_prompt : q;
      final success = await _fetchRecommendations(
        query: finalQuery,
        imageBytes: _selectedImageBytes,
      );
      _searchController.clear();
      setState(() {
        _selectedImageBytes = null;
      });
      if (success && !isPro) {
        await PremiumGateService().incrementAiMessages();
      }
    }

    Future<void> pickImage() async {
      if (!isPro) {
        PremiumConversionService().openPaywall(
          context,
          PaywallEntryPoint.aiCoachLimit,
          featureName: 'ai_coach_image',
        );
        return;
      }
      final ImagePicker picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder:
            (context) => SafeArea(
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(LucideIcons.camera),
                    title: Text(l10n.common_camera),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                  ListTile(
                    leading: const Icon(LucideIcons.image),
                    title: Text(l10n.snap_gallery),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
      );
      if (source == null) return;
      try {
        final image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        if (image == null) return;
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      } catch (e) {
        debugPrint("Error picking image: $e");
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(color: context.cardBorderColor, width: 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ComposerQuickQuestions(onSelect: submitCoachQuery),
          const SizedBox(height: 10),
          if (_selectedImageBytes != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _selectedImageBytes!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageBytes = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: context.primaryColor.withValues(alpha: 0.16),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                AppScaleTap(
                  onTap: pickImage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.cardBorderColor),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      color: context.primaryColor,
                      size: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: context.primaryColor,
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.assistant_input_hint,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: context.textMutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: submitCoachQuery,
                  ),
                ),
                const SizedBox(width: 8),
                AppScaleTap(
                  onTap: submitCoachQuery,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowUp,
                      color: Colors.white,
                      size: 21,
                    ),
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

class _ComposerQuickQuestions extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _ComposerQuickQuestions({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final questions = [
      (LucideIcons.target, l10n.assistant_quick_macros),
      (LucideIcons.utensils, l10n.assistant_quick_next_meal),
      (LucideIcons.dumbbell, l10n.assistant_quick_snack),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (var i = 0; i < questions.length; i++) ...[
            AppScaleTap(
              onTap: () => onSelect(questions[i].$2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.cardBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      questions[i].$1,
                      size: 14,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      questions[i].$2,
                      style: AppTypography.labelMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != questions.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CoachWelcomeExperience extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _CoachWelcomeExperience({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mealProvider = context.watch<MealProvider>();
    final settings = context.watch<SettingsProvider>();
    final meals = mealProvider.todaysMeals;
    final calories = mealProvider.todaysTotalCalories;
    final targetCalories = settings.dailyCalorieGoal;
    final caloriesLeft = (targetCalories - calories).clamp(0, 99999).toInt();
    final proteinGap =
        (settings.dailyProteinGoal - mealProvider.todaysTotalMacros.protein)
            .clamp(0, 999)
            .toInt();
    final progress =
        targetCalories <= 0
            ? 0.0
            : (calories / targetCalories).clamp(0.0, 1.0).toDouble();
    final lastMeal =
        meals.isEmpty ? l10n.assistant_no_meals_logged : meals.last.foodName;
    final action =
        meals.isEmpty
            ? l10n.assistant_action_log_meal
            : proteinGap > 20
            ? l10n.assistant_action_protein
            : caloriesLeft < 300
            ? l10n.assistant_action_light
            : l10n.assistant_action_balanced;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Colors.white,
                          size: 26,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        duration: 1800.ms,
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1.04, 1.04),
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.assistant_initial_prompt,
                          style: AppTypography.headlineSmall.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.assistant_meals_logged_today(meals.length),
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textSecondaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _CoachBriefCard(
                calories: calories,
                targetCalories: targetCalories,
                caloriesLeft: caloriesLeft,
                proteinGap: proteinGap,
                lastMeal: lastMeal,
                action: action,
                progress: progress,
              ),
              const SizedBox(height: 16),
              _CoachActionChips(onSelect: onSelect),
              const SizedBox(height: 18),
              Text(
                l10n.assistant_ask_coach_header,
                style: AppTypography.titleMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _RecommendationGrid(onSelect: onSelect),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachBriefCard extends StatelessWidget {
  final int calories;
  final int targetCalories;
  final int caloriesLeft;
  final int proteinGap;
  final String lastMeal;
  final String action;
  final double progress;

  const _CoachBriefCard({
    required this.calories,
    required this.targetCalories,
    required this.caloriesLeft,
    required this.proteinGap,
    required this.lastMeal,
    required this.action,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.assistant_brief_today,
                  style: AppTypography.titleMedium.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.assistant_live,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.cardBorderColor.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CoachStatTile(
                  label: l10n.assistant_brief_left,
                  value: "$caloriesLeft",
                  unit: "kcal",
                  icon: LucideIcons.flame,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoachStatTile(
                  label: l10n.assistant_protein_gap,
                  value: "${proteinGap}g",
                  unit: l10n.assistant_to_goal,
                  icon: LucideIcons.dumbbell,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CoachSignalChip(
            icon: LucideIcons.utensils,
            label: l10n.assistant_last_meal,
            value: lastMeal,
          ),
          const SizedBox(height: 8),
          _CoachSignalChip(
            icon: LucideIcons.target,
            label: l10n.assistant_next_move,
            value: action,
          ),
        ],
      ),
    );
  }
}

class _CoachStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _CoachStatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  unit,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachSignalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CoachSignalChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(width: 9),
          Text(
            "$label:",
            style: AppTypography.bodySmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachActionChips extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _CoachActionChips({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      (LucideIcons.target, l10n.assistant_action_fix_macros),
      (LucideIcons.utensils, l10n.assistant_action_plan_next_meal),
      (LucideIcons.salad, l10n.assistant_action_light_dinner),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          actions
              .map(
                (action) => AppScaleTap(
                  onTap: () => onSelect(action.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.cardBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(action.$1, size: 15, color: context.primaryColor),
                        const SizedBox(width: 7),
                        Text(
                          action.$2,
                          style: AppTypography.labelMedium.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _CoachThreadHeader extends StatelessWidget {
  const _CoachThreadHeader();

  @override
  Widget build(BuildContext context) {
    final meals = context.watch<MealProvider>().todaysMeals.length;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.cardBorderColor),
              ),
              child: Text(
                l10n.assistant_coaching_with_meals(meals),
                style: AppTypography.bodySmall.copyWith(
                  color: context.textSecondaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachBackButton extends StatelessWidget {
  const _CoachBackButton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.common_back,
      child: AppScaleTap(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: context.textPrimaryColor,
          ),
        ),
      ),
    );
  }
}

class _NewChatHeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewChatHeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.assistant_start_new_chat,
      child: AppScaleTap(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 17, color: context.primaryColor),
              const SizedBox(width: 5),
              Text(
                l10n.assistant_new_chat,
                style: AppTypography.labelMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedCoachPreview extends StatelessWidget {
  const _LockedCoachPreview();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: context.cardBorderColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.28 : 0.08,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.lock,
                              color: Colors.white,
                              size: 32,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            duration: 2.seconds,
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.05, 1.05),
                          ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.coach_locked_title,
                        style: AppTypography.headlineSmall.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.coach_locked_desc,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.textSecondaryColor,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _CoachPreviewCard(
                  icon: LucideIcons.utensils,
                  title: l10n.coach_preview_meal_title,
                  body: l10n.coach_preview_meal_body,
                ),
                const SizedBox(height: 12),
                _CoachPreviewCard(
                  icon: LucideIcons.barChart3,
                  title: l10n.coach_preview_macro_title,
                  body: l10n.coach_preview_macro_body,
                ),
                const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
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
                    height: 1.35,
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
    final l10n = AppLocalizations.of(context)!;
    final bool isUser;
    final String content;
    String title = l10n.assistant_coach_insight;
    String type = "coaching";
    Map<String, int>? macros;

    if (message is Map) {
      isUser = message['role'] == 'user' || message['type'] == 'user';
      content = message['content'] as String? ?? '';
    } else if (message is AssistantResponse) {
      isUser = false;
      content = message.content;
      title =
          message.title.isEmpty ? l10n.assistant_coach_insight : message.title;
      type = message.type;
      macros = message.macros;
    } else {
      isUser = false;
      content = '';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    22,
                  ).copyWith(bottomRight: const Radius.circular(6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isRecipe = type == 'recipe' || _ParsedRecipe.looksLikeRecipe(content);
    if (isRecipe) {
      return _RecipePlanCard(
        title: _ParsedRecipe.displayTitle(
          title,
          content,
          l10n.assistant_coach_insight,
          l10n.assistant_recipe_plan,
        ),
        content: content,
        macros: macros,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleSmall.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        type == 'recipe'
                            ? l10n.assistant_recipe_estimated_macros
                            : l10n.assistant_personalized_from_today,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.textMutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (macros != null) ...[
              _CoachMacroEstimate(macros: macros),
              const SizedBox(height: 12),
            ],
            MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: AppTypography.bodyMedium.copyWith(
                  color: context.textPrimaryColor,
                  height: 1.48,
                ),
                strong: AppTypography.bodyMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                ),
                listBullet: AppTypography.bodyMedium.copyWith(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const _CoachResponseActions(),
          ],
        ),
      ),
    );
  }
}

class _RecipePlanCard extends StatelessWidget {
  final String title;
  final String content;
  final Map<String, int>? macros;

  const _RecipePlanCard({
    required this.title,
    required this.content,
    required this.macros,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parsed = _ParsedRecipe.fromMarkdown(content);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: context.cardBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.12),
                      AppColors.violet.withValues(alpha: isDark ? 0.22 : 0.08),
                      AppColors.amber.withValues(alpha: isDark ? 0.14 : 0.08),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: AppColors.premiumGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.chefHat,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleLarge.copyWith(
                                  color: context.textPrimaryColor,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.assistant_step_recipe_plan,
                                style: AppTypography.labelMedium.copyWith(
                                  color: context.textSecondaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.10 : 0.72,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: isDark ? 0.12 : 0.45,
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.assistant_recipe,
                            style: AppTypography.labelSmall.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (macros != null) ...[
                      const SizedBox(height: 14),
                      _CoachMacroEstimate(macros: macros!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child:
                    parsed.hasStructure
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (parsed.ingredients.isNotEmpty) ...[
                              _RecipeSection(
                                icon: LucideIcons.utensils,
                                title: l10n.assistant_ingredients,
                                child: _IngredientWrap(
                                  ingredients: parsed.ingredients,
                                ),
                              ),
                            ],
                            if (parsed.ingredients.isNotEmpty &&
                                parsed.steps.isNotEmpty)
                              const SizedBox(height: 18),
                            if (parsed.steps.isNotEmpty) ...[
                              _RecipeSection(
                                icon: LucideIcons.listChecks,
                                title: l10n.assistant_what_to_do,
                                child: _RecipeSteps(steps: parsed.steps),
                              ),
                            ],
                            if (parsed.note.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              _RecipeNote(note: parsed.note),
                            ],
                          ],
                        )
                        : MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTypography.bodyMedium.copyWith(
                              color: context.textPrimaryColor,
                              height: 1.48,
                            ),
                            listBullet: AppTypography.bodyMedium.copyWith(
                              color: context.primaryColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParsedRecipe {
  final List<String> ingredients;
  final List<String> steps;
  final String note;

  const _ParsedRecipe({
    required this.ingredients,
    required this.steps,
    required this.note,
  });

  bool get hasStructure =>
      ingredients.isNotEmpty || steps.isNotEmpty || note.isNotEmpty;

  static bool looksLikeRecipe(String content) {
    final lower = content.toLowerCase();
    return lower.contains('ingredient') ||
        lower.contains('### steps') ||
        (lower.contains('combine ') && lower.contains('cook')) ||
        (lower.contains('recipe') && lower.contains('step'));
  }

  static String displayTitle(
    String title,
    String content,
    String defaultCoachTitle,
    String fallbackRecipeTitle,
  ) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty && trimmedTitle != defaultCoachTitle) {
      return trimmedTitle;
    }

    for (final rawLine in content.split('\n')) {
      final cleaned =
          _cleanItem(rawLine)
              .replaceFirst(RegExp(r'^#+\s*'), '')
              .replaceFirst(RegExp(r'^title:\s*', caseSensitive: false), '')
              .trim();
      final lower = cleaned.toLowerCase();
      if (cleaned.isEmpty ||
          lower.contains('ingredient') ||
          lower.contains('step') ||
          lower.contains('coach') ||
          lower.contains('nutrition')) {
        continue;
      }
      if (cleaned.length <= 42 && !cleaned.contains('.')) {
        return cleaned;
      }
    }

    return fallbackRecipeTitle;
  }

  factory _ParsedRecipe.fromMarkdown(String content) {
    final ingredients = <String>[];
    final steps = <String>[];
    final noteLines = <String>[];
    var section = '';

    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final normalized =
          line.replaceFirst(RegExp(r'^#+\s*'), '').replaceAll('**', '').trim();
      final lower = normalized.toLowerCase();
      final payload =
          normalized.contains(':')
              ? normalized.substring(normalized.indexOf(':') + 1).trim()
              : '';

      if (_matchesHeading(lower, const ['ingredient'])) {
        section = 'ingredients';
        if (payload.isNotEmpty) {
          ingredients.addAll(_splitIngredientPayload(payload));
        }
        continue;
      }
      if (_matchesHeading(lower, const [
        'step',
        'method',
        'instruction',
        'what to do',
        'directions',
      ])) {
        section = 'steps';
        if (payload.isNotEmpty) {
          steps.add(_cleanItem(payload));
        }
        continue;
      }
      if (_matchesHeading(lower, const ['coach', 'nutrition', 'note'])) {
        section = 'note';
        if (payload.isNotEmpty) {
          noteLines.add(_cleanItem(payload));
        }
        continue;
      }

      final cleaned = _cleanItem(normalized);
      if (cleaned.isEmpty) continue;

      if (section == 'ingredients') {
        ingredients.addAll(_splitIngredientPayload(cleaned));
      } else if (section == 'steps') {
        steps.add(cleaned);
      } else if (section == 'note') {
        noteLines.add(cleaned);
      }
    }

    if (ingredients.isEmpty && steps.isEmpty) {
      _parseCompactRecipe(content, ingredients, steps);
    }

    return _ParsedRecipe(
      ingredients: ingredients,
      steps: steps,
      note: noteLines.join(' '),
    );
  }

  static bool _matchesHeading(String lower, List<String> keywords) {
    return keywords.any((keyword) => lower.contains(keyword));
  }

  static String _cleanItem(String value) {
    return value
        .replaceAll('**', '')
        .replaceFirst(RegExp(r'^[-*•]\s*'), '')
        .replaceFirst(RegExp(r'^\d+[\.)]\s*'), '')
        .trim();
  }

  static List<String> _splitIngredientPayload(String value) {
    return value
        .split(RegExp(r',|\band\b', caseSensitive: false))
        .map(_cleanItem)
        .where((item) => item.length > 2)
        .take(8)
        .toList();
  }

  static void _parseCompactRecipe(
    String content,
    List<String> ingredients,
    List<String> steps,
  ) {
    final sentences =
        content
            .replaceAll('\n', ' ')
            .split(RegExp(r'[.!?]\s*'))
            .map(_cleanItem)
            .where((sentence) => sentence.length > 3)
            .toList();

    for (final sentence in sentences.take(5)) {
      final lower = sentence.toLowerCase();
      if (lower.startsWith('combine ') || lower.startsWith('mix ')) {
        final ingredientText =
            sentence
                .replaceFirst(
                  RegExp(r'^(combine|mix)\s+', caseSensitive: false),
                  '',
                )
                .trim();
        ingredients.addAll(_splitIngredientPayload(ingredientText));
        steps.add(sentence);
      } else if (lower.contains('cook') ||
          lower.contains('bake') ||
          lower.contains('simmer') ||
          lower.contains('serve')) {
        steps.add(sentence);
      }
    }

    if (steps.isEmpty && sentences.isNotEmpty) {
      steps.addAll(sentences.take(3));
    }
  }
}

class _RecipeSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _RecipeSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: context.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _IngredientWrap extends StatelessWidget {
  final List<String> ingredients;

  const _IngredientWrap({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          ingredients
              .map(
                (ingredient) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.cardBorderColor),
                  ),
                  child: Text(
                    ingredient,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _RecipeSteps extends StatelessWidget {
  final List<String> steps;

  const _RecipeSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "${i + 1}",
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    steps[i],
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textPrimaryColor,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (i != steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecipeNote extends StatelessWidget {
  final String note;

  const _RecipeNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.leaf, size: 17, color: AppColors.success),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              note,
              style: AppTypography.bodySmall.copyWith(
                color: context.textPrimaryColor,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachMacroEstimate extends StatelessWidget {
  final Map<String, int> macros;

  const _CoachMacroEstimate({required this.macros});

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.flame, "${macros['calories'] ?? 0}", "kcal"),
      (LucideIcons.dumbbell, "${macros['protein'] ?? 0}g", "protein"),
      (LucideIcons.wheat, "${macros['carbs'] ?? 0}g", "carbs"),
      (LucideIcons.droplet, "${macros['fat'] ?? 0}g", "fat"),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.primaryColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.$1, size: 14, color: context.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        item.$2,
                        style: AppTypography.labelLarge.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.$3,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.textMutedColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _CoachResponseActions extends StatelessWidget {
  const _CoachResponseActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      (LucideIcons.utensils, l10n.assistant_plan_meal),
      (LucideIcons.target, l10n.assistant_adjust_macros),
      (LucideIcons.messageCircle, l10n.assistant_ask_follow_up),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          actions
              .map(
                (action) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.cardBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.$1, size: 14, color: context.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        action.$2,
                        style: AppTypography.labelMedium.copyWith(
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  final Function(String) onSelect;
  const _RecommendationGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _QueryItem(
        label: l10n.assistant_starter_cal_desc,
        icon: LucideIcons.flame,
      ),
      _QueryItem(
        label: l10n.assistant_starter_meal_desc,
        icon: LucideIcons.utensils,
      ),
      _QueryItem(
        label: l10n.assistant_starter_plans_desc,
        icon: LucideIcons.clipboardList,
      ),
      _QueryItem(
        label: l10n.assistant_starter_tips_desc,
        icon: LucideIcons.lightbulb,
      ),
    ];

    return Column(
      children: [
        for (var item in items) ...[
          _QueryChip(
            label: item.label,
            icon: item.icon,
            onTap: () => onSelect(item.label),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _QueryItem {
  final String label;
  final IconData icon;
  _QueryItem({required this.label, required this.icon});
}

class _QueryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QueryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.cardBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: context.textMutedColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
