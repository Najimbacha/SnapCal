import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/wazn_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/resilience/timeout_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/app_page_scaffold.dart';
import '../../../widgets/motion/reveal.dart';
import '../../../widgets/motion/lift_when_ready.dart';

class PhotoCaptureFlow extends ConsumerStatefulWidget {
  const PhotoCaptureFlow({super.key});

  @override
  ConsumerState<PhotoCaptureFlow> createState() => _PhotoCaptureFlowState();
}

class _PhotoCaptureFlowState extends ConsumerState<PhotoCaptureFlow> {
  final ImagePicker _picker = ImagePicker();
  String? _frontPath;
  String? _sidePath;
  bool _isSaving = false;
  bool _isPicking = false;

  /// Saved: the button shows a tick before the screen goes.
  bool _saved = false;

  Future<void> _takePhoto(bool isFront) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final XFile? file = await _picker
          .pickImage(
            source: ImageSource.camera,
            preferredCameraDevice: CameraDevice.front,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          )
          .timeout(TimeoutPolicy.gallery);

      // The camera and the file check are both awaits, so this screen can be
      // gone by the time they return. The catch and finally below already
      // guard; this did not.
      if (!mounted) return;
      if (file != null && await File(file.path).exists()) {
        if (!mounted) return;
        setState(() {
          if (isFront) {
            _frontPath = file.path;
          } else {
            _sidePath = file.path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.progress_failed_camera),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || (_frontPath == null && _sidePath == null)) return;

    setState(() => _isSaving = true);

    final metricsProvider = ref.read(bodyMetricsProvider.notifier);
    try {
      final front = _frontPath;
      final side = _sidePath;
      // Both photos are one check-in, saved together: the front and side of
      // the same day belong to the same entry.
      await metricsProvider.logProgressPhotos(
        frontPath: front != null && await File(front).exists() ? front : null,
        sidePath: side != null && await File(side).exists() ? side : null,
      );

      if (!mounted) return;
      if (!AppMotion.reduceMotion(context)) {
        HapticFeedback.lightImpact();
        setState(() => _saved = true);
        await Future<void>.delayed(const Duration(milliseconds: 480));
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.progress_failed_camera),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: AppLocalizations.of(context)!.progress_log_progress,
      subtitle: AppLocalizations.of(context)!.progress_take_photos_desc,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Reveal(
                    delay: const Duration(milliseconds: 120),
                    offset: const Offset(0, 26),
                    child: _CaptureSlot(
                      title: AppLocalizations.of(context)!.progress_front_view,
                      path: _frontPath,
                      onTap: _isPicking ? null : () => _takePhoto(true),
                      onClear: () => setState(() => _frontPath = null),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Reveal(
                    delay: const Duration(milliseconds: 210),
                    offset: const Offset(0, 26),
                    child: _CaptureSlot(
                      title: AppLocalizations.of(context)!.progress_side_view,
                      path: _sidePath,
                      onTap: _isPicking ? null : () => _takePhoto(false),
                      onClear: () => setState(() => _sidePath = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Reveal(
            delay: const Duration(milliseconds: 320),
            offset: const Offset(0, 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LiftWhenReady(
                ready: _frontPath != null || _sidePath != null,
                child: FilledButton(
                  onPressed:
                      (_frontPath != null || _sidePath != null) &&
                              !_isSaving &&
                              !_saved
                          ? _save
                          : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    transitionBuilder:
                        (child, animation) => ScaleTransition(
                          scale: CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.springCurve,
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                    child:
                        _saved
                            ? const Icon(
                              WaznIcons.check,
                              key: ValueKey('photos-saved'),
                              size: 24,
                            )
                            : Row(
                              key: ValueKey('photos-saving-$_isSaving'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isSaving
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(WaznIcons.check),
                                const SizedBox(width: 8),
                                Text(
                                  _isSaving
                                      ? AppLocalizations.of(
                                        context,
                                      )!.progress_saving
                                      : AppLocalizations.of(
                                        context,
                                      )!.progress_save_progress,
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CaptureSlot extends StatelessWidget {
  final String title;
  final String? path;
  final VoidCallback? onTap;
  final VoidCallback onClear;

  const _CaptureSlot({
    required this.title,
    required this.path,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: AppTypography.labelLarge),
        const SizedBox(height: 12),
        Expanded(
          child: GestureDetector(
            onTap: path == null ? onTap : null,
            child: AnimatedContainer(
              duration: AppMotion.maybeZero(
                context,
                const Duration(milliseconds: 350),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      path == null
                          ? Theme.of(context).colorScheme.outlineVariant
                          : AppColors.primary,
                  width: 2,
                ),
              ),
              child:
                  path == null
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              WaznIcons.camera,
                              size: 32,
                              color: context.textSecondaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.progress_tap_to_snap,
                              style: AppTypography.labelMedium.copyWith(
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                      : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _Develop(
                              key: ValueKey(path),
                              child:
                                  File(path!).existsSync()
                                      ? Image.file(
                                        File(path!),
                                        fit: BoxFit.cover,
                                      )
                                      : const Center(
                                        child: Icon(WaznIcons.imageOff),
                                      ),
                            ),
                          ),
                          // A tick lands once the photo has come through.
                          PositionedDirectional(
                            start: 8,
                            bottom: 8,
                            child: Reveal(
                              key: ValueKey('tick $path'),
                              delay: const Duration(milliseconds: 650),
                              offset: Offset.zero,
                              scale: 0,
                              curve: AppMotion.springCurve,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  WaznIcons.check,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              onPressed: onClear,
                              icon: Icon(WaznIcons.close, size: 16),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.6,
                                ),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(32, 32),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A photo coming through like a print developing: a flash, then from pale,
/// grey and soft to sharp and in colour.
class _Develop extends StatelessWidget {
  const _Develop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.maybeZero(
        context,
        const Duration(milliseconds: 1100),
      ),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        if (t >= 1) return child!;
        final grey = 1 - t;
        // Mixes each channel towards the pixel's grey by [grey].
        final r = .2126 * grey, g = .7152 * grey, b = .0722 * grey;
        final keep = 1 - grey;
        final lift = 90 * grey;
        final flash = t < .2 ? 1 - t / .2 : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 12 * grey,
                sigmaY: 12 * grey,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  r + keep, g, b, 0, lift, //
                  r, g + keep, b, 0, lift, //
                  r, g, b + keep, 0, lift, //
                  0, 0, 0, 1, 0,
                ]),
                child: Opacity(opacity: math.min(1, .4 + .6 * t), child: child),
              ),
            ),
            if (flash > 0)
              ColoredBox(color: Colors.white.withValues(alpha: .9 * flash)),
          ],
        );
      },
      child: child,
    );
  }
}
