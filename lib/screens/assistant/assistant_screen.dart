import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_typography.dart';
import '../../data/services/connectivity_service.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/services/assistant_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/app_page_scaffold.dart';
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
  
  // Voice & Image State
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    context.read<AssistantProvider>().addListener(_scrollToBottom);
    _staggerController?.forward();
  }

  @override
  void dispose() {
    _staggerController?.dispose();
    context.read<AssistantProvider>().removeListener(_scrollToBottom);
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
    final mealNames = mealProvider.todaysMeals.map((m) => m.foodName).toList();
    final dietaryRestriction = settingsProvider.dietaryRestriction;

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
      mealNames: mealNames,
      dietaryRestriction: dietaryRestriction,
      userQuery: query,
      imageBytes: imageBytes,
      clearPrevious: clearPrevious,
      forceFetch: forceFetch,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedImage == null) return;
    if (!context.read<ConnectivityService>().isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistant needs connection.')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    
    Uint8List? imageBytes;
    if (_selectedImage != null) {
      imageBytes = await _selectedImage!.readAsBytes();
    }

    _fetchRecommendations(
      query: query.isEmpty ? null : query,
      imageBytes: imageBytes,
    );
    
    _searchController.clear();
    setState(() => _selectedImage = null);
    FocusScope.of(context).unfocus();
  }

  Future<void> _handleVoice() async {
    if (!_isListening) {
      // Request permission explicitly
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required for voice input.')),
          );
        }
        return;
      }

      try {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              setState(() => _isListening = false);
            }
          },
          onError: (val) {
            debugPrint('Speech Error: $val');
            setState(() => _isListening = false);
          },
        );

        if (available) {
          setState(() => _isListening = true);
          _speech.listen(
            onResult: (val) {
              setState(() {
                _searchController.text = val.recognizedWords;
              });
            },
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          );
        } else {
          debugPrint('Speech recognition not available on this device');
        }
      } catch (e) {
        debugPrint('Speech Initialization Error: $e');
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_searchController.text.isNotEmpty) {
        _handleSearch();
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Full Screen Mesh Gradient Background
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
              // Custom Chat AppBar
              _ChatAppBar(
                onRefresh: () => _fetchRecommendations(clearPrevious: true, forceFetch: true),
              ),
              
              Expanded(
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _ThinkingPulse(),
                            const SizedBox(height: 16),
                            Text(
                              'Preparing your wellness journey...',
                              style: AppTypography.labelMedium.copyWith(
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (assistant.history.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.wellnessGlow,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.sparkles,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'How can I help you today?',
                                  style: AppTypography.heading2.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your personal SnapCal coach is ready to assist with recipes, goals, and nutrition advice.',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: context.textSecondaryColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 48),
                                _StartersGrid(onSelect: (query) {
                                  _searchController.text = query;
                                  _handleSearch();
                                }),
                                const SizedBox(height: 120), // Clear input bar
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                        top: 16,
                        left: 12,
                        right: 12,
                      ),
                      itemCount: assistant.history.length + (assistant.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= assistant.history.length) {
                          return const _ThinkingPulse();
                        }

                        final item = assistant.history[index];
                        final isUser = item is Map && item['type'] == 'user';
                        final isLatestAssistant = !isUser && index == assistant.history.length - 1 && !assistant.isLoading;
                        
                        final anim = _staggerController != null 
                          ? CurvedAnimation(
                              parent: _staggerController!,
                              curve: Interval(
                              (index % 10) * 0.1, 
                              (((index % 10) * 0.1) + 0.4).clamp(0.0, 1.0), 
                              curve: Curves.easeOutCubic
                              ),
                            )
                          : const AlwaysStoppedAnimation(1.0);

                        return _staggeredSlide(
                          anim,
                          _ChatBubble(
                            content: isUser ? (item['content'] as String) : (item.content as String),
                            isUser: isUser,
                            title: isUser ? null : item.title,
                            type: isUser ? null : item.type,
                            isTypewriter: isLatestAssistant,
                            onComplete: _scrollToBottom,
                            actions: isUser ? null : (item as AssistantResponse).actions,
                            hasImage: isUser ? (item['hasImage'] as bool? ?? false) : false,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Integrated Input Bar (Modern Clean Style)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8, tileMode: TileMode.clamp),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80, height: 80, color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  onPressed: () => setState(() => _selectedImage = null),
                                  icon: const Icon(Icons.cancel, size: 20),
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          AppScaleTap(
                            onTap: _pickImage,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(LucideIcons.image, size: 20, color: context.textSecondaryColor),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _searchController,
                                enabled: context.watch<ConnectivityService>().isOnline,
                                style: AppTypography.bodyLarge.copyWith(fontSize: 16),
                                maxLines: 5,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: _isListening ? 'Listening...' : 'Type a message...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: context.textMutedColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                onSubmitted: (_) => _handleSearch(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppScaleTap(
                            onTap: _handleVoice,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                _isListening ? LucideIcons.mic : LucideIcons.micOff, 
                                size: 20, 
                                color: _isListening ? AppColors.primary : context.textSecondaryColor
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppScaleTap(
                            onTap: _handleSearch,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.wellnessGlow,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(LucideIcons.arrowUp, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8, tileMode: TileMode.clamp),
        child: Container(
          padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              AppScaleTap(
                onTap: () => context.pop(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Image.asset('assets/icon/icon.png', width: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Always active',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AppScaleTap(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Chat?'),
                      content: const Text('This will delete your conversation history with the coach.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    context.read<AssistantProvider>().clear();
                  }
                },
                child: Icon(LucideIcons.trash2, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
              const SizedBox(width: 12),
              AppScaleTap(
                onTap: onRefresh,
                child: Icon(LucideIcons.refreshCw, size: 20, color: colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



Widget _staggeredSlide(Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 15 * (1 - animation.value)),
          child: child,
        ),
      );
    },
    child: child,
  );
}



class _StartersGrid extends StatelessWidget {
  final Function(String) onSelect;

  const _StartersGrid({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final starters = [
      {'title': 'Meal Ideas', 'desc': 'High-protein dinners', 'icon': LucideIcons.utensils},
      {'title': 'Calorie Check', 'desc': 'How am I doing today?', 'icon': LucideIcons.flame},
      {'title': 'Tips', 'desc': 'Curbing late-night cravings', 'icon': LucideIcons.sparkles},
      {'title': 'Plans', 'desc': 'Create a 3-day meal plan', 'icon': LucideIcons.calendar},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: starters.length,
      itemBuilder: (context, index) {
        final item = starters[index];
        final colorScheme = Theme.of(context).colorScheme;
        return AppScaleTap(
          onTap: () => onSelect(item['desc'] as String),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'] as IconData, size: 16, color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  item['title'] as String,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item['desc'] as String,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final String? title;
  final String? type;
  final bool isTypewriter;
  final VoidCallback onComplete;
  final List<AssistantAction>? actions; // New: Action buttons
  final bool hasImage; // New: Image attachment flag

  const _ChatBubble({
    required this.content,
    required this.isUser,
    this.title,
    this.type,
    this.isTypewriter = false,
    required this.onComplete,
    this.actions,
    this.hasImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUserMessage = isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUserMessage && title != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                title!.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUserMessage) ...[
                const SizedBox(width: 4),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  child: Image.asset('assets/icon/icon.png', width: 14),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isUserMessage
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              )
                            : null,
                        color: isUserMessage
                            ? null
                            : colorScheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(24),
                          topRight: const Radius.circular(24),
                          bottomLeft: Radius.circular(isUserMessage ? 24 : 4),
                          bottomRight: Radius.circular(isUserMessage ? 4 : 24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isUserMessage 
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasImage)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image, size: 14, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Text('Attached image', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                ],
                              ),
                            ),
                          isUserMessage
                              ? Text(
                                  content,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : isTypewriter
                                  ? _TypewriterMarkdown(text: content, onComplete: onComplete)
                                  : MarkdownBody(
                                      data: content,
                                      styleSheet: MarkdownStyleSheet(
                                        p: AppTypography.bodyLarge.copyWith(
                                          color: colorScheme.onSurface,
                                          height: 1.5,
                                        ),
                                        strong: AppTypography.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                        listBullet: AppTypography.bodyLarge.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                        listIndent: 16.0,
                                      ),
                                    ),
                        ],
                      ),
                    ),
                    if (!isUserMessage && actions != null && actions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: actions!.map((action) => _ActionButton(action: action)).toList().cast<Widget>(),
                        ),
                      ),
                  ],
                ),
              ),
              if (isUserMessage) const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final AssistantAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppScaleTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        _handleAction(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIconForAction(action.type), size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAction(String type) {
    switch (type) {
      case 'add_to_diary': return LucideIcons.plusCircle;
      case 'show_recipe': return LucideIcons.chefHat;
      case 'navigate': return LucideIcons.arrowRight;
      default: return LucideIcons.externalLink;
    }
  }

  Future<void> _handleAction(BuildContext context) async {
    switch (action.type) {
      case 'add_to_diary':
        final data = action.data;
        if (data != null) {
          // Logic to add meal to repository via provider
          context.read<MealProvider>().addMeal(
            foodName: action.label.replaceFirst('Add ', ''),
            calories: data['calories'] as int? ?? 0,
            protein: data['protein'] as int? ?? 0,
            carbs: data['carbs'] as int? ?? 0,
            fat: data['fat'] as int? ?? 0,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to your diary! 🍎')),
          );
        }
        break;
      case 'update_setting':
        final key = action.data?['key'];
        final value = action.data?['value'];
        if (key != null && value != null) {
          final settings = context.read<SettingsProvider>();
          bool success = false;
          final numericValue = double.tryParse(value.toString()) ?? 0.0;
          
          if (key == 'calories') {
            await settings.updateCalorieGoal(numericValue.toInt());
            success = true;
          } else if (key == 'protein') {
            await settings.updateProteinGoal(numericValue.toInt());
            success = true;
          } else if (key == 'carbs') {
            await settings.updateCarbGoal(numericValue.toInt());
            success = true;
          } else if (key == 'fat') {
            await settings.updateFatGoal(numericValue.toInt());
            success = true;
          } else if (key == 'target_weight') {
            await settings.updateBodyProfile(targetWeight: numericValue);
            success = true;
          }

          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Plan updated: $key is now $value'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
        break;
      case 'navigate':
        final path = action.data?['path'] as String?;
        if (path != null) context.push(path);
        break;
      default:
        // Handle other actions
        break;
    }
  }
}

class _ThinkingPulse extends StatefulWidget {
  const _ThinkingPulse();

  @override
  State<_ThinkingPulse> createState() => _ThinkingPulseState();
}

class _ThinkingPulseState extends State<_ThinkingPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 60, bottom: 32),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: _pulse.value),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: _pulse.value * 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Coach is typing...',
            style: AppTypography.labelSmall.copyWith(
              color: context.textMutedColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypewriterMarkdown extends StatefulWidget {
  final String text;
  final VoidCallback onComplete;

  const _TypewriterMarkdown({required this.text, required this.onComplete});

  @override
  State<_TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends State<_TypewriterMarkdown> {
  int _displayedCharacters = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  void _animateText() async {
    const chunkSize = 12; // Print more characters at once
    while (_displayedCharacters < widget.text.length && mounted) {
      await Future.delayed(const Duration(milliseconds: 32)); // ~30 FPS instead of 80 FPS
      if (!mounted) return;
      
      setState(() {
        _displayedCharacters += chunkSize;
        if (_displayedCharacters >= widget.text.length) {
          _displayedCharacters = widget.text.length;
          _isComplete = true;
        }
      });
      
      // Throttle scroll updates to avoid animation thrashing
      if (_displayedCharacters % 48 < chunkSize) {
        widget.onComplete();
      }
    }
    
    if (mounted && _isComplete) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _displayedCharacters);
    
    return MarkdownBody(
      data: visibleText + (_isComplete ? '' : ' ▌'),
      styleSheet: MarkdownStyleSheet(
        p: AppTypography.bodyLarge.copyWith(
          color: context.textPrimaryColor.withValues(alpha: 0.9),
          height: 1.6,
        ),
        strong: AppTypography.bodyLarge.copyWith(
          color: context.textPrimaryColor,
          fontWeight: FontWeight.w800,
        ),
        listBullet: AppTypography.bodyLarge.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


