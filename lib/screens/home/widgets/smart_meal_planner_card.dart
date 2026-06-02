import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/models/meal_slot.dart';
import '../../../widgets/ui_blocks.dart';

class SmartMealPlannerCard extends StatelessWidget {
  final int goalKcal;
  final String dietLabel;
  final int completedMeals;
  final int totalMeals;
  final List<MealSlot> meals;
  final VoidCallback onLogTap;
  final VoidCallback onSwapTap;
  final VoidCallback onRefreshTap;
  final bool isTeaser;

  const SmartMealPlannerCard({
    super.key,
    required this.goalKcal,
    required this.dietLabel,
    required this.completedMeals,
    required this.totalMeals,
    required this.meals,
    required this.onLogTap,
    required this.onSwapTap,
    required this.onRefreshTap,
    this.isTeaser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    // Theme-aware styles
    final Color cardBgColor;
    final Color borderColor;
    final List<BoxShadow> cardShadow;
    final LinearGradient headerGradient;
    final Color headerBorderColor;
    final Color titleColor;
    final Color subtitleColor;
    final Color progressTrackColor;
    final Color labelColor;
    final Color refreshBtnBg;
    final Color refreshIconColor;

    if (isDark) {
      cardBgColor = const Color(0xFF0B2114); // Deep Forest Green
      borderColor = goldColor.withValues(alpha: 0.35);
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];
      headerGradient = const LinearGradient(
        colors: [Color(0xFF163E27), Color(0xFF0B2114)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      headerBorderColor = const Color(0x33D4AF37);
      titleColor = const Color(0xFFFAF8F5);
      subtitleColor = const Color(0xFFBDD2C6);
      progressTrackColor = const Color(0xFF143020);
      labelColor = const Color(0xFFBDD2C6);
      refreshBtnBg = const Color(0xFF143A24);
      refreshIconColor = goldColor;
    } else {
      cardBgColor = const Color(0xFFFFFFFF); // Pure White
      borderColor = const Color(0xFFEFEBE4); // Champagne/light border
      cardShadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
      headerGradient = const LinearGradient(
        colors: [Color(0xFFFCF8EF), Color(0xFFFAF2E6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      headerBorderColor = const Color(0xFFEFEBE4);
      titleColor = const Color(0xFF1A1A2E); // Charcoal
      subtitleColor = const Color(0xFF788C80); // Muted sage
      progressTrackColor = const Color(0xFFF1F3F5); // Light grey track
      labelColor = const Color(0xFF788C80);
      refreshBtnBg = const Color(0xFFFCF8EF);
      refreshIconColor = const Color(0xFFBA7517); // Rich gold/amber
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: headerGradient,
              border: Border(
                bottom: BorderSide(color: headerBorderColor, width: 1.0),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -30,
                  top: -35,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : const Color(0xFFFAF2E6).withValues(alpha: 0.2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color:
                                    isDark
                                        ? goldColor
                                        : const Color(0xFFBA7517),
                                size: 15,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Smart Meal Planner",
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE5C060),
                                      Color(0xFFB88E2F),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldColor.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Optimized for your $goalKcal kcal goal · $dietLabel",
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: refreshIconColor,
                        size: 20,
                      ),
                      onPressed: onRefreshTap,
                      style: IconButton.styleFrom(
                        backgroundColor: refreshBtnBg,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Progress Bar Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's plan",
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isTeaser
                          ? "2 of 4 suggestions unlocked"
                          : "$completedMeals of $totalMeals meals done",
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: progressTrackColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (isTeaser
                                ? 0.5
                                : (completedMeals /
                                    (totalMeals > 0 ? totalMeals : 1)))
                            .clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5C060), Color(0xFFD4AF37)],
                            ),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Meal Slots List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child:
                isTeaser
                    ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Column(
                          children: [
                            if (meals.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildMealSlotRow(context, meals[0]),
                              ),
                            if (meals.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildMealSlotRow(context, meals[1]),
                              ),
                            ClipRect(
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: 5.5,
                                  sigmaY: 5.5,
                                ),
                                child: Opacity(
                                  opacity: 0.20,
                                  child: AbsorbPointer(
                                    child: Column(
                                      children: List.generate(
                                        meals.length > 2 ? meals.length - 2 : 0,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                            bottom:
                                                index == meals.length - 3
                                                    ? 0.0
                                                    : 8.0,
                                          ),
                                          child: _buildMealSlotRow(
                                            context,
                                            meals[index + 2],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Upgrade Nudge Overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isDark
                                        ? [
                                          const Color(
                                            0xFF0B2114,
                                          ).withValues(alpha: 0.70),
                                          const Color(
                                            0xFF0B2114,
                                          ).withValues(alpha: 0.95),
                                          const Color(0xFF0B2114),
                                        ]
                                        : [
                                          Colors.white.withValues(alpha: 0.70),
                                          Colors.white.withValues(alpha: 0.95),
                                          Colors.white,
                                        ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_rounded,
                                      color:
                                          isDark
                                              ? goldColor
                                              : const Color(0xFFBA7517),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Unlock Lunch & Dinner Plans",
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? const Color(0xFFFAF8F5)
                                                : const Color(0xFF1A3D2B),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Get the full 4-meal daily schedule personalized for you",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? const Color(0xFFBDD2C6)
                                            : const Color(0xFF788C80),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppScaleTap(
                                  onTap: onLogTap,
                                  child: Container(
                                    width: double.infinity,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE5C060),
                                          Color(0xFFB88E2F),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: goldColor.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "Unlock with SnapCal Pro",
                                        style: TextStyle(
                                          color: Color(
                                            0xFF0A2114,
                                          ), // Forest text
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: List.generate(meals.length, (index) {
                        final slot = meals[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == meals.length - 1 ? 0.0 : 8.0,
                          ),
                          child: _buildMealSlotRow(context, slot),
                        );
                      }),
                    ),
          ),

          const SizedBox(height: 14),

          // 4. Action Buttons Row
          if (!isTeaser) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: AppScaleTap(
                      onTap: onLogTap,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: goldColor.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF0A2114),
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Log this meal",
                              style: TextStyle(
                                color: Color(0xFF0A2114),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SwapButton(onTap: onSwapTap),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSlotRow(BuildContext context, MealSlot slot) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Border? border;
    Decoration? iconDecoration;
    IconData iconData;
    Color iconColor;
    const goldColor = Color(0xFFD4AF37);
    Color nameColor;
    Color metaColor;
    Color kcalColor;
    bool isBoldName = false;
    bool isBoldKcal = false;
    List<BoxShadow>? rowShadows;

    String meta;
    if (slot.status == MealSlotStatus.done) {
      bg = isDark ? const Color(0xFF0D2517) : const Color(0xFFF2FDF4);
      border = Border.all(
        color: isDark ? const Color(0xFF1C462E) : const Color(0xFFD4ECD8),
        width: 1.0,
      );
      iconDecoration = BoxDecoration(
        color: isDark ? const Color(0xFF1C462E) : const Color(0xFFE2EFE0),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.check_rounded;
      iconColor = isDark ? goldColor : const Color(0xFF1E4620);
      meta = "${slot.mealType} · ${slot.time} · Logged";
      nameColor = isDark ? const Color(0xFFFAF8F5) : const Color(0xFF1A1A2E);
      metaColor = isDark ? const Color(0xFFBDD2C6) : const Color(0xFF788C80);
      kcalColor = nameColor;
    } else if (slot.status == MealSlotStatus.next) {
      bg = isDark ? const Color(0xFF123421) : const Color(0xFFFCF8EF);
      border = Border.all(
        color: goldColor.withValues(alpha: isDark ? 0.5 : 0.6),
        width: 1.4,
      );
      iconDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE5C060), Color(0xFFB88E2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.restaurant_rounded;
      iconColor = const Color(0xFF0A2114);
      nameColor = isDark ? const Color(0xFFE5C060) : const Color(0xFFBA7517);
      metaColor = isDark ? const Color(0xFFE3D0A4) : const Color(0xFF888780);
      kcalColor = nameColor;
      isBoldName = true;
      isBoldKcal = true;
      meta = "${slot.mealType} · ${slot.time} · Up Next";
      rowShadows = [
        BoxShadow(
          color: goldColor.withValues(alpha: isDark ? 0.10 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    } else {
      bg = isDark ? const Color(0xFF0A1D13) : const Color(0xFFF9FAFB);
      border = Border.all(
        color: isDark ? const Color(0xFF153322) : const Color(0xFFE2E8F0),
        width: 1.0,
      );
      iconDecoration = BoxDecoration(
        color: isDark ? const Color(0xFF153322) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.nightlight_round;
      iconColor = isDark ? const Color(0xFF8BA596) : const Color(0xFF64748B);
      meta = "${slot.mealType} · ${slot.time} · Planned";
      nameColor = isDark ? const Color(0xFFDCD8D3) : const Color(0xFF334155);
      metaColor = isDark ? const Color(0xFF8BA596) : const Color(0xFF64748B);
      kcalColor = nameColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: border,
        borderRadius: BorderRadius.circular(12),
        boxShadow: rowShadows,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: iconDecoration,
            child: Center(child: Icon(iconData, color: iconColor, size: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.name,
                  style: TextStyle(
                    color: nameColor,
                    fontWeight: isBoldName ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    color: metaColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${slot.kcal} kcal",
            style: TextStyle(
              color: kcalColor,
              fontWeight: isBoldKcal ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwapButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SwapButton({required this.onTap});

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_controller.isAnimating) return;
    _controller.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    return AppScaleTap(
      onTap: _handleTap,
      child: Container(
        width: 80,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF123220) : const Color(0xFFFCF8EF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark
                    ? goldColor.withValues(alpha: 0.35)
                    : const Color(0xFFE5C060).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.refresh_rounded,
                color: isDark ? goldColor : const Color(0xFFBA7517),
                size: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "Swap",
              style: TextStyle(
                color: isDark ? goldColor : const Color(0xFFBA7517),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MacroInsightCard extends StatelessWidget {
  const MacroInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);

    final Color cardBg;
    final Color borderColor;
    final Color textColor;
    final Color highlightColor;
    final Color iconBg;
    final Color iconColor;
    final List<BoxShadow> shadow;

    if (isDark) {
      cardBg = const Color(0xFF0B2114);
      borderColor = goldColor.withValues(alpha: 0.35);
      textColor = const Color(0xFFFAF8F5);
      highlightColor = goldColor;
      iconBg = const Color(0xFF1C462E);
      iconColor = goldColor;
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      cardBg = const Color(0xFFFFFFFF);
      borderColor = const Color(0xFFEFEBE4);
      textColor = const Color(0xFF1A1A2E);
      highlightColor = const Color(0xFFBA7517);
      iconBg = const Color(0xFFFCF8EF);
      iconColor = const Color(0xFFBA7517);
      shadow = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: shadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isDark
                        ? goldColor.withValues(alpha: 0.30)
                        : const Color(0xFFFAF2E6),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(Icons.lightbulb_rounded, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "On track for your goal",
                  style: TextStyle(
                    color: highlightColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You're hitting 92g protein today. Add 10g more at dinner to reach your target. Try Greek yogurt as a side.",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
