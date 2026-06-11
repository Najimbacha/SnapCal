import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _fetch({String? query, bool clear = false, bool force = false}) async {
    if (!mounted) return;
    final ap = context.read<AssistantProvider>();
    final mp = context.read<MealProvider>();
    final sp = context.read<SettingsProvider>();
    await ap.fetchRecommendations(
      currentCalories: mp.todaysTotalCalories,
      targetCalories: sp.dailyCalorieGoal,
      currentMacros: {
        'protein': mp.todaysTotalMacros.protein,
        'carbs': mp.todaysTotalMacros.carbs,
        'fat': mp.todaysTotalMacros.fat,
      },
      targetMacros: {
        'protein': sp.dailyProteinGoal,
        'carbs': sp.dailyCarbGoal,
        'fat': sp.dailyFatGoal,
      },
      mealNames: mp.todaysMeals.map((m) => m.foodName).toList(),
      dietaryRestriction: sp.dietaryRestriction,
      userQuery: query,
      clearPrevious: clear,
      forceFetch: force,
      language: sp.languageCode,
    );
    if (mounted) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _submit() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    await _fetch(query: q);
  }

  void _handleSuggestion(String query) async {
    _ctrl.clear();
    await _fetch(query: query);
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
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF27272A), width: 0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Icon(Icons.chevron_left_rounded, size: 18, color: Color(0xFFA1A1AA)),
            ),
          ),
        ),
        title: Column(
          children: [
            const Text(
              'AI Coach',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFAFAFA),
                letterSpacing: 0.01,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _fetch(clear: true, force: true),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF27272A), width: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(Icons.brightness_6_outlined, size: 16, color: Color(0xFFA1A1AA)),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AssistantProvider>(
        builder: (context, ap, _) {
          if (ap.history.isEmpty && ap.isLoading) {
            return const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7C3AED),
                ),
              ),
            );
          }

          if (ap.history.isEmpty) {
            return _buildEmptyState();
          }

          return _buildChatView(ap);
        },
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 52),

          // Hero icon mark with online badge
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF27272A), width: 0.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 28,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFF09090B), width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Headline
          const Text(
            'How can I help\nyou today?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFFFAFAFA),
              height: 1.3,
              letterSpacing: -0.02,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          const Text(
            'Nutrition • meal plans • daily goals',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF52525B),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 32),

          // Suggestion cards
          _buildSuggestionCard(
            icon: Icons.restaurant_rounded,
            iconBg: const Color(0xFF3B0764),
            iconColor: const Color(0xFFA855F7),
            label: 'Scan my meal',
            sublabel: 'Get instant calorie breakdown',
          ),
          const SizedBox(height: 10),
          _buildSuggestionCard(
            icon: Icons.calendar_today_rounded,
            iconBg: const Color(0xFF052E16),
            iconColor: const Color(0xFF22C55E),
            label: 'Plan this week',
            sublabel: 'Smart 7-day meal schedule',
          ),
          const SizedBox(height: 10),
          _buildSuggestionCard(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFF1C1917),
            iconColor: const Color(0xFFF97316),
            label: 'Track my day',
            sublabel: 'Log food, water & progress',
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String sublabel,
  }) {
    return GestureDetector(
      onTap: () => _handleSuggestion(label),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE4E4E7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: Color(0xFF3F3F46),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(AssistantProvider ap) {
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: user ? const Color(0xFF7C3AED) : const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: user ? const Radius.circular(4) : const Radius.circular(16),
                      bottomLeft: !user ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: user ? Colors.transparent : const Color(0xFF27272A),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: user ? Colors.white : const Color(0xFFE4E4E7),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (user) const SizedBox(width: 8),
              if (user)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, size: 14, color: Color(0xFF7C3AED)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(
          top: BorderSide(color: Color(0xFF18181B), width: 0.5),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF27272A), width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                    color: Color(0xFF3F3F46),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFFAFAFA),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
