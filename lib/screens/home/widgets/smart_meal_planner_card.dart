import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E0FD),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C5FE0).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: -45,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
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
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Smart Meal Planner",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Text(
                                  "PRO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Optimized for your $goalKcal kcal goal · $dietLabel",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withValues(alpha: 0.80),
                        size: 20,
                      ),
                      onPressed: onRefreshTap,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's plan",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isTeaser
                          ? "2 of 4 suggestions unlocked"
                          : "$completedMeals of $totalMeals meals done",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
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
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (isTeaser
                                ? 0.5
                                : (completedMeals / (totalMeals > 0 ? totalMeals : 1)))
                            .clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
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

          const SizedBox(height: 12),

          // 3. Meal Slots List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: isTeaser
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Column(
                        children: [
                          if (meals.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildMealSlotRow(meals[0]),
                            ),
                          if (meals.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildMealSlotRow(meals[1]),
                            ),
                          ClipRect(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                              child: Opacity(
                                opacity: 0.25,
                                child: AbsorbPointer(
                                  child: Column(
                                    children: List.generate(
                                      meals.length > 2 ? meals.length - 2 : 0,
                                      (index) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: index == meals.length - 3 ? 0.0 : 8.0,
                                        ),
                                        child: _buildMealSlotRow(meals[index + 2]),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.70),
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_rounded,
                                    color: Color(0xFF7C3AED),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "Unlock Lunch & Dinner Plans",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Get the full 4-meal daily schedule personalized for you",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
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
                                      colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF5C5FE0).withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Unlock with SnapCal Pro",
                                      style: TextStyle(
                                        color: Colors.white,
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
                        child: _buildMealSlotRow(slot),
                      );
                    }),
                  ),
          ),

          const SizedBox(height: 12),

          // 4. Action Buttons Row
          if (!isTeaser) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: AppScaleTap(
                      onTap: onLogTap,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Log this meal",
                              style: TextStyle(
                                color: Colors.white,
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
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMealSlotRow(MealSlot slot) {
    Color bg;
    Border? border;
    Decoration? iconDecoration;
    IconData iconData;
    Color iconColor;
    Color nameColor = AppColors.textPrimary;
    Color metaColor = AppColors.textSecondary;
    Color kcalColor = AppColors.textPrimary;
    bool isBoldName = false;
    bool isBoldKcal = false;
    List<BoxShadow>? rowShadows;

    // Determine metadata text
    String meta;
    if (slot.status == MealSlotStatus.done) {
      bg = AppColors.slotDoneBg;
      border = Border.all(color: const Color(0xFFEEF0FF), width: 1.0);
      iconDecoration = BoxDecoration(
        color: const Color(0xFFE0E0FD),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.check_rounded;
      iconColor = AppColors.primary;
      meta = "${slot.mealType} · ${slot.time} · Logged";
    } else if (slot.status == MealSlotStatus.next) {
      bg = AppColors.slotNextBg;
      border = Border.all(color: const Color(0xFFC7C9F8), width: 1.5);
      iconDecoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C5FE0), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.restaurant_rounded;
      iconColor = Colors.white;
      nameColor = AppColors.primary;
      metaColor = AppColors.primaryDark;
      kcalColor = AppColors.primary;
      isBoldName = true;
      isBoldKcal = true;
      meta = "${slot.mealType} · ${slot.time} · 380 kcal left after";
      rowShadows = [
        BoxShadow(
          color: const Color(0xFF5C5FE0).withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      bg = AppColors.slotUpcomingBg.withValues(alpha: 0.7);
      iconDecoration = BoxDecoration(
        color: const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(10),
      );
      iconData = Icons.nightlight_round;
      iconColor = const Color(0xFF888888);
      meta = "${slot.mealType} · ${slot.time} · Planned";
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
            child: Center(
              child: Icon(
                iconData,
                color: iconColor,
                size: 18,
              ),
            ),
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
    return AppScaleTap(
      onTap: _handleTap,
      child: Container(
        width: 80,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              "Swap",
              style: TextStyle(
                color: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E0FD),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0FD).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFE0B2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.lightbulb_rounded,
                color: Color(0xFFBA7517),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "On track for your goal",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "You're hitting 92g protein today. Add 10g more at dinner to reach your target. Try Greek yogurt as a side.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
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
