import 'dart:async';
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
  final _focus = FocusNode();
  final Set<int> _typedIndices = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focus.dispose();
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
    if (clear || force) _typedIndices.clear();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _handleSuggestion(String query) {
    _ctrl.clear();
    _focus.unfocus();
    _fetch(query: query);
  }

  void _submit() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    _focus.unfocus();
    _fetch(query: q);
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

    return Scaffold(
      backgroundColor: d ? const Color(0xFF09090B) : Colors.white,
      appBar: AppBar(
        backgroundColor: d ? const Color(0xFF09090B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: d ? const Color(0xFFA1A1AA) : const Color(0xFF3C3C43),
            ),
          ),
        ),
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/avatar/fajar.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fajar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: d ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Nutritionist',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: d ? const Color(0xFF71717A) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => _fetch(clear: true, force: true),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: d ? const Color(0xFFA1A1AA) : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Consumer<AssistantProvider>(
                builder: (context, ap, _) {
          if (ap.history.isEmpty && ap.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAvatar(48),
                  const SizedBox(height: 16),
                  Text(
                    'Fajar is thinking...',
                    style: TextStyle(
                      fontSize: 14,
                      color: d ? const Color(0xFF71717A) : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            );
          }

          if (ap.history.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAvatar(80),
                  const SizedBox(height: 16),
                  Text(
                    'Fajar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: d ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Nutrition Coach',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: d ? const Color(0xFF71717A) : const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'What can I help you with?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: d ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildActionGrid(d),
                  const SizedBox(height: 24),
                  _buildDivider(d),
                  const SizedBox(height: 20),
                  _buildSuggestions(d),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: ap.history.length,
            itemBuilder: (context, i) {
              final msg = ap.history[i];
              final user = _isUser(msg);
              final text = _parseContent(msg);
              if (text.isEmpty) return const SizedBox.shrink();

              final showTyping = !user && !_typedIndices.contains(i);
              if (showTyping && text.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_typedIndices.contains(i)) {
                    setState(() => _typedIndices.add(i));
                  }
                });
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!user) ...[
                      _buildAvatar(28),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!user)
                            Padding(
                              padding: const EdgeInsets.only(left: 2, bottom: 4),
                              child: Text(
                                'Fajar',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: d ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: user
                                  ? (d ? const Color(0xFF7C3AED) : const Color(0xFF5C5FE0))
                                  : (d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7)),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: user ? const Radius.circular(4) : null,
                                bottomLeft: !user ? const Radius.circular(4) : null,
                              ),
                            ),
                            child: showTyping
                                ? _TypingText(
                                    text: text,
                                    color: d ? const Color(0xFFE4E4E7) : const Color(0xFF1C1C1E),
                                    onComplete: () {
                                      if (mounted) {
                                        setState(() => _typedIndices.add(i));
                                        _scroll.animateTo(
                                          _scroll.position.maxScrollExtent,
                                          duration: const Duration(milliseconds: 100),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    },
                                  )
                                : _buildRichText(text, user, d),
                          ),
                        ],
                      ),
                    ),
                    if (user) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: d ? const Color(0xFFA1A1AA) : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
                },
              ),
            ),
            _buildInputBar(d),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double size) {
    return ClipOval(
      child: Image.asset(
        'assets/avatar/fajar.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionGrid(bool d) {
    final items = [
      _GridItem(icon: '📷', label: 'Food', query: 'What should I eat today?'),
      _GridItem(icon: '🔥', label: 'Calories', query: 'How many calories should I eat?'),
      _GridItem(icon: '🥗', label: 'Plan', query: 'Create a meal plan for me'),
      _GridItem(icon: '⚖️', label: 'Weight', query: 'Help me with my weight goal'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: items.map((item) => GestureDetector(
        onTap: () => _handleSuggestion(item.query),
        child: Container(
          decoration: BoxDecoration(
            color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: d ? const Color(0xFFE4E4E7) : const Color(0xFF3C3C43),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDivider(bool d) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or ask a question',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: d ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(bool d) {
    final suggestions = [
      'How many calories should I eat?',
      'Create a meal plan',
      'Analyze my lunch photo',
      'Suggest a high-protein breakfast',
    ];

    return Column(
      children: suggestions.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => _handleSuggestion(s),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: d ? const Color(0xFF52525B) : const Color(0xFFA1A1AA),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: d ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRichText(String text, bool user, bool d) {
    final color = user
        ? Colors.white
        : (d ? const Color(0xFFE4E4E7) : const Color(0xFF1C1C1E));

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15, height: 1.5, color: color),
        children: spans,
      ),
    );
  }

  Widget _buildInputBar(bool d) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: BoxDecoration(
        color: d ? const Color(0xFF09090B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 100),
              decoration: BoxDecoration(
                color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.send,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(
                    color: d ? const Color(0xFF3F3F46) : const Color(0xFF8E8E93),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: d ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submit,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingText extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback? onComplete;

  const _TypingText({required this.text, required this.color, this.onComplete});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> {
  String _displayed = '';
  int _charIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayed = '';
      _charIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _charIndex++;
          _displayed = widget.text.substring(0, _charIndex);
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: widget.color,
      ),
    );
  }
}

class _GridItem {
  final String icon;
  final String label;
  final String query;

  const _GridItem({required this.icon, required this.label, required this.query});
}
