import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/wazn_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/meal.dart';
import '../../../data/models/quick_food.dart';
import '../../../data/quick_food_catalog.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/quick_food_provider.dart';

typedef AddCatalogFood = Future<Meal> Function(QuickFood food, double grams);
typedef RepeatLoggedMeal = Future<Meal> Function(Meal meal);
typedef UndoQuickMeal = Future<void> Function(String mealId);

enum _QuickFoodFilter { forYou, recent, local, favorites, all }

class QuickAddFoods extends ConsumerStatefulWidget {
  const QuickAddFoods({
    super.key,
    required this.meals,
    required this.mealType,
    required this.cuisinePreference,
    required this.onAddCatalogFood,
    required this.onRepeatMeal,
    required this.onUndo,
  });

  final List<Meal> meals;
  final String mealType;
  final String cuisinePreference;
  final AddCatalogFood onAddCatalogFood;
  final RepeatLoggedMeal onRepeatMeal;
  final UndoQuickMeal onUndo;

  @override
  ConsumerState<QuickAddFoods> createState() => _QuickAddFoodsState();
}

class _QuickAddFoodsState extends ConsumerState<QuickAddFoods> {
  _QuickFoodFilter _filter = _QuickFoodFilter.forYou;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preferences =
        ref.watch(quickFoodPreferencesProvider).valueOrNull ??
        const QuickFoodPreferences();
    final suggestions = _suggestions(preferences);

    return Column(
      key: const ValueKey('quick-add-foods'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.quick_add_title,
                style: AppTypography.titleMedium.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const ValueKey('quick-add-see-all'),
              onPressed: () => _showBrowser(preferences),
              child: Text(l10n.quick_add_see_all),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: l10n.quick_add_search,
          child: InkWell(
            key: const ValueKey('quick-add-search'),
            onTap: () => _showBrowser(preferences),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: _softSurface(context, radius: 99),
              child: Row(
                children: [
                  Icon(
                    WaznIcons.search,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.quick_add_search,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textMutedColor,
                      ),
                    ),
                  ),
                  Icon(
                    WaznIcons.chevronRight,
                    size: 18,
                    color: context.textMutedColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _FilterChip(
                label: l10n.quick_add_for_you,
                selected: _filter == _QuickFoodFilter.forYou,
                onTap: () => setState(() => _filter = _QuickFoodFilter.forYou),
              ),
              _FilterChip(
                label: l10n.quick_add_recent,
                selected: _filter == _QuickFoodFilter.recent,
                onTap: () => setState(() => _filter = _QuickFoodFilter.recent),
              ),
              _FilterChip(
                label: l10n.quick_add_local,
                selected: _filter == _QuickFoodFilter.local,
                onTap: () => setState(() => _filter = _QuickFoodFilter.local),
              ),
              _FilterChip(
                label: l10n.quick_add_favorites,
                selected: _filter == _QuickFoodFilter.favorites,
                onTap:
                    () => setState(() => _filter = _QuickFoodFilter.favorites),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (suggestions.isEmpty)
          _EmptyQuickFoods(
            text:
                _filter == _QuickFoodFilter.favorites
                    ? l10n.quick_add_empty_favorites
                    : l10n.quick_add_empty,
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              key: const ValueKey('quick-add-carousel'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return _QuickFoodCard(
                  suggestion: suggestion,
                  languageCode: Localizations.localeOf(context).languageCode,
                  addedCount: _addedCounts[_cardKey(suggestion)] ?? 0,
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }

  List<_QuickSuggestion> _suggestions(QuickFoodPreferences preferences) {
    final history = _rankHistory(widget.meals);
    final rankedCatalog = QuickFoodCatalog.ranked(
      regionPreference: preferences.region,
      cuisinePreference: widget.cuisinePreference,
      mealType: widget.mealType,
    );
    final region = QuickFoodCatalog.resolvedRegion(preferences.region);

    return switch (_filter) {
      _QuickFoodFilter.recent => _recentHistory(widget.meals).take(10).toList(),
      _QuickFoodFilter.local =>
        rankedCatalog
            .where((food) => food.regions.contains(region))
            .take(12)
            .map(_QuickSuggestion.catalog)
            .toList(),
      _QuickFoodFilter.favorites =>
        rankedCatalog
            .where((food) => preferences.favoriteIds.contains(food.nutritionId))
            .map(_QuickSuggestion.catalog)
            .toList(),
      _ => _forYou(history, rankedCatalog),
    };
  }

  List<_QuickSuggestion> _forYou(
    List<_QuickSuggestion> history,
    List<QuickFood> catalog,
  ) {
    final result = <_QuickSuggestion>[];
    final identities = <String>{};
    final names = <String>{};
    for (final item in history.take(4)) {
      result.add(item);
      identities.add(_mealIdentity(item.meal!));
      names.add(_normalizedFoodName(item.meal!.foodName));
    }
    for (final food in catalog) {
      if (result.length >= 10) break;
      if (identities.add(food.nutritionId) &&
          names.add(_normalizedFoodName(food.name))) {
        result.add(_QuickSuggestion.catalog(food));
      }
    }
    return result;
  }

  /// How many times each card has added its food, so its + can tick.
  final _addedCounts = <String, int>{};

  String _cardKey(_QuickSuggestion s) => s.food?.nutritionId ?? s.meal!.id;

  void _markAdded(_QuickSuggestion suggestion) => setState(
    () => _addedCounts.update(
      _cardKey(suggestion),
      (n) => n + 1,
      ifAbsent: () => 1,
    ),
  );

  Future<void> _selectSuggestion(_QuickSuggestion suggestion) async {
    if (suggestion.meal != null) {
      final saved = await widget.onRepeatMeal(suggestion.meal!);
      if (!mounted) return;
      _markAdded(suggestion);
      _showAdded(saved.foodName, saved.id);
      return;
    }
    if (await _showPortion(suggestion.food!) && mounted) {
      _markAdded(suggestion);
    }
  }

  /// Whether a portion was added.
  Future<bool> _showPortion(QuickFood food) async {
    final saved = await showQuickFoodPortionSheet(
      context,
      food: food,
      isFavorite:
          ref
              .read(quickFoodPreferencesProvider)
              .valueOrNull
              ?.favoriteIds
              .contains(food.nutritionId) ??
          false,
      onToggleFavorite:
          () => ref
              .read(quickFoodPreferencesProvider.notifier)
              .toggleFavorite(food.nutritionId),
      onAdd: widget.onAddCatalogFood,
    );
    if (saved != null && mounted) _showAdded(saved.foodName, saved.id);
    return saved != null;
  }

  Future<void> _showBrowser(QuickFoodPreferences preferences) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => _QuickFoodBrowserSheet(
            history: _rankHistory(widget.meals),
            recentHistory: _recentHistory(widget.meals),
            mealType: widget.mealType,
            cuisinePreference: widget.cuisinePreference,
            onAddCatalogFood: widget.onAddCatalogFood,
            onRepeatMeal: widget.onRepeatMeal,
            onAdded: _showAdded,
          ),
    );
  }

  void _showAdded(String foodName, String mealId) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.quick_add_added(foodName)),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.quick_add_undo,
          onPressed: () => widget.onUndo(mealId),
        ),
      ),
    );
  }
}

