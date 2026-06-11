import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/assistant_service.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _fetch()); }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _fetch({String? query, bool clear = false, bool force = false}) async {
    if (!mounted) return;
    final ap = context.read<AssistantProvider>();
    final mp = context.read<MealProvider>();
    final sp = context.read<SettingsProvider>();
    await ap.fetchRecommendations(
      currentCalories: mp.todaysTotalCalories,
      targetCalories: sp.dailyCalorieGoal,
      currentMacros: {'protein': mp.todaysTotalMacros.protein, 'carbs': mp.todaysTotalMacros.carbs, 'fat': mp.todaysTotalMacros.fat},
      targetMacros: {'protein': sp.dailyProteinGoal, 'carbs': sp.dailyCarbGoal, 'fat': sp.dailyFatGoal},
      mealNames: mp.todaysMeals.map((m) => m.foodName).toList(),
      dietaryRestriction: sp.dietaryRestriction,
      userQuery: query, clearPrevious: clear, forceFetch: force, language: sp.languageCode,
    );
    if (mounted) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _submit() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    await _fetch(query: q);
  }

  String _parseContent(dynamic msg) {
    if (msg is Map) return msg['content'] ?? msg['text'] ?? '';
    if (msg is AssistantResponse) return msg.content;
    return msg.toString();
  }

  bool _isUser(dynamic msg) {
    if (msg is Map) return msg['type'] == 'user';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    final pro = context.watch<SettingsProvider>().isPro;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 36, height: 36,
            decoration: BoxDecoration(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.chevron_left_rounded, size: 22, color: d ? Colors.white : const Color(0xFF1C1C1E)),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Coach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                Text('Online', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF10B981))),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _fetch(clear: true, force: true),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 36, height: 36,
              decoration: BoxDecoration(color: (d ? Colors.white : Colors.black).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.refresh_rounded, size: 18, color: d ? Colors.white38 : const Color(0xFF8E8E93)),
            ),
          ),
        ],
      ),
      body: Consumer<AssistantProvider>(
        builder: (context, ap, _) {
          if (ap.history.isEmpty && ap.isLoading) {
            return Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)));
          }
          if (ap.history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 24, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    Text('How can I help you today?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: d ? Colors.white : const Color(0xFF1C1C1E))),
                    const SizedBox(height: 8),
                    Text('Ask me about nutrition, meal ideas, or your daily goals', style: TextStyle(fontSize: 14, color: d ? Colors.white38 : const Color(0xFF8E8E93))),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: ap.history.length,
            itemBuilder: (context, i) {
              final msg = ap.history[i];
              final user = _isUser(msg);
              final text = _parseContent(msg);
              if (text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                child: Row(
                  mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!user) ...[
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)]),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Center(child: Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: user ? const Color(0xFF5C5FE0) : (d ? const Color(0xFF1C1C1E) : Colors.white),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: user ? Radius.circular(4) : Radius.circular(16),
                            bottomLeft: !user ? Radius.circular(4) : Radius.circular(16),
                          ),
                        ),
                        child: Text(text, style: TextStyle(fontSize: 15, color: user ? Colors.white : (d ? Colors.white : const Color(0xFF1C1C1E)), height: 1.4)),
                      ),
                    ),
                    if (user) const SizedBox(width: 8),
                    if (user)
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Center(child: Icon(Icons.person_rounded, size: 14, color: AppColors.primary)),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 8),
        decoration: BoxDecoration(
          color: d ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: d ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: d ? const Color(0xFF2C2C2E) : const Color(0xFFC7C7CC).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onSubmitted: (_) => _submit(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: d ? Colors.white38 : const Color(0xFF8E8E93), fontSize: 16),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: TextStyle(fontSize: 16, color: d ? Colors.white : const Color(0xFF1C1C1E)),
                      ),
                    ),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.arrow_upward_rounded, size: 17, color: Colors.white),
                      ),
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
