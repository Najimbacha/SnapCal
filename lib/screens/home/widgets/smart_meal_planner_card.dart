import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../data/models/meal_slot.dart';
import '../../../core/theme/app_colors.dart';
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
    final p = AppColors.primary;

    final cardBg = isDark ? const Color(0xFF121218) : const Color(0xFFFFFFFF);
    final border = isDark ? p.withValues(alpha: 0.25) : const Color(0xFFE2E8F0);
    final headerGrad = isDark
        ? LinearGradient(colors: [p.withValues(alpha: 0.12), const Color(0xFF121218)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : LinearGradient(colors: [p.withValues(alpha: 0.04), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight);
    final headerBorder = isDark ? p.withValues(alpha: 0.15) : const Color(0xFFE2E8F0);
    final titleC = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final subtitleC = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
    final trackC = isDark ? const Color(0xFF1A1A22) : const Color(0xFFF1F5F9);
    final refreshBg = isDark ? const Color(0xFF1A1A24) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05), blurRadius: isDark ? 20 : 18, offset: Offset(0, isDark ? 10 : 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(gradient: headerGrad, border: Border(bottom: BorderSide(color: headerBorder))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: p, size: 15),
                          const SizedBox(width: 8),
                          Text("Smart Meal Planner", style: TextStyle(color: titleC, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [p, p.withValues(alpha: 0.8)]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("PRO", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Optimized for your $goalKcal kcal goal \u00b7 $dietLabel", style: TextStyle(color: subtitleC, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: p, size: 20),
                  onPressed: onRefreshTap,
                  style: IconButton.styleFrom(backgroundColor: refreshBg, padding: const EdgeInsets.all(8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's plan", style: TextStyle(color: subtitleC, fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(isTeaser ? "2 of 4 suggestions unlocked" : "$completedMeals of $totalMeals meals done", style: TextStyle(color: subtitleC, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6, width: double.infinity,
                  decoration: BoxDecoration(color: trackC, borderRadius: BorderRadius.circular(99)),
                  child: FractionallySizedBox(
                    widthFactor: (isTeaser ? 0.5 : (completedMeals / (totalMeals > 0 ? totalMeals : 1))).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [p, p.withValues(alpha: 0.6)]),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Meal slots
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: isTeaser ? _buildTeaser(context, p) : Column(children: List.generate(meals.length, (i) => Padding(padding: EdgeInsets.only(bottom: i == meals.length - 1 ? 0 : 8), child: _buildMealSlot(context, meals[i], p)))),
          ),
          const SizedBox(height: 14),
          // Actions
          if (!isTeaser)
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
                          gradient: LinearGradient(colors: [p, p.withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            const Text("Log this meal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SwapButton(onTap: onSwapTap, primary: p),
                ],
              ),
            ),
          if (!isTeaser) const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildTeaser(BuildContext context, Color p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            if (meals.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildMealSlot(context, meals[0], p)),
            if (meals.length > 1) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildMealSlot(context, meals[1], p)),
            if (meals.length > 2)
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
                  child: Opacity(
                    opacity: 0.2,
                    child: AbsorbPointer(
                      child: Column(children: List.generate(meals.length - 2, (i) => Padding(padding: EdgeInsets.only(bottom: i == meals.length - 3 ? 0 : 8), child: _buildMealSlot(context, meals[i + 2], p)))),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF121218).withValues(alpha: 0.7), const Color(0xFF121218).withValues(alpha: 0.95), const Color(0xFF121218)]
                    : [Colors.white.withValues(alpha: 0.7), Colors.white.withValues(alpha: 0.95), Colors.white],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: p, size: 15),
                    const SizedBox(width: 8),
                    Text("Unlock Full Meal Plans", style: TextStyle(color: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Get the complete daily schedule personalized for you", textAlign: TextAlign.center, style: TextStyle(color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                AppScaleTap(
                  onTap: onLogTap,
                  child: Container(
                    width: double.infinity, height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [p, p.withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("Unlock with SnapCal Pro", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSlot(BuildContext context, MealSlot slot, Color p) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    BorderSide border;
    Decoration iconDeco;
    IconData icon;
    Color iconC, nameC, metaC, kcalC;
    bool bold = false;
    String meta;

    if (slot.status == MealSlotStatus.done) {
      bg = isDark ? const Color(0xFF0F0F18) : const Color(0xFFF8FAFC);
      border = BorderSide(color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFE2E8F0));
      iconDeco = BoxDecoration(color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10));
      icon = Icons.check_rounded;
      iconC = p;
      nameC = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
      metaC = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
      kcalC = nameC;
      meta = "${slot.mealType} \u00b7 ${slot.time} \u00b7 Logged";
    } else if (slot.status == MealSlotStatus.next) {
      bg = isDark ? const Color(0xFF1A1A28) : const Color(0xFFF8FAFF);
      border = BorderSide(color: p.withValues(alpha: isDark ? 0.4 : 0.5), width: 1.4);
      iconDeco = BoxDecoration(
        gradient: LinearGradient(colors: [p, p.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(10),
      );
      icon = Icons.restaurant_rounded;
      iconC = Colors.white;
      nameC = p;
      metaC = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
      kcalC = p;
      bold = true;
      meta = "${slot.mealType} \u00b7 ${slot.time} \u00b7 Up Next";
    } else {
      bg = isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF9FAFB);
      border = BorderSide(color: isDark ? const Color(0xFF1A1A22) : const Color(0xFFE2E8F0));
      iconDeco = BoxDecoration(color: isDark ? const Color(0xFF1A1A22) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10));
      icon = Icons.nightlight_round;
      iconC = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);
      nameC = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF334155);
      metaC = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF64748B);
      kcalC = nameC;
      meta = "${slot.mealType} \u00b7 ${slot.time} \u00b7 Planned";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, border: Border(top: border, bottom: border, left: border, right: border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: iconDeco, child: Center(child: Icon(icon, color: iconC, size: 18))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.name, style: TextStyle(color: nameC, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(color: metaC, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text("${slot.kcal} kcal", style: TextStyle(color: kcalC, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SwapButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color primary;
  const _SwapButton({required this.onTap, required this.primary});

  @override
  State<_SwapButton> createState() => _SwapButtonState();
}

class _SwapButtonState extends State<_SwapButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600)); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() { if (!_ctrl.isAnimating) { _ctrl.forward(from: 0); widget.onTap(); } }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaleTap(
      onTap: _handleTap,
      child: Container(
        width: 80, height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.primary.withValues(alpha: isDark ? 0.3 : 0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(turns: _ctrl, child: Icon(Icons.refresh_rounded, color: widget.primary, size: 16)),
            const SizedBox(width: 4),
            Text("Swap", style: TextStyle(color: widget.primary, fontWeight: FontWeight.w600, fontSize: 13)),
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
    final p = AppColors.primary;
    final cardBg = isDark ? const Color(0xFF121218) : const Color(0xFFFFFFFF);
    final borderC = isDark ? p.withValues(alpha: 0.25) : const Color(0xFFE2E8F0);
    final textC = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final iconBg = isDark ? const Color(0xFF1A1A24) : const Color(0xFFF8FAFC);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: borderC), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 16, offset: const Offset(0, 8))]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: p.withValues(alpha: 0.2))),
            child: Center(child: Icon(Icons.lightbulb_rounded, color: p, size: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("On track for your goal", style: TextStyle(color: p, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Text("You're hitting 92g protein today. Add 10g more at dinner to reach your target. Try Greek yogurt as a side.", style: TextStyle(color: textC, fontSize: 11, height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
