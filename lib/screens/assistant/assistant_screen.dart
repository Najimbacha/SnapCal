import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialRecommendations();
  }

  void _loadInitialRecommendations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      );
    });
  }

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (_searchController.text.isEmpty) return;

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
      userQuery: _searchController.text,
    );
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _loadInitialRecommendations,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<AssistantProvider>(
              builder: (context, assistant, child) {
                if (assistant.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (assistant.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppColors.error,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(assistant.error!, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadInitialRecommendations,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildWelcomeHeader(),
                    const SizedBox(height: 24),
                    if (assistant.recommendations.isEmpty)
                      const Center(
                        child: Text('No recommendations yet. Ask me anything!'),
                      )
                    else
                      ...assistant.recommendations.map(
                        (item) => _buildRecommendationCard(item),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildSearchInput(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How can I help you today?', style: AppTypography.heading3),
        const SizedBox(height: 8),
        Text(
          'Ask for recipes based on your macros or get coaching tips to stay on track.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSearch(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSearch,
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

  Widget _buildRecommendationCard(dynamic item) {
    final isRecipe = item.type == 'recipe';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isRecipe ? AppColors.primary : Colors.orange)
                      .withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRecipe ? LucideIcons.utensils : LucideIcons.lightbulb,
                  color: isRecipe ? AppColors.primary : Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.title, style: AppTypography.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.content,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (isRecipe && item.macros != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMacroSmall('Cals', '${item.macros['calories']}'),
                _buildMacroSmall('Pro', '${item.macros['protein']}g'),
                _buildMacroSmall('Carb', '${item.macros['carbs']}g'),
                _buildMacroSmall('Fat', '${item.macros['fat']}g'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroSmall(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