class _QuickFoodBrowserSheet extends ConsumerStatefulWidget {
  const _QuickFoodBrowserSheet({
    required this.history,
    required this.recentHistory,
    required this.mealType,
    required this.cuisinePreference,
    required this.onAddCatalogFood,
    required this.onRepeatMeal,
    required this.onAdded,
  });

  final List<_QuickSuggestion> history;
  final List<_QuickSuggestion> recentHistory;
  final String mealType;
  final String cuisinePreference;
  final AddCatalogFood onAddCatalogFood;
  final RepeatLoggedMeal onRepeatMeal;
  final void Function(String foodName, String mealId) onAdded;

  @override
  ConsumerState<_QuickFoodBrowserSheet> createState() =>
      _QuickFoodBrowserSheetState();
}

class _QuickFoodBrowserSheetState
    extends ConsumerState<_QuickFoodBrowserSheet> {
  final _searchController = TextEditingController();
  _QuickFoodFilter _filter = _QuickFoodFilter.forYou;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final preferences =
        ref.watch(quickFoodPreferencesProvider).valueOrNull ??
        const QuickFoodPreferences();
    final items = _items(preferences);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.92,
          child: Material(
            color: context.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const _SheetHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.quick_add_title,
                          style: AppTypography.titleLarge.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(WaznIcons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    key: const ValueKey('quick-food-search-field'),
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.quick_add_search,
                      prefixIcon: const Icon(WaznIcons.search, size: 19),
                      suffixIcon:
                          _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(WaznIcons.close, size: 18),
                              ),
                      filled: true,
                      fillColor: context.surfaceContainerColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    key: const ValueKey('quick-food-region-button'),
                    onTap: () => showQuickFoodRegionSheet(context, ref),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            WaznIcons.mapPin,
                            size: 17,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l10n.quick_add_region}: ${quickFoodRegionLabel(l10n, preferences.region)}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            WaznIcons.chevronDown,
                            size: 17,
                            color: context.textMutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _FilterChip(
                        label: l10n.quick_add_for_you,
                        selected: _filter == _QuickFoodFilter.forYou,
                        onTap:
                            () => setState(
                              () => _filter = _QuickFoodFilter.forYou,
                            ),
                      ),
                      _FilterChip(
                        label: l10n.quick_add_recent,
                        selected: _filter == _QuickFoodFilter.recent,
                        onTap:
                            () => setState(
                              () => _filter = _QuickFoodFilter.recent,
                            ),
                      ),
                      _FilterChip(
                        label: l10n.quick_add_local,
                        selected: _filter == _QuickFoodFilter.local,
                        onTap:
                            () => setState(
                              () => _filter = _QuickFoodFilter.local,
                            ),
                      ),
                      _FilterChip(
                        label: l10n.quick_add_favorites,
                        selected: _filter == _QuickFoodFilter.favorites,
                        onTap:
                            () => setState(
                              () => _filter = _QuickFoodFilter.favorites,
                            ),
                      ),
                      _FilterChip(
                        label: l10n.quick_add_all,
                        selected: _filter == _QuickFoodFilter.all,
                        onTap:
                            () =>
                                setState(() => _filter = _QuickFoodFilter.all),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.dividerColor),
                Expanded(
                  child:
                      items.isEmpty
                          ? _EmptyQuickFoods(
                            text:
                                _filter == _QuickFoodFilter.favorites
                                    ? l10n.quick_add_empty_favorites
                                    : l10n.quick_add_empty,
                          )
                          : ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              10,
                              20,
                              math.max(20, media.padding.bottom),
                            ),
                            itemCount: items.length,
                            separatorBuilder:
                                (_, _) => Divider(
                                  height: 1,
                                  indent: 54,
                                  color: context.dividerColor,
                                ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final food = item.food;
                              final favorite =
                                  food != null &&
                                  preferences.favoriteIds.contains(
                                    food.nutritionId,
                                  );
                              return _BrowserFoodRow(
                                suggestion: item,
                                languageCode:
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                isFavorite: favorite,
                                onFavorite:
                                    food == null
                                        ? null
                                        : () => ref
                                            .read(
                                              quickFoodPreferencesProvider
                                                  .notifier,
                                            )
                                            .toggleFavorite(food.nutritionId),
                                onTap: () => _select(item, favorite),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_QuickSuggestion> _items(QuickFoodPreferences preferences) {
    final query = _searchController.text.trim();
    final region = QuickFoodCatalog.resolvedRegion(preferences.region);
    final catalog = QuickFoodCatalog.ranked(
      regionPreference: preferences.region,
      cuisinePreference: widget.cuisinePreference,
      mealType: widget.mealType,
    );
    Iterable<_QuickSuggestion> values = switch (_filter) {
      _QuickFoodFilter.recent => widget.recentHistory,
      _QuickFoodFilter.local => catalog
          .where((food) => food.regions.contains(region))
          .map(_QuickSuggestion.catalog),
      _QuickFoodFilter.favorites => catalog
          .where((food) => preferences.favoriteIds.contains(food.nutritionId))
          .map(_QuickSuggestion.catalog),
      _QuickFoodFilter.all => catalog.map(_QuickSuggestion.catalog),
      _ => _mergeForYou(widget.history, catalog),
    };
    if (query.isNotEmpty) {
      values = values.where((item) {
        if (item.food != null) return item.food!.matches(query);
        return item.meal!.foodName.toLowerCase().contains(query.toLowerCase());
      });
    }
    return values.take(80).toList(growable: false);
  }

  Future<void> _select(_QuickSuggestion item, bool favorite) async {
    if (item.meal != null) {
      final saved = await widget.onRepeatMeal(item.meal!);
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded(saved.foodName, saved.id);
      }
      return;
    }
    final food = item.food!;
    final saved = await showQuickFoodPortionSheet(
      context,
      food: food,
      isFavorite: favorite,
      onToggleFavorite:
          () => ref
              .read(quickFoodPreferencesProvider.notifier)
              .toggleFavorite(food.nutritionId),
      onAdd: widget.onAddCatalogFood,
    );
    if (saved != null && mounted) {
      Navigator.pop(context);
      widget.onAdded(saved.foodName, saved.id);
    }
  }
}

Future<Meal?> showQuickFoodPortionSheet(
  BuildContext context, {
  required QuickFood food,
  required bool isFavorite,
  required VoidCallback onToggleFavorite,
  required AddCatalogFood onAdd,
}) {
  return showModalBottomSheet<Meal>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => _QuickFoodPortionSheet(
          food: food,
          initialFavorite: isFavorite,
          onToggleFavorite: onToggleFavorite,
          onAdd: onAdd,
        ),
  );
}

