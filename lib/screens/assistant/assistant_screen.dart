import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_page_scaffold.dart';
import '../../widgets/ui_blocks.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialRecommendations();
  }

  @override
  void dispose() {
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

  void _fetchRecommendations({String? query, bool clearPrevious = false}) {
    final mealProvider = context.read<MealProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    context.read<AssistantProvider>().fetchRecommendations(
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
      userQuery: query,
      clearPrevious: clearPrevious,
    );
  }

  void _handleSearch() {
    if (_searchController.text.trim().isEmpty) return;
    if (!context.read<ConnectivityService>().isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assistant needs connection.'),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    _fetchRecommendations(query: _searchController.text.trim());
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppPageScaffold(
      title: 'AI Coach',
      subtitle: 'Personalized guidance for your fitness goals.',
      trailing: IconButton.filledTonal(
        icon: const Icon(LucideIcons.refreshCw),
        onPressed: () => _fetchRecommendations(clearPrevious: true),
      ),
      bottomBar: BottomActionBar(
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  enabled: context.watch<ConnectivityService>().isOnline,
                  decoration: InputDecoration(
                    hintText: 'Ask anything...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              IconButton.filled(
                onPressed: _handleSearch,
                icon: const Icon(LucideIcons.send, size: 20),
              ),
            ],
          ),
        ),
      ),
      child: Consumer<AssistantProvider>(
        builder: (context, assistant, _) {
          if (assistant.error != null) {
            return Center(
              child: AppEmptyState(
                icon: LucideIcons.alertTriangle,
                title: 'Coach unavailable',
                body: assistant.error!,
                actionLabel: 'Retry',
                onAction: _loadInitialRecommendations,
              ),
            );
          }

          if (assistant.history.isEmpty && assistant.isLoading) {
            return const Center(
              child: AppEmptyState(
                icon: LucideIcons.sparkles,
                title: 'Thinking...',
                body: 'Preparing your personalized suggestions.',
              ),
            );
          }

          if (assistant.history.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: LucideIcons.messageCircle,
                title: 'Start chatting',
                body: 'Ask for meal ideas, plans, or general guidance.',
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: assistant.history.length + (assistant.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= assistant.history.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppSectionCard(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Developing suggestions...',
                          style: AppTypography.labelMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final item = assistant.history[index];
              final isUser = item is Map && item['type'] == 'user';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                    ),
                    child: AppSectionCard(
                      padding: const EdgeInsets.all(20),
                      color: isUser 
                        ? colorScheme.primaryContainer 
                        : colorScheme.surfaceContainerLow,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            Row(
                              children: [
                                Icon(
                                  item.type == 'recipe' ? LucideIcons.utensils : LucideIcons.sparkles,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            isUser ? (item['content'] as String) : (item.content as String),
                            style: AppTypography.bodyLarge.copyWith(
                              color: isUser 
                                ? colorScheme.onPrimaryContainer 
                                : colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
