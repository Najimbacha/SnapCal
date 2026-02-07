import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/glass_container.dart';

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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'AI Assistant',
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.backgroundColor.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed:
                () => context.read<AssistantProvider>().fetchRecommendations(
                  currentCalories:
                      context.read<MealProvider>().todaysTotalCalories,
                  targetCalories:
                      context.read<SettingsProvider>().dailyCalorieGoal,
                  currentMacros: {
                    'protein':
                        context.read<MealProvider>().todaysTotalMacros.protein,
                    'carbs':
                        context.read<MealProvider>().todaysTotalMacros.carbs,
                    'fat': context.read<MealProvider>().todaysTotalMacros.fat,
                  },
                  targetMacros: {
                    'protein':
                        context.read<SettingsProvider>().dailyProteinGoal,
                    'carbs': context.read<SettingsProvider>().dailyCarbGoal,
                    'fat': context.read<SettingsProvider>().dailyFatGoal,
                  },
                  clearPrevious: true,
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Subtle background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    context.backgroundColor,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Consumer<AssistantProvider>(
                  builder: (context, assistant, child) {
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
                              Text(
                                assistant.error!,
                                textAlign: TextAlign.center,
                              ),
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

                    // Scroll to bottom when new messages arrive
                    if (assistant.history.isNotEmpty) {
                      _scrollToBottom();
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.of(context).padding.top + 80,
                        20,
                        100, // Extra padding for docked input
                      ),
                      itemCount:
                          assistant.history.length +
                          (assistant.isLoading ? 1 : 0) +
                          1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildWelcomeHeader()
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: 0.2, end: 0);
                        }

                        final dataIndex = index - 1;
                        if (dataIndex < assistant.history.length) {
                          final item = assistant.history[dataIndex];
                          if (item is Map && item['type'] == 'user') {
                            return _buildUserMessage(item['content'])
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(begin: 0.2, end: 0);
                          }
                          return _buildRecommendationCard(item)
                              .animate()
                              .fadeIn(
                                duration: 500.ms,
                                delay: (dataIndex * 50).ms,
                              )
                              .slideY(begin: 0.1, end: 0);
                        } else {
                          return _buildLoadingIndicator().animate().fadeIn();
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          _buildSearchInput(),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String content) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF5E5CE6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          content,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'SnapCal is thinking...',
            style: AppTypography.bodyMedium.copyWith(
              color: context.textMutedColor,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6B4DFF)],
              ).createShader(bounds),
          child: Text(
            'How can I help you today?',
            style: AppTypography.heading3.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ask for recipes based on your macros or get coaching tips to stay on track.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.textSecondaryColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GlassContainer(
        borderRadius: 0,
        blur: 20,
        backgroundColor: context.surfaceColor.withOpacity(0.8),
        borderColor: context.glassBorderColor.withOpacity(0.5),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textPrimaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask your personal nutritionist...',
                    hintStyle: AppTypography.bodySmall.copyWith(
                      color: context.textMutedColor,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSearch,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF6B4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic item) {
    final isRecipe = item.type == 'recipe';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        backgroundColor: context.surfaceColor.withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isRecipe ? AppColors.primary : Colors.orange)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRecipe ? LucideIcons.utensils : LucideIcons.lightbulb,
                    color: isRecipe ? AppColors.primary : Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.content,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textPrimaryColor.withOpacity(0.9),
                height: 1.6,
              ),
            ),
            if (isRecipe && item.macros != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.backgroundColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.glassBorderColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroSmall(
                      'Calories',
                      '${item.macros['calories']} kcal',
                    ),
                    _buildMacroSmall('Protein', '${item.macros['protein']}g'),
                    _buildMacroSmall('Carbs', '${item.macros['carbs']}g'),
                    _buildMacroSmall('Fat', '${item.macros['fat']}g'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSmall(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: context.textMutedColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
