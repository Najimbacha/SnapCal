import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/theme_colors.dart';

/// Performance-tuned glass container widget.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor ?? context.glassBackgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor ?? context.glassBorderColor,
                  width: 1.0, // Thinner border for better sub-pixel rendering
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
