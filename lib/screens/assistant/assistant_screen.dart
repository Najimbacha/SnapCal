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

const _minimalGreen = Color(0xFF1A3D2B);

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
    if (!mounted || !_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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
      if (!mounted) return;
      if (!context.read<ConnectivityService>().isOnline) {
        showFriendlyFallbackSnack(
          context,
          AppLocalizations.of(context)?.common_offline_mode ??
              "Offline Mode: Check your internet connection",
          icon: LucideIcons.wifiOff,
        );
        return;
      }
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
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14130F)
                : const Color(0xFFF9F8F5),
        leading: const _CoachBackButton(),
        trailing: _CoachHeaderActions(
          isPro: isPro,
          onNewChat:
              () =>
                  _fetchRecommendations(clearPrevious: true, forceFetch: true),
          onOpenProfile: () => _showCoachProfileBottomSheet(context),
          onOpenReport: () => _showWeeklyReportDialog(context),
        ),
        bottomBar: _buildInputArea(context, isPro),
        child: Consumer<AssistantProvider>(
          builder: (context, assistant, _) {
            final hasReachedLimit = PremiumGateService().hasReachedAiLimit(
              isPro,
            );
            final showLockedPreview =
                !isPro && assistant.history.isEmpty && hasReachedLimit;

            if (showLockedPreview) {
              return const _LockedCoachPreview();
            }

            final chatContent = _buildChatContent(context, assistant);
            final mainLayout = Column(
              children: [
                const _CoachMetricsHeader(),
                Expanded(child: chatContent),
              ],
            );

            if (!isPro && hasReachedLimit) {
              return Stack(
                children: [
                  mainLayout,
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
            return mainLayout;
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
      if (!context.read<ConnectivityService>().isOnline) {
        showFriendlyFallbackSnack(
          context,
          l10n.common_offline_mode,
          icon: LucideIcons.wifiOff,
        );
        return;
      }
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
              color: isDark ? const Color(0xFF0D2517) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color:
                    isDark
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
                        : const Color(0xFFEFEBE4),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
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
                      color:
                          isDark
                              ? const Color(0xFF143324)
                              : const Color(0xFFFCF8EF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark
                                ? const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.25)
                                : const Color(0xFFFAF2E6),
                      ),
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      color:
                          isDark
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFFBA7517),
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
                    cursorColor:
                        isDark
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFFBA7517),
                    style: AppTypography.bodyMedium.copyWith(
                      color:
                          isDark
                              ? const Color(0xFFFAF8F5)
                              : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.assistant_input_hint,
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color:
                            isDark
                                ? const Color(0xFFBDD2C6)
                                : const Color(0xFF788C80),
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
                      gradient: LinearGradient(
                        colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.arrowUp,
                      color:
                          isDark
                              ? const Color(0xFF0A2114)
                              : const Color(0xFF1A3D2B),
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
    final targetCalories =
        settings.dailyCalorieGoal > 0 ? settings.dailyCalorieGoal : 2000;
    final caloriesLeft = (targetCalories - calories).clamp(0, 99999).toInt();
    final proteinGap =
        (settings.dailyProteinGoal - mealProvider.todaysTotalMacros.protein)
            .clamp(0, 999)
            .toInt();
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

    final coachMessage = _calculateCoachMessage(
      context: context,
      calories: calories,
      targetCalories: targetCalories,
      protein: mealProvider.todaysTotalMacros.protein,
      targetProtein:
          settings.dailyProteinGoal > 0 ? settings.dailyProteinGoal : 120,
      carbs: mealProvider.todaysTotalMacros.carbs,
      targetCarbs: settings.dailyCarbGoal > 0 ? settings.dailyCarbGoal : 220,
      fat: mealProvider.todaysTotalMacros.fat,
      targetFat: settings.dailyFatGoal > 0 ? settings.dailyFatGoal : 65,
      languageCode: settings.languageCode,
      mealCount: meals.length,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    final Color cardBg =
        isDark ? const Color(0xFF0F2618) : const Color(0xFFFCF8EF);
    final Color borderColor =
        isDark
            ? goldColor.withValues(alpha: 0.25)
            : const Color(0xFFE5C060).withValues(alpha: 0.3);
    final Color textColor =
        isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A3D2B);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Title Row
              Row(
                children: [
                  Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          color: Color(0xFF0A2114),
                          size: 20,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        duration: 1800.ms,
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1.04, 1.04),
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AI Recommendations",
                          style: AppTypography.titleLarge.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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

              // Prominent Coach's Insight Bubble / Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.05,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          color: goldColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "TODAY'S FOCUS & ADVICE",
                          style: AppTypography.labelSmall.copyWith(
                            color:
                                isDark
                                    ? const Color(0xFFE5C060)
                                    : const Color(0xFFBA7517),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coachMessage,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Side-by-side Capsules for Last Meal & Next Move
              Row(
                children: [
                  Expanded(
                    child: _CoachCapsuleTile(
                      icon: LucideIcons.utensils,
                      label: l10n.assistant_last_meal,
                      value: lastMeal,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CoachCapsuleTile(
                      icon: LucideIcons.target,
                      label: "Next Move",
                      value: action,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recommended inquiries section header
              Text(
                "Recommended Queries",
                style: AppTypography.titleMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),

              // Recommended Queries Stack (replaces the chips and old grid)
              _RecommendedCard(
                icon: LucideIcons.utensils,
                title: "Plan My Next Meal",
                subtitle:
                    "Get healthy meal ideas tailored to your calorie budget",
                onTap: () => onSelect("Suggest next meal based on target"),
              ),
              const SizedBox(height: 12),
              _RecommendedCard(
                icon: LucideIcons.target,
                title: "Optimize My Macros",
                subtitle:
                    "Get tips on how to hit your protein, carbs, and fat target",
                onTap: () => onSelect("What are my macro targets?"),
              ),
              const SizedBox(height: 12),
              _RecommendedCard(
                icon: LucideIcons.lightbulb,
                title: "Daily Nutrition Tips",
                subtitle:
                    "Learn quick dietary tricks based on your profile & goals",
                onTap: () => onSelect("Tell me some quick nutrition tips"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachCapsuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _CoachCapsuleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4AF37);
    final Color chipBg =
        isDark ? const Color(0xFF112A1C) : const Color(0xFFF2FDF4);
    final Color iconColor = isDark ? goldColor : const Color(0xFF1E4620);
    final Color labelColor =
        isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80);
    final Color valueColor =
        isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A1A2E);
    final Color borderColor =
        isDark ? goldColor.withValues(alpha: 0.15) : const Color(0xFFD4ECD8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    final Color cardBg = context.cardColor;
    final Color borderColor = context.cardBorderColor;

    return AppScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.2),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? goldColor : context.primaryColor,
                size: 20,
              ),
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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 11,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
              color: _minimalGreen,
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
                              color: _minimalGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _minimalGreen.withValues(alpha: 0.3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

    if (isUser) {
      final LinearGradient userGrad;
      final Color userTextColor;

      if (isDark) {
        userGrad = const LinearGradient(
          colors: [
            Color(0xFFE5C060), // Light Gold
            Color(0xFFB88E2F), // Dark Gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        userTextColor = const Color(0xFF0A2013);
      } else {
        userGrad = const LinearGradient(
          colors: [
            Color(0xFFFCF8EF), // Warm champagne
            Color(0xFFF5EAD2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        userTextColor = const Color(0xFF1A3D2B); // Forest green text
      }

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
                  gradient: userGrad,
                  borderRadius: BorderRadius.circular(
                    22,
                  ).copyWith(bottomRight: const Radius.circular(6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFFD4AF37,
                      ).withValues(alpha: isDark ? 0.15 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.bodyMedium.copyWith(
                      color: userTextColor,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
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

    const goldColor = Color(0xFFD4AF37);

    final Color bubbleBg;
    final Color borderColor;
    final Color sparklesBg;
    final Color sparklesColor;
    final Color titleColor;
    final Color subtitleColor;
    final Color textColor;
    final Color boldTextColor;
    final Color bulletColor;
    final List<BoxShadow> shadow;

    if (isDark) {
      bubbleBg = const Color(0xFF0B2114);
      borderColor = goldColor.withValues(alpha: 0.35);
      sparklesBg = const Color(0xFF143324);
      sparklesColor = goldColor;
      titleColor = const Color(0xFFFAF8F5);
      subtitleColor = const Color(0xFFBDD2C6);
      textColor = const Color(0xFFFAF8F5);
      boldTextColor = const Color(0xFFE5C060);
      bulletColor = goldColor;
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ];
    } else {
      bubbleBg = Colors.white;
      borderColor = const Color(0xFFEFEBE4);
      sparklesBg = const Color(0xFFFCF8EF);
      sparklesColor = const Color(0xFFBA7517);
      titleColor = const Color(0xFF1A1A2E);
      subtitleColor = const Color(0xFF788C80);
      textColor = const Color(0xFF1A1A2E);
      boldTextColor = const Color(0xFFBA7517);
      bulletColor = const Color(0xFFBA7517);
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bubbleBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sparklesBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 16,
                    color: sparklesColor,
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
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        type == 'recipe'
                            ? l10n.assistant_recipe_estimated_macros
                            : l10n.assistant_personalized_from_today,
                        style: AppTypography.labelSmall.copyWith(
                          color: subtitleColor,
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
                  color: textColor,
                  height: 1.48,
                ),
                strong: AppTypography.bodyMedium.copyWith(
                  color: boldTextColor,
                  fontWeight: FontWeight.w900,
                ),
                listBullet: AppTypography.bodyMedium.copyWith(
                  color: bulletColor,
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
    final parsed = _ParsedRecipe.fromMarkdown(content);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    final Color cardBg;
    final Color borderColor;
    final List<BoxShadow> shadow;
    final LinearGradient headerGrad;
    final Color chefHatBg;
    final Color chefHatColor;
    final Color titleColor;
    final Color subtitleColor;
    final Color badgeBg;
    final Color badgeText;
    final Color badgeBorder;

    final Color textBodyColor;
    final Color bulletBodyColor;

    if (isDark) {
      cardBg = const Color(0xFF0B2114);
      borderColor = goldColor.withValues(alpha: 0.35);
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
      headerGrad = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF143020), Color(0xFF0B2114)],
      );
      chefHatBg = const Color(0xFF1C462E);
      chefHatColor = goldColor;
      titleColor = const Color(0xFFFAF8F5);
      subtitleColor = const Color(0xFFBDD2C6);
      badgeBg = const Color(0xFF143020);
      badgeText = goldColor;
      badgeBorder = goldColor.withValues(alpha: 0.35);
      textBodyColor = const Color(0xFFFAF8F5);
      bulletBodyColor = goldColor;
    } else {
      cardBg = Colors.white;
      borderColor = const Color(0xFFEFEBE4);
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
      headerGrad = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFCF8EF), Color(0xFFFAF2E6)],
      );
      chefHatBg = const Color(0xFFFCF8EF);
      chefHatColor = const Color(0xFFBA7517);
      titleColor = const Color(0xFF1A1A2E);
      subtitleColor = const Color(0xFF788C80);
      badgeBg = const Color(0xFFFCF8EF);
      badgeText = const Color(0xFFBA7517);
      badgeBorder = const Color(0xFFE5C060).withValues(alpha: 0.5);
      textBodyColor = const Color(0xFF1A1A2E);
      bulletBodyColor = const Color(0xFFBA7517);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(gradient: headerGrad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: chefHatBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.chefHat,
                            color: chefHatColor,
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
                                  color: titleColor,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.assistant_step_recipe_plan,
                                style: AppTypography.labelMedium.copyWith(
                                  color: subtitleColor,
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
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: badgeBorder),
                          ),
                          child: Text(
                            "RECIPE",
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
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
                              color: textBodyColor,
                              height: 1.48,
                            ),
                            listBullet: AppTypography.bodyMedium.copyWith(
                              color: bulletBodyColor,
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
                  color: _minimalGreen,
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

// ── CUSTOM WIDGETS AND DIALOGS FOR AI COACH ──

class _CoachHeaderActions extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenReport;
  final bool isPro;

  const _CoachHeaderActions({
    required this.onNewChat,
    required this.onOpenProfile,
    required this.onOpenReport,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderActionButton(
          icon: LucideIcons.barChart3,
          tooltip: "Weekly Report",
          onTap: onOpenReport,
          showProBadge: !isPro,
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          icon: LucideIcons.user,
          tooltip: "Coach Profile",
          onTap: onOpenProfile,
        ),
        const SizedBox(width: 8),
        _HeaderActionButton(
          icon: Icons.add_rounded,
          tooltip: "New Chat",
          onTap: onNewChat,
          iconColor: context.primaryColor,
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showProBadge;
  final Color? iconColor;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showProBadge = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColorResolved =
        iconColor ??
        (isDark ? const Color(0xFFE5C060) : const Color(0xFFBA7517));

    return Tooltip(
      message: tooltip,
      child: AppScaleTap(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.cardBorderColor),
              ),
              child: Icon(icon, size: 18, color: iconColorResolved),
            ),
            if (showProBadge)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.lock,
                    size: 8,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoachMetricsHeader extends StatelessWidget {
  const _CoachMetricsHeader();

  @override
  Widget build(BuildContext context) {
    final mealProvider = context.watch<MealProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final calories = mealProvider.todaysTotalCalories;
    final targetCalories =
        settingsProvider.dailyCalorieGoal > 0
            ? settingsProvider.dailyCalorieGoal
            : 2000;
    final remaining = (targetCalories - calories).clamp(0, 9999).toInt();

    final protein = mealProvider.todaysTotalMacros.protein;
    final targetProtein =
        settingsProvider.dailyProteinGoal > 0
            ? settingsProvider.dailyProteinGoal
            : 120;

    final carbs = mealProvider.todaysTotalMacros.carbs;
    final targetCarbs =
        settingsProvider.dailyCarbGoal > 0
            ? settingsProvider.dailyCarbGoal
            : 220;

    final fat = mealProvider.todaysTotalMacros.fat;
    final targetFat =
        settingsProvider.dailyFatGoal > 0 ? settingsProvider.dailyFatGoal : 65;

    final calorieProgress = (calories / targetCalories).clamp(0.0, 1.0);

    final Color cardBg =
        isDark ? const Color(0xFF0F2618) : const Color(0xFFFCF8EF);
    final Color borderColor =
        isDark
            ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
            : const Color(0xFFE5C060).withValues(alpha: 0.2);
    final Color textColor =
        isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A3D2B);
    final Color secondaryTextColor =
        isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80);
    final Color progressVal =
        isDark ? const Color(0xFFE5C060) : const Color(0xFFBA7517);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.flame, size: 16, color: progressVal),
                  const SizedBox(width: 6),
                  Text(
                    "Calories",
                    style: AppTypography.titleSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Text(
                "$calories / $targetCalories kcal ($remaining left)",
                style: AppTypography.labelSmall.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: calorieProgress,
              minHeight: 6,
              backgroundColor:
                  isDark ? const Color(0xFF183D26) : const Color(0xFFEFEBE4),
              valueColor: AlwaysStoppedAnimation<Color>(progressVal),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MacroProgressItem(
                  label: "Protein",
                  value: protein,
                  target: targetProtein,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: "Carbs",
                  value: carbs,
                  target: targetCarbs,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroProgressItem(
                  label: "Fat",
                  value: fat,
                  target: targetFat,
                  color: const Color(0xFFEAB308),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _calculateCoachMessage({
  required BuildContext context,
  required int calories,
  required int targetCalories,
  required int protein,
  required int targetProtein,
  required int carbs,
  required int targetCarbs,
  required int fat,
  required int targetFat,
  required String languageCode,
  required int mealCount,
}) {
  if (mealCount == 0) {
    if (languageCode == 'ar') {
      return "لم تقم بتسجيل أي وجبات اليوم بعد! فلنبدأ بوجبة فطور صحية أو وجبة سريعة.";
    } else if (languageCode == 'es') {
      return "¡Aún no has registrado ninguna comida hoy! Empecemos con un desayuno saludable o una comida rápida.";
    } else if (languageCode == 'fr') {
      return "Vous n'avez pas encore enregistré de repas aujourd'hui! Commençons par un petit-déjeuner sain ou un repas rapide.";
    } else {
      return "You haven't logged any meals today yet! Let's start with a healthy breakfast or quick meal.";
    }
  } else if (calories > targetCalories) {
    if (languageCode == 'ar') {
      return "السعرات الحرارية تتجاوز هدفك اليومي. حاول التركيز على وجبات خفيفة أو أطعمة منخفضة السعرات.";
    } else if (languageCode == 'es') {
      return "Las calorías superan tu objetivo diario. Intenta concentrarte en comidas siguientes más ligeras o bocadillos bajos en calorías.";
    } else if (languageCode == 'fr') {
      return "Les calories dépassent votre objectif quotidien. Essayez de vous concentrer sur des repas suivants plus légers ou des collations peu caloriques.";
    } else {
      return "Calories are above your daily target. Try to focus on lighter next meals or low-calorie snacks.";
    }
  } else if (calories >= targetCalories * 0.85 &&
      calories <= targetCalories * 1.05) {
    if (languageCode == 'ar') {
      return "أنت على المسار الصحيح تمامًا وقريب من هدف السعرات الحرارية اليومي! استمر في هذا الأداء المتناسق.";
    } else if (languageCode == 'es') {
      return "¡Vas por buen camino y cerca de tu objetivo diario de calorías! Sigue así con el trabajo constante.";
    } else if (languageCode == 'fr') {
      return "Vous êtes sur la bonne voie et proche de votre objectif calorique quotidien! Continuez votre excellent travail.";
    } else {
      return "You are right on track and near your daily calorie target! Keep up the consistent work.";
    }
  } else if (protein < targetProtein * 0.5) {
    if (languageCode == 'ar') {
      return "كمية البروتين التي تناولتها منخفضة اليوم. فكر في إضافة أطعمة غنية بالبروتين مثل صدر الدجاج، البيض، أو التوفو إلى وجبتك التالية.";
    } else if (languageCode == 'es') {
      return "Tu consumo de proteínas es bajo hoy. Considera agregar alimentos ricos en proteínas como pechuga de pollo, huevos o tofu en tu próxima comida.";
    } else if (languageCode == 'fr') {
      return "Votre apport en protéines est faible aujourd'hui. Pensez à ajouter des aliments riches en protéines comme du blanc de poulet, des œufs ou du tofu à votre prochain repas.";
    } else {
      return "Your protein intake is low today. Consider adding high-protein foods like chicken breast, eggs, or tofu to your next meal.";
    }
  } else if (carbs > targetCarbs * 0.85) {
    if (languageCode == 'ar') {
      return "الكربوهيدرات مرتفعة قليلاً. عادل وجبتك القادمة بالدهون الصحية، البروتين الخالي من الدهون، والألياف.";
    } else if (languageCode == 'es') {
      return "Los carbohidratos están un poco altos. Equilibra tu próxima comida con grasas saludables, proteínas magras y fibra.";
    } else if (languageCode == 'fr') {
      return "Les glucides sont un peu élevés. Équilibrez votre prochain repas avec des graisses saines, des protéines magras et des fibres.";
    } else {
      return "Carbohydrates are running a bit high. Balance your next meal with healthy fats, lean protein, and fiber.";
    }
  } else {
    if (languageCode == 'ar') {
      return "استمر في تتبع وجباتك وحافظ على استمراريتك للوصول إلى هدف وزنك!";
    } else if (languageCode == 'es') {
      return "¡Sigue registrando tus comidas y mantente constante para lograr tu peso objetivo!";
    } else if (languageCode == 'fr') {
      return "Continuez à suivre vos repas et restez régulier pour atteindre votre objectif de poids!";
    } else {
      return "Keep tracking your meals and stay consistent to reach your weight goal!";
    }
  }
}

class _MacroProgressItem extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;

  const _MacroProgressItem({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
            Text(
              "$value/${target}g",
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A3D2B),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor:
                isDark ? const Color(0xFF183D26) : const Color(0xFFEFEBE4),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

void _showCoachProfileBottomSheet(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final ageController = TextEditingController(
    text: settings.age?.toString() ?? '',
  );
  final heightController = TextEditingController(
    text: settings.height?.toString() ?? '',
  );
  final weightController = TextEditingController(
    text: settings.startingWeight?.toString() ?? '',
  );
  final targetWeightController = TextEditingController(
    text: settings.targetWeight?.toString() ?? '',
  );
  final foodDislikesController = TextEditingController(
    text: settings.foodDislikes ?? '',
  );
  final medicalNotesController = TextEditingController(
    text: settings.medicalNotes ?? '',
  );

  String selectedGender = settings.gender ?? 'other';
  String selectedGoalMode = settings.goalMode;
  String selectedActivityLevel = settings.activityLevel ?? 'moderatelyActive';
  String selectedDietPreference = settings.dietaryRestriction;

  // Dynanically safeguard dropdown options to prevent any crash if the DB state contains an unexpected/unlisted value
  final List<String> genderOptions = ['male', 'female', 'other'];
  if (!genderOptions.contains(selectedGender)) {
    genderOptions.add(selectedGender);
  }

  final List<String> goalModeOptions = ['lose', 'gain', 'maintain'];
  if (!goalModeOptions.contains(selectedGoalMode)) {
    goalModeOptions.add(selectedGoalMode);
  }

  final List<String> activityOptions = [
    'sedentary',
    'lightlyActive',
    'moderatelyActive',
    'veryActive',
  ];
  if (!activityOptions.contains(selectedActivityLevel)) {
    activityOptions.add(selectedActivityLevel);
  }

  final List<String> dietOptions = [
    'none',
    'vegetarian',
    'vegan',
    'gluten-free',
    'keto',
    'halal',
  ];
  if (!dietOptions.contains(selectedDietPreference)) {
    dietOptions.add(selectedDietPreference);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14130F) : const Color(0xFFF9F8F5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color:
                    isDark
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                        : const Color(0xFFE5C060).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.user,
                        color:
                            isDark
                                ? const Color(0xFFE5C060)
                                : const Color(0xFFBA7517),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Coach Profile Setup",
                        style: AppTypography.titleLarge.copyWith(
                          color:
                              isDark
                                  ? const Color(0xFFFAF8F5)
                                  : const Color(0xFF1A3D2B),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "Age (years)",
                          controller: ageController,
                          keyboardType: TextInputType.number,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: "Gender",
                          value: selectedGender,
                          items:
                              genderOptions.map((opt) {
                                String label = opt;
                                switch (opt) {
                                  case 'male':
                                    label = "Male";
                                    break;
                                  case 'female':
                                    label = "Female";
                                    break;
                                  case 'other':
                                    label = "Other";
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(label),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedGender = val);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "Height (cm)",
                          controller: heightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFormField(
                          label: "Current Weight (kg)",
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: "Goal Weight (kg)",
                          controller: targetWeightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: "Goal Mode",
                          value: selectedGoalMode,
                          items:
                              goalModeOptions.map((opt) {
                                String label = opt;
                                switch (opt) {
                                  case 'lose':
                                    label = "Lose Weight";
                                    break;
                                  case 'gain':
                                    label = "Gain Weight";
                                    break;
                                  case 'maintain':
                                    label = "Maintain";
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(label),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedGoalMode = val);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: "Activity Level",
                          value: selectedActivityLevel,
                          items:
                              activityOptions.map((opt) {
                                String label = opt;
                                switch (opt) {
                                  case 'sedentary':
                                    label = "Sedentary";
                                    break;
                                  case 'lightlyActive':
                                    label = "Lightly Active";
                                    break;
                                  case 'moderatelyActive':
                                    label = "Moderately Active";
                                    break;
                                  case 'veryActive':
                                    label = "Very Active";
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(label),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedActivityLevel = val);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField<String>(
                          label: "Diet Preference",
                          value: selectedDietPreference,
                          items:
                              dietOptions.map((opt) {
                                String label = opt;
                                switch (opt) {
                                  case 'none':
                                    label = "None";
                                    break;
                                  case 'vegetarian':
                                    label = "Vegetarian";
                                    break;
                                  case 'vegan':
                                    label = "Vegan";
                                    break;
                                  case 'gluten-free':
                                    label = "Gluten Free";
                                    break;
                                  case 'keto':
                                    label = "Keto";
                                    break;
                                  case 'halal':
                                    label = "Halal";
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: opt,
                                  child: Text(label),
                                );
                              }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => selectedDietPreference = val);
                            }
                          },
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildFormField(
                    label:
                        "Food Dislikes (comma separated, e.g. peanuts, dairy)",
                    controller: foodDislikesController,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFormField(
                    label: "Medical Notes / Allergies / Conditions (optional)",
                    controller: medicalNotesController,
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "Cancel",
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final int? age = int.tryParse(ageController.text);
                              final double? height = double.tryParse(
                                heightController.text,
                              );
                              final double? weight = double.tryParse(
                                weightController.text,
                              );
                              final double? targetWeight = double.tryParse(
                                targetWeightController.text,
                              );

                              await settings.updateCoachProfile(
                                age: age,
                                height: height,
                                startingWeight: weight,
                                targetWeight: targetWeight,
                                gender: selectedGender,
                                goalMode: selectedGoalMode,
                                activityLevel: selectedActivityLevel,
                                dietaryRestriction:
                                    selectedDietPreference == 'none'
                                        ? null
                                        : selectedDietPreference,
                                foodDislikes:
                                    foodDislikesController.text.trim().isEmpty
                                        ? null
                                        : foodDislikesController.text.trim(),
                                medicalNotes:
                                    medicalNotesController.text.trim().isEmpty
                                        ? null
                                        : medicalNotesController.text.trim(),
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Coach profile updated successfully!",
                                    ),
                                    backgroundColor:
                                        isDark
                                            ? const Color(0xFF143324)
                                            : const Color(0xFF1A3D2B),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              "Save Profile",
                              style: AppTypography.titleMedium.copyWith(
                                color: const Color(0xFF0A2114),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildFormField({
  required String label,
  required TextEditingController controller,
  TextInputType? keyboardType,
  required bool isDark,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80),
        ),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF1C221D) : const Color(0xFFF1EDE4),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}

Widget _buildDropdownField<T>({
  required String label,
  required T? value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  required bool isDark,
}) {
  final seenValues = <T?>{};
  final dedupedItems =
      items.where((item) => seenValues.add(item.value)).toList();
  final safeValue =
      dedupedItems.any((item) => item.value == value) ? value : null;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80),
        ),
      ),
      const SizedBox(height: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C221D) : const Color(0xFFF1EDE4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: safeValue,
            items: dedupedItems,
            onChanged: onChanged,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? const Color(0xFFD4AF37) : const Color(0xFFBA7517),
            ),
            dropdownColor:
                isDark ? const Color(0xFF14130F) : const Color(0xFFF9F8F5),
            isExpanded: true,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    ],
  );
}

void _showWeeklyReportDialog(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  final mealProvider = context.read<MealProvider>();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (!settings.isPro) {
    PremiumConversionService().openPaywall(
      context,
      PaywallEntryPoint.reportInsight,
      featureName: 'weekly_report',
    );
    return;
  }

  final avgCalories = mealProvider.getWeeklyAverageCalories();
  final weeklyMacros = mealProvider.getWeeklyMacroSummary();
  final avgProtein = (weeklyMacros.protein / 7.0).round();

  final trend = mealProvider.getWeeklyCalorieTrend();
  final calorieGoal =
      settings.dailyCalorieGoal > 0 ? settings.dailyCalorieGoal : 2000;
  final today = DateTime.now();

  double closestDiff = double.infinity;
  int bestDayIndex = -1;
  for (int i = 0; i < trend.length; i++) {
    final calories = trend[i];
    if (calories <= 0) continue;
    final diff = (calories - calorieGoal).abs();
    if (diff < closestDiff) {
      closestDiff = diff.toDouble();
      bestDayIndex = i;
    }
  }

  String bestDayStr;
  if (bestDayIndex != -1) {
    final bestDate = today.subtract(Duration(days: 6 - bestDayIndex));
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    bestDayStr = weekdays[bestDate.weekday - 1];
  } else {
    bestDayStr = 'No data logged';
  }

  final avgCarbs = (weeklyMacros.carbs / 7.0).round();
  final avgFat = (weeklyMacros.fat / 7.0).round();

  final targetProtein =
      settings.dailyProteinGoal > 0 ? settings.dailyProteinGoal : 120;
  final targetCarbs = settings.dailyCarbGoal > 0 ? settings.dailyCarbGoal : 220;
  final targetFat = settings.dailyFatGoal > 0 ? settings.dailyFatGoal : 65;

  final proteinRatio = avgProtein / targetProtein;
  final carbRatio = avgCarbs / targetCarbs;
  final fatRatio = avgFat / targetFat;

  String weakestArea = 'Protein Intake';
  double lowestRatio = proteinRatio;

  if (carbRatio < lowestRatio) {
    lowestRatio = carbRatio;
    weakestArea = 'Carbohydrates';
  }
  if (fatRatio < lowestRatio) {
    lowestRatio = fatRatio;
    weakestArea = 'Fat Balance';
  }

  if (lowestRatio >= 0.85) {
    weakestArea = 'Calorie consistency';
  }

  String nextWeekTarget = '';
  if (weakestArea == 'Protein Intake') {
    nextWeekTarget =
        'Hit ${targetProtein}g Protein daily (Add eggs, chicken, Greek yogurt)';
  } else if (weakestArea == 'Carbohydrates') {
    nextWeekTarget =
        'Focus on ${targetCarbs}g complex carbs (oats, brown rice, sweet potatoes)';
  } else if (weakestArea == 'Fat Balance') {
    nextWeekTarget =
        'Aim for ${targetFat}g healthy fats (avocado, nuts, olive oil)';
  } else {
    nextWeekTarget =
        'Maintain calorie target of $calorieGoal kcal (Keep tracking daily)';
  }

  final Color cardBg =
      isDark ? const Color(0xFF14130F) : const Color(0xFFF9F8F5);
  final Color titleColor =
      isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A3D2B);
  final Color goldAccent =
      isDark ? const Color(0xFFE5C060) : const Color(0xFFB88E2F);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color:
                  isDark
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
                      : const Color(0xFFE5C060).withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.barChart3,
                      color: goldAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Weekly Summary",
                          style: AppTypography.titleLarge.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "AI Coach Premium Report",
                          style: AppTypography.labelSmall.copyWith(
                            color: goldAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildReportRow(
                icon: LucideIcons.flame,
                label: "Average Daily Calories",
                value: "$avgCalories kcal",
                subValue: "Goal: $calorieGoal kcal",
                color: goldAccent,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildReportRow(
                icon: LucideIcons.dumbbell,
                label: "Average Daily Protein",
                value: "${avgProtein}g",
                subValue: "Goal: ${targetProtein}g",
                color: const Color(0xFF22C55E),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildReportRow(
                icon: LucideIcons.calendarCheck,
                label: "Best Performing Day",
                value: bestDayStr,
                subValue: "Closest to goals",
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildReportRow(
                icon: LucideIcons.alertTriangle,
                label: "Weakest Nutrition Area",
                value: weakestArea,
                subValue:
                    lowestRatio < 0.85 ? "Below target" : "Excellent control",
                color:
                    lowestRatio < 0.85
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: goldAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: goldAccent.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RECOMMENDED NEXT TARGET",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: goldAccent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextWeekTarget,
                      style: AppTypography.bodySmall.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Dismiss Report",
                    style: AppTypography.titleMedium.copyWith(
                      color: const Color(0xFF0A2114),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildReportRow({
  required IconData icon,
  required String label,
  required String value,
  required String subValue,
  required Color color,
  required bool isDark,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color:
                    isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subValue,
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? Colors.white30 : Colors.black38,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      Text(
        value,
        style: AppTypography.titleSmall.copyWith(
          color: isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A3D2B),
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
