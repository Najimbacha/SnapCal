import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../providers/metrics_provider.dart';
import '../../../widgets/app_page_scaffold.dart';

class PhotoCaptureFlow extends StatefulWidget {
  const PhotoCaptureFlow({super.key});

  @override
  State<PhotoCaptureFlow> createState() => _PhotoCaptureFlowState();
}

class _PhotoCaptureFlowState extends State<PhotoCaptureFlow> {
  final ImagePicker _picker = ImagePicker();
  String? _frontPath;
  String? _sidePath;
  bool _isSaving = false;

  Future<void> _takePhoto(bool isFront) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (file != null) {
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
          const SnackBar(content: Text('Failed to open camera.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_frontPath == null && _sidePath == null) return;
    
    setState(() => _isSaving = true);
    
    final metricsProvider = context.read<MetricsProvider>();
    
    // Save front if taken
    if (_frontPath != null) {
      await metricsProvider.logProgressPhoto(_frontPath!, isFront: true);
    }
    
    // Save side if taken
    if (_sidePath != null) {
      await metricsProvider.logProgressPhoto(_sidePath!, isFront: false);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Log Progress',
      subtitle: 'Take photos to track your journey.',
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _CaptureSlot(
                    title: 'Front View',
                    path: _frontPath,
                    onTap: () => _takePhoto(true),
                    onClear: () => setState(() => _frontPath = null),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CaptureSlot(
                    title: 'Side View',
                    path: _sidePath,
                    onTap: () => _takePhoto(false),
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
              onPressed: (_frontPath != null || _sidePath != null) && !_isSaving ? _save : null,
              icon: _isSaving 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Progress'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _CaptureSlot({required this.title, required this.path, required this.onTap, required this.onClear});

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
                  color: path == null ? Theme.of(context).colorScheme.outlineVariant : AppColors.primary,
                  width: 2,
                ),
              ),
              child: path == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.camera, size: 32, color: context.textSecondaryColor),
                          const SizedBox(height: 8),
                          Text('Tap to snap', style: AppTypography.labelMedium.copyWith(color: context.textSecondaryColor)),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(File(path!), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: IconButton.filled(
                            onPressed: onClear,
                            icon: const Icon(LucideIcons.x, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.6),
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
