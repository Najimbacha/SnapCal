import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/assistant_service.dart';
import '../../data/services/premium_gate_service.dart';
import '../../data/services/pro_feature_service.dart';
import 'widgets/coach_overlays.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final Set<int> _typedIndices = {};
  final List<dynamic> _messages = [];
  bool _isLoading = false;

  /// Set when a free user has spent their daily AI message. Drives the
  /// [CoachLockedOverlay] below. The counter and the ceiling live in
  /// [PremiumGateService]; the server enforces the same limit independently.
  bool _limitReached = false;

  /// Sentinel content for a failed request, rendered as an error bubble with
  /// a retry affordance instead of hanging on the typing indicator forever.
  static const String _errorMsg = '__coach_error__';
  String? _lastQuery;

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

  Future<void> _fetch({
    String? query,
    bool clear = false,
    bool force = false,
    bool echoUser = true,
  }) async {
    if (!mounted) return;

    // The coach was never gated: CoachLockedOverlay existed but was imported
    // nowhere, and the counters in PremiumGateService were never called, so
    // every free user had unlimited AI messages.
    final access = ref.read(proAccessProvider);
    final unlimited = access.can(ProFeature.unlimitedAiCoach);
    if (!unlimited && access.isFree) {
      if (PremiumGateService().hasReachedAiLimit(false)) {
        setState(() => _limitReached = true);
        return;
      }
    }

    if (echoUser && query != null && query.isNotEmpty) {
      setState(() => _messages.add({'type': 'user', 'content': query}));
    }
    if (query != null && query.isNotEmpty) {
      _lastQuery = query;
    }
    setState(() => _isLoading = true);

    String? result;
    Object? error;
    int? statusCode;
    try {
      result = await ref
          .read(assistantProvider.notifier)
          .fetchRecommendations(query ?? '');
    } catch (e) {
      error = e;
      if (e is DioException) statusCode = e.response?.statusCode;
    }
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (clear || force) {
        _messages.clear();
        _typedIndices.clear();
      }
      if (error != null || result == null || result.isEmpty) {
        debugPrint(
          'AI coach request failed'
          '${statusCode != null ? ' (HTTP $statusCode)' : ''}: $error',
        );
        if (error is DioException && error.response?.data != null) {
          debugPrint('AI coach server detail: ${error.response!.data}');
        }
        _messages.add({
          'type': 'assistant',
          'content': _errorMsg,
          if (statusCode != null) 'status': statusCode,
        });
      } else {
        _messages.add({'type': 'assistant', 'content': result});
      }
    });

    if (!unlimited && access.isFree && error == null && result!.isNotEmpty) {
      await PremiumGateService().incrementAiMessages();
      if (mounted && PremiumGateService().hasReachedAiLimit(false)) {
        setState(() => _limitReached = true);
      }
    }
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

  /// Drops trailing error bubbles and re-sends the last question without
  /// echoing a duplicate user bubble.
  void _retryLast() {
    while (_messages.isNotEmpty && _parseContent(_messages.last) == _errorMsg) {
      _messages.removeLast();
    }
    setState(() {});
    _fetch(query: _lastQuery, echoUser: false);
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
              LucideIcons.chevronLeft,
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
                cacheWidth: 80,
                cacheHeight: 80,
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
                        color:
                            d
                                ? const Color(0xFF71717A)
                                : const Color(0xFF8E8E93),
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
                LucideIcons.refreshCw,
                size: 18,
                color: d ? const Color(0xFFA1A1AA) : const Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child:
                      _messages.isEmpty && _isLoading
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAvatar(48),
                                const SizedBox(height: 16),
                                Text(
                                  'Fajar is thinking...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        d
                                            ? const Color(0xFF71717A)
                                            : const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : _messages.isEmpty
                          ? SingleChildScrollView(
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
                                    color:
                                        d
                                            ? Colors.white
                                            : const Color(0xFF1C1C1E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'AI Nutrition Coach',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        d
                                            ? const Color(0xFF71717A)
                                            : const Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'What can I help you with?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        d
                                            ? const Color(0xFFA1A1AA)
                                            : const Color(0xFF6B7280),
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
                          )
                          : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final msg = _messages[i];
                              final user = _isUser(msg);
                              final text = _parseContent(msg);
                              if (text.isEmpty) return const SizedBox.shrink();

                              if (text == _errorMsg) {
                                final status =
                                    msg is Map && msg['status'] is int
                                        ? msg['status'] as int
                                        : null;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildAvatar(28),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: _buildErrorBubble(d, status),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final showTyping =
                                  !user && !_typedIndices.contains(i);
                              if (showTyping && text.isNotEmpty) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted && !_typedIndices.contains(i)) {
                                    setState(() => _typedIndices.add(i));
                                  }
                                });
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      user
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!user) ...[
                                      _buildAvatar(28),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            user
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                        children: [
                                          if (!user)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 2,
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                'Fajar',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      d
                                                          ? const Color(
                                                            0xFFA1A1AA,
                                                          )
                                                          : const Color(
                                                            0xFF6B7280,
                                                          ),
                                                ),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  user
                                                      ? (d
                                                          ? AppColors
                                                              .primaryDark
                                                          : AppColors.primary)
                                                      : (d
                                                          ? const Color(
                                                            0xFF18181B,
                                                          )
                                                          : const Color(
                                                            0xFFF2F2F7,
                                                          )),
                                              borderRadius: BorderRadius.circular(
                                                16,
                                              ).copyWith(
                                                bottomRight:
                                                    user
                                                        ? const Radius.circular(
                                                          4,
                                                        )
                                                        : null,
                                                bottomLeft:
                                                    !user
                                                        ? const Radius.circular(
                                                          4,
                                                        )
                                                        : null,
                                              ),
                                            ),
                                            child:
                                                showTyping
                                                    ? _TypingText(
                                                      text: text,
                                                      color:
                                                          d
                                                              ? const Color(
                                                                0xFFE4E4E7,
                                                              )
                                                              : const Color(
                                                                0xFF1C1C1E,
                                                              ),
                                                      onComplete: () {
                                                        if (mounted) {
                                                          setState(
                                                            () => _typedIndices
                                                                .add(i),
                                                          );
                                                          _scroll.animateTo(
                                                            _scroll
                                                                .position
                                                                .maxScrollExtent,
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      100,
                                                                ),
                                                            curve:
                                                                Curves.easeOut,
                                                          );
                                                        }
                                                      },
                                                    )
                                                    : _buildRichText(
                                                      text,
                                                      user,
                                                      d,
                                                    ),
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
                                          color:
                                              d
                                                  ? const Color(0xFF27272A)
                                                  : const Color(0xFFE5E5EA),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          LucideIcons.user,
                                          size: 14,
                                          color:
                                              d
                                                  ? const Color(0xFFA1A1AA)
                                                  : const Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                ),
                _buildInputBar(d),
              ],
            ),
          ),
          // The daily-limit wall. Only ever shown to a user we know
          // is on the free tier.
          if (_limitReached) const Positioned.fill(child: CoachLockedOverlay()),
        ],
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
        cacheWidth: 80,
        cacheHeight: 80,
      ),
    );
  }

  Widget _buildErrorBubble(bool d, int? statusCode) {
    final tint = AppColors.error;
    // A 5xx is the server failing, not the phone: "check your connection"
    // would send the user staring at their Wi-Fi for nothing.
    final isServerIssue =
        statusCode != null && statusCode >= 500 && statusCode < 600;
    final detail =
        isServerIssue
            ? "Fajar's server is having trouble right now. Give it a moment and retry."
            : 'Check your connection and try again.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: d ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(
          16,
        ).copyWith(bottomLeft: const Radius.circular(4)),
        border: Border.all(color: tint.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.wifiOff, size: 14, color: tint),
              const SizedBox(width: 8),
              Text(
                "Fajar couldn't reply",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: d ? const Color(0xFFE4E4E7) : const Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: d ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isLoading ? null : _retryLast,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  LucideIcons.refreshCw,
                  size: 12,
                  color: d ? AppColors.primary : AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: d ? AppColors.primary : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool d) {
    final items = [
      _GridItem(icon: '📷', label: 'Food', query: 'What should I eat today?'),
      _GridItem(
        icon: '🔥',
        label: 'Calories',
        query: 'How many calories should I eat?',
      ),
      _GridItem(icon: '🥗', label: 'Plan', query: 'Create a meal plan for me'),
      _GridItem(
        icon: '⚖️',
        label: 'Weight',
        query: 'Help me with my weight goal',
      ),
    ];

    return Column(
      children: [
        Row(
          children:
              items.take(2).toList().asMap().entries.map((e) {
                final item = e.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.key == 0 ? 5 : 0,
                      left: e.key == 1 ? 5 : 0,
                    ),
                    child: _ActionGridTile(
                      item: item,
                      handleSuggestion: _handleSuggestion,
                      d: d,
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children:
              items.skip(2).toList().asMap().entries.map((e) {
                final item = e.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.key == 0 ? 5 : 0,
                      left: e.key == 1 ? 5 : 0,
                    ),
                    child: _ActionGridTile(
                      item: item,
                      handleSuggestion: _handleSuggestion,
                      d: d,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
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
      children:
          suggestions
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _handleSuggestion(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            d
                                ? const Color(0xFF18181B)
                                : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              d
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE5E5EA),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.arrowRight,
                            size: 14,
                            color:
                                d
                                    ? const Color(0xFF52525B)
                                    : const Color(0xFFA1A1AA),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color:
                                    d
                                        ? const Color(0xFFA1A1AA)
                                        : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildRichText(String text, bool user, bool d) {
    final color =
        user
            ? Colors.white
            : (d ? const Color(0xFFE4E4E7) : const Color(0xFF1C1C1E));

    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
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
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 10,
      ),
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
                    color:
                        d ? const Color(0xFF3F3F46) : const Color(0xFF8E8E93),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.arrowUp, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGridTile extends StatelessWidget {
  final _GridItem item;
  final void Function(String) handleSuggestion;
  final bool d;

  const _ActionGridTile({
    required this.item,
    required this.handleSuggestion,
    required this.d,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => handleSuggestion(item.query),
      child: Container(
        decoration: BoxDecoration(
          color: d ? const Color(0xFF18181B) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: d ? const Color(0xFF27272A) : const Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
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
      style: TextStyle(fontSize: 15, height: 1.5, color: widget.color),
    );
  }
}

class _GridItem {
  final String icon;
  final String label;
  final String query;

  const _GridItem({
    required this.icon,
    required this.label,
    required this.query,
  });
}