class _QuickFoodPortionSheet extends StatefulWidget {
  const _QuickFoodPortionSheet({
    required this.food,
    required this.initialFavorite,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  final QuickFood food;
  final bool initialFavorite;
  final VoidCallback onToggleFavorite;
  final AddCatalogFood onAdd;

  @override
  State<_QuickFoodPortionSheet> createState() => _QuickFoodPortionSheetState();
}

class _QuickFoodPortionSheetState extends State<_QuickFoodPortionSheet> {
  double _multiplier = 1;
  late bool _favorite = widget.initialFavorite;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final grams = widget.food.defaultServingG * _multiplier;
    final languageCode = Localizations.localeOf(context).languageCode;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.84),
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              math.max(20, media.padding.bottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHandle(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          widget.food.displayName(languageCode),
                          style: AppTypography.titleLarge.copyWith(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.quick_add_favorites,
                      onPressed: () {
                        widget.onToggleFavorite();
                        setState(() => _favorite = !_favorite);
                      },
                      icon: Icon(
                        _favorite ? WaznIcons.starFilled : WaznIcons.star,
                        color:
                            _favorite
                                ? const Color(0xFFE3A62F)
                                : context.textMutedColor,
                      ),
                    ),
                    IconButton(
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(WaznIcons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.quick_add_serving,
                  style: AppTypography.labelLarge.copyWith(
                    color: context.textSecondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ServingChoice(
                      label: l10n.quick_add_half_serving,
                      value: 0.5,
                      selected: _multiplier == 0.5,
                      onTap: _selectServing,
                    ),
                    _ServingChoice(
                      label: l10n.quick_add_one_serving,
                      value: 1,
                      selected: _multiplier == 1,
                      onTap: _selectServing,
                    ),
                    _ServingChoice(
                      label: l10n.quick_add_one_half_servings,
                      value: 1.5,
                      selected: _multiplier == 1.5,
                      onTap: _selectServing,
                    ),
                    _ServingChoice(
                      label: l10n.quick_add_two_servings,
                      value: 2,
                      selected: _multiplier == 2,
                      onTap: _selectServing,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceContainerColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NutritionFigure(
                          value: l10n.quick_add_calories(
                            widget.food.caloriesFor(grams),
                          ),
                          label: l10n.quick_add_grams(grams.round()),
                        ),
                      ),
                      _VerticalDivider(color: context.dividerColor),
                      Expanded(
                        child: _NutritionFigure(
                          value: '${widget.food.macrosFor(grams).protein} g',
                          label: l10n.result_protein,
                        ),
                      ),
                      _VerticalDivider(color: context.dividerColor),
                      Expanded(
                        child: _NutritionFigure(
                          value: '${widget.food.macrosFor(grams).carbs} g',
                          label: l10n.result_carbs,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    key: const ValueKey('quick-food-add-button'),
                    onPressed:
                        _saving
                            ? null
                            : () async {
                              setState(() => _saving = true);
                              try {
                                final meal = await widget.onAdd(
                                  widget.food,
                                  grams,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context, meal);
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                    icon:
                        _saving
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(WaznIcons.plus, size: 19),
                    label: Text(l10n.quick_add_add),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectServing(double value) => setState(() => _multiplier = value);
}

Future<void> showQuickFoodRegionSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final selected =
      ref.read(quickFoodPreferencesProvider).valueOrNull?.region ?? 'automatic';
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Material(
              color: context.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const _SheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.quick_add_region,
                            style: AppTypography.titleLarge.copyWith(
                              color: context.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(WaznIcons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      l10n.quick_add_region_subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.dividerColor),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: QuickFoodRegion.values.length,
                      itemBuilder: (context, index) {
                        final region = QuickFoodRegion.values[index];
                        final isSelected = region.id == selected;
                        return ListTile(
                          title: Text(quickFoodRegionLabel(l10n, region.id)),
                          leading: Icon(
                            region.id == 'automatic'
                                ? WaznIcons.locate
                                : WaznIcons.mapPin,
                            size: 19,
                          ),
                          trailing: Icon(
                            isSelected ? WaznIcons.circleDot : WaznIcons.circle,
                            color:
                                isSelected
                                    ? context.primaryColor
                                    : context.textMutedColor,
                          ),
                          selected: isSelected,
                          onTap: () async {
                            await ref
                                .read(quickFoodPreferencesProvider.notifier)
                                .setRegion(region.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

String quickFoodRegionLabel(AppLocalizations l10n, String id) => switch (id) {
  'pakistan' => l10n.quick_add_region_pakistan,
  'south_asian' => l10n.quick_add_region_south_asian,
  'middle_eastern' => l10n.quick_add_region_middle_eastern,
  'gulf' => l10n.quick_add_region_gulf,
  'east_asian' => l10n.quick_add_region_east_asian,
  'korean' => l10n.quick_add_region_korean,
  'american' => l10n.quick_add_region_american,
  'mediterranean' => l10n.quick_add_region_mediterranean,
  'international' => l10n.quick_add_region_international,
  _ => l10n.quick_add_region_automatic,
};

class _QuickSuggestion {
  const _QuickSuggestion._({this.food, this.meal, this.frequency = 0});

  factory _QuickSuggestion.catalog(QuickFood food) =>
      _QuickSuggestion._(food: food);

  factory _QuickSuggestion.history(Meal meal, int frequency) =>
      _QuickSuggestion._(meal: meal, frequency: frequency);

  final QuickFood? food;
  final Meal? meal;
  final int frequency;
}

List<_QuickSuggestion> _rankHistory(List<Meal> meals) {
  final groups = <String, List<Meal>>{};
  for (final meal in meals) {
    final key = _mealIdentity(meal);
    if (key.isEmpty) continue;
    groups.putIfAbsent(key, () => []).add(meal);
  }
  final entries =
      groups.values.map((group) {
          group.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return _QuickSuggestion.history(group.first, group.length);
        }).toList()
        ..sort((a, b) {
          final byFrequency = b.frequency.compareTo(a.frequency);
          if (byFrequency != 0) return byFrequency;
          return b.meal!.timestamp.compareTo(a.meal!.timestamp);
        });
  return entries;
}

List<_QuickSuggestion> _recentHistory(List<Meal> meals) {
  final sorted = [...meals]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final counts = <String, int>{};
  for (final meal in meals) {
    final key = _mealIdentity(meal);
    if (key.isNotEmpty) counts[key] = (counts[key] ?? 0) + 1;
  }
  final seen = <String>{};
  return [
    for (final meal in sorted)
      if (_mealIdentity(meal).isNotEmpty && seen.add(_mealIdentity(meal)))
        _QuickSuggestion.history(meal, counts[_mealIdentity(meal)] ?? 1),
  ];
}

Iterable<_QuickSuggestion> _mergeForYou(
  List<_QuickSuggestion> history,
  List<QuickFood> catalog,
) sync* {
  final identities = <String>{};
  final names = <String>{};
  for (final item in history.take(6)) {
    identities.add(_mealIdentity(item.meal!));
    names.add(_normalizedFoodName(item.meal!.foodName));
    yield item;
  }
  for (final food in catalog) {
    if (identities.add(food.nutritionId) &&
        names.add(_normalizedFoodName(food.name))) {
      yield _QuickSuggestion.catalog(food);
    }
  }
}

String _mealIdentity(Meal meal) =>
    meal.nutritionMatchId?.trim().isNotEmpty == true
        ? meal.nutritionMatchId!
        : _normalizedFoodName(meal.foodName);

String _normalizedFoodName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

class _QuickFoodCard extends StatelessWidget {
  const _QuickFoodCard({
    required this.suggestion,
    required this.languageCode,
    required this.onTap,
    this.addedCount = 0,
  });

  final _QuickSuggestion suggestion;

  /// Goes up each time this card adds its food; the + ticks for each one.
  final int addedCount;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final food = suggestion.food;
    final meal = suggestion.meal;
    final name = food?.displayName(languageCode) ?? meal!.foodName;
    final calories = food?.caloriesFor(food.defaultServingG) ?? meal!.calories;

    return SizedBox(
      width: 158,
      child: DecoratedBox(
        decoration: _softSurface(context, radius: 18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('quick-food-${food?.nutritionId ?? meal!.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        WaznIcons.calories,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.quick_add_calories(calories),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      _AddTick(count: addedCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card's +, which turns into a green tick for a moment each time the
/// card adds its food, then turns back.
class _AddTick extends StatefulWidget {
  const _AddTick({required this.count});

  final int count;

  @override
  State<_AddTick> createState() => _AddTickState();
}

class _AddTickState extends State<_AddTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
    value: 1,
  );

  @override
  void didUpdateWidget(_AddTick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > oldWidget.count) {
      HapticFeedback.lightImpact();
      if (AppMotion.reduceMotion(context)) return;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColor;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final v = _controller.value;
        // In over the first fifth, held, back over the last fifth.
        final ticked =
            v >= 1
                ? 0.0
                : (v < .2
                    ? AppMotion.springCurve.transform(v / .2)
                    : (v > .8
                        ? 1 - Curves.easeIn.transform((v - .8) / .2)
                        : 1.0));
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color.lerp(
              primary.withValues(alpha: 0.12),
              primary,
              ticked.clamp(0.0, 1.0),
            ),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: ticked * 1.6,
                child: Transform.scale(
                  scale: (1 - ticked).clamp(0.0, 1.0),
                  child: Icon(WaznIcons.plus, color: primary, size: 18),
                ),
              ),
              Transform.rotate(
                angle: (1 - ticked) * -0.7,
                child: Transform.scale(
                  scale: ticked.clamp(0.0, 1.2),
                  child: const Icon(
                    WaznIcons.check,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrowserFoodRow extends StatelessWidget {
  const _BrowserFoodRow({
    required this.suggestion,
    required this.languageCode,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final _QuickSuggestion suggestion;
  final String languageCode;
  final bool isFavorite;
  final VoidCallback? onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final food = suggestion.food;
    final meal = suggestion.meal;
    final name = food?.displayName(languageCode) ?? meal!.foodName;
    final calories = food?.caloriesFor(food.defaultServingG) ?? meal!.calories;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  meal != null ? WaznIcons.history : WaznIcons.meal,
                  size: 20,
                  color: context.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal != null
                          ? '${l10n.quick_add_calories(calories)} · ${l10n.quick_add_previous_portion}'
                          : '${l10n.quick_add_calories(calories)} · ${l10n.quick_add_grams(food!.defaultServingG.round())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (onFavorite != null)
                IconButton(
                  tooltip: l10n.quick_add_favorites,
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? WaznIcons.starFilled : WaznIcons.star,
                    color:
                        isFavorite
                            ? const Color(0xFFE3A62F)
                            : context.textMutedColor,
                  ),
                ),
              Icon(WaznIcons.plusCircle, size: 22, color: context.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        shape: const StadiumBorder(),
        side: BorderSide(
          color:
              selected
                  ? Colors.transparent
                  : context.dividerColor.withValues(alpha: 0.6),
        ),
        selectedColor: context.primaryColor,
        backgroundColor: context.cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: selected ? Colors.white : context.textSecondaryColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServingChoice extends StatelessWidget {
  const _ServingChoice({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double value;
  final bool selected;
  final ValueChanged<double> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(value),
      showCheckmark: false,
      selectedColor: context.primaryColor.withValues(alpha: 0.12),
      side: BorderSide(
        color: selected ? context.primaryColor : context.dividerColor,
      ),
    );
  }
}

class _NutritionFigure extends StatelessWidget {
  const _NutritionFigure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: context.textMutedColor,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 38,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: color,
  );
}

class _EmptyQuickFoods extends StatelessWidget {
  const _EmptyQuickFoods({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.surfaceContainerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dividerColor),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: context.textSecondaryColor,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: context.dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// A raised surface for Quick Add's search pill and food cards: no hard
/// outline, a soft shadow in light mode and a faint lift in dark mode.
BoxDecoration _softSurface(BuildContext context, {required double radius}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: dark ? Colors.white.withValues(alpha: 0.045) : AppColors.cardBg,
    borderRadius: BorderRadius.circular(radius),
    border:
        dark ? Border.all(color: Colors.white.withValues(alpha: 0.06)) : null,
    boxShadow:
        dark
            ? null
            : [
              BoxShadow(
                color: const Color(0xFF16181D).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
  );
}
