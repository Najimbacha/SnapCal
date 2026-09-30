import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/theme_colors.dart';
import '../onboarding_draft.dart';

/// The pictures on the onboarding choice cards: unDraw illustrations
/// (https://undraw.co, free for commercial use, no credit needed).
///
/// unDraw draws every picture in one accent colour, `#6c63ff`. It is swapped
/// for the app's own primary at draw time, so the pictures follow the theme in
/// light and dark and always match the screen.
const _unDrawAccent = Color(0xFF6C63FF);
const _dir = 'assets/illustrations/onboarding';

class _AccentMapper extends ColorMapper {
  const _AccentMapper(this.accent);

  final Color accent;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => color == _unDrawAccent ? accent : color;

  @override
  bool operator ==(Object other) =>
      other is _AccentMapper && other.accent == accent;

  @override
  int get hashCode => accent.hashCode;
}

/// One picture, recoloured, that grows a little when its card is picked.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.name,
    required this.selected,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  final String name;
  final bool selected;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedScale(
        scale: selected ? 1.05 : 1,
        alignment: alignment,
        duration: AppMotion.maybeZero(
          context,
          const Duration(milliseconds: 420),
        ),
        curve: AppMotion.springCurve,
        child: SvgPicture.asset(
          '$_dir/$name.svg',
          width: width,
          height: height,
          alignment: alignment,
          fit: BoxFit.contain,
          colorMapper: _AccentMapper(context.primaryColor),
        ),
      ),
    );
  }
}

/// Female or male.
class OnbSexArt extends StatelessWidget {
  const OnbSexArt({
    super.key,
    required this.sex,
    required this.selected,
    this.size = 104,
  });

  final BiologicalSex sex;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => _Picture(
    name: sex == BiologicalSex.female ? 'sex_female' : 'sex_male',
    selected: selected,
    width: size,
    height: size,
  );
}

/// The four goals.
class OnbGoalArt extends StatelessWidget {
  const OnbGoalArt({
    super.key,
    required this.goal,
    required this.selected,
    this.height = 92,
    this.alignment = Alignment.centerLeft,
  });

  final GoalType goal;
  final bool selected;
  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: _Picture(
      name: switch (goal) {
        GoalType.loseWeight => 'goal_lose',
        GoalType.maintainWeight => 'goal_maintain',
        GoalType.buildMuscle => 'goal_build',
        GoalType.trackNutrition => 'goal_track',
      },
      selected: selected,
      alignment: alignment,
    ),
  );
}

/// How active a normal week is.
class OnbActivityArt extends StatelessWidget {
  const OnbActivityArt({
    super.key,
    required this.level,
    required this.selected,
    this.size = 72,
  });

  final ActivityLevel level;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: _Picture(
      name: switch (level) {
        ActivityLevel.mostlySitting => 'act_sitting',
        ActivityLevel.lightlyActive => 'act_light',
        ActivityLevel.active => 'act_active',
        ActivityLevel.veryActive => 'act_very',
      },
      selected: selected,
    ),
  );
}
