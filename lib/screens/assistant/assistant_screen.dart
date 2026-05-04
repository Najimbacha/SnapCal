import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/assistant_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/ui_blocks.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> with SingleTickerProviderStateMixin {
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

  void _fetchRecommendations({String? query, Uint8List? imageBytes, bool clearPrevious = false, bool forceFetch = false}) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.primary.withValues(alpha: 0.04),
                    colorScheme.surface,
                    AppColors.primary.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              _ChatAppBar(
                onRefresh: () => _fetchRecommendations(clearPrevious: true, forceFetch: true),
              ),
              
              Expanded(
                child: Consumer<AssistantProvider>(
                  builder: (context, assistant, _) {
                    final content = _buildChatContent(context, assistant);
                    
                    if (!settings.isPro) {
                      return Stack(
                        children: [
                          content,
                          Positioned.fill(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  color: context.backgroundColor.withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                                        ),
                                        child: const Icon(LucideIcons.crown, color: AppColors.primary, size: 48),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        "Unlock Your AI Coach",
                                        style: AppTypography.displaySmall.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 28,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        "Get 24/7 expert nutrition guidance, deep meal insights, and personalized coaching to reach your goals faster.",
                                        style: AppTypography.bodyLarge.copyWith(
                                          color: context.textSecondaryColor,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      AppScaleTap(
                                        onTap: () => context.push('/paywall'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.4),
                                                blurRadius: 20,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            "Upgrade to SnapCal Pro",
                                            style: AppTypography.titleMedium.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    return content;
                  },
                ),
              ),
              
              if (settings.isPro) _buildInputArea(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, AssistantProvider assistant) {
    if (assistant.error != null) {
      return Center(
        child: AppEmptyState(
          icon: LucideIcons.alertTriangle,
          title: AppLocalizations.of(context)!.assistant_title,
          body: assistant.error!,
          actionLabel: AppLocalizations.of(context)!.assistant_retry,
          onAction: _loadInitialRecommendations,
        ),
      );
    }

    if (assistant.history.isEmpty && assistant.isLoading) {
      return const Center(child: _ThinkingPulse());
    }

    if (assistant.history.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 48),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.assistant_initial_prompt,
                style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.assistant_initial_body,
                style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _RecommendationGrid(
                onSelect: (q) => _fetchRecommendations(query: q, clearPrevious: true),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: assistant.history.length,
      itemBuilder: (context, index) {
        return _ChatMessageTile(message: assistant.history[index]);
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.dividerColor.withValues(alpha: 0.1))),
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
                decoration: const InputDecoration(
                  hintText: "Ask about your nutrition...",
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
            onTap: () {
              final q = _searchController.text;
              if (q.trim().isNotEmpty) {
                _fetchRecommendations(query: q);
                _searchController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ChatAppBar({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Text(
              "AI Coach",
              style: AppTypography.heading3.copyWith(fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            AppScaleTap(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ),
          ],
        ),
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
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  p: AppTypography.bodyMedium.copyWith(color: isUser ? Colors.white : context.textPrimaryColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingPulse extends StatelessWidget {
  const _ThinkingPulse();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  final Function(String) onSelect;
  const _RecommendationGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final queries = [
      "Am I on track for my goal today?",
      "Suggest a protein-rich dinner",
      "Explain my macro balance",
      "How can I improve my streak?"
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: queries.map((q) => _QueryChip(label: q, onTap: () => onSelect(q))).toList(),
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
          border: Border.all(color: context.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
