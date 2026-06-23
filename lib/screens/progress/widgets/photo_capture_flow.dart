import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapcal/l10n/generated/app_localizations.dart';

import '../../../core/resilience/timeout_policy.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/app_page_scaffold.dart';

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

      if (file != null && await File(file.path).exists()) {
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
      if (_frontPath != null && await File(_frontPath!).exists()) {
        await metricsProvider.logProgressPhoto(_frontPath!);
      }

      if (_sidePath != null && await File(_sidePath!).exists()) {
        await metricsProvider.logProgressPhoto(_sidePath!);
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
                  child: _CaptureSlot(
                    title: AppLocalizations.of(context)!.progress_front_view,
                    path: _frontPath,
                    onTap: _isPicking ? null : () => _takePhoto(true),
                    onClear: () => setState(() => _frontPath = null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CaptureSlot(
                    title: AppLocalizations.of(context)!.progress_side_view,
                    path: _sidePath,
                    onTap: _isPicking ? null : () => _takePhoto(false),
                    onClear: () => setState(() => _sidePath = null),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed:
                  (_frontPath != null || _sidePath != null) && !_isSaving
                      ? _save
                      : null,
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Icon(LucideIcons.check),
              label: Text(
                _isSaving
                    ? AppLocalizations.of(context)!.progress_saving
                    : AppLocalizations.of(context)!.progress_save_progress,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
            child: Container(
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
                              LucideIcons.camera,
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
                            child:
                                File(path!).existsSync()
                                    ? Image.file(File(path!), fit: BoxFit.cover)
                                    : const Center(
                                      child: Icon(LucideIcons.imageOff),
                                    ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton.filled(
                              onPressed: onClear,
                              icon: Icon(LucideIcons.x, size: 16),
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

