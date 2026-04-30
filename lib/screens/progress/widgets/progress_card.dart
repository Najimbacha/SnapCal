import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

class ProgressCard extends StatelessWidget {
  final dynamic metric;
  final VoidCallback? onCompare;

  const ProgressCard({super.key, required this.metric, this.onCompare});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(metric.date);
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${metric.weight.toStringAsFixed(1)} kg',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (metric.photoFrontPath != null)
                Expanded(child: _PhotoThumbnail(path: metric.photoFrontPath!, label: 'Front')),
              if (metric.photoFrontPath != null && metric.photoSidePath != null)
                const SizedBox(width: 12),
              if (metric.photoSidePath != null)
                Expanded(child: _PhotoThumbnail(path: metric.photoSidePath!, label: 'Side')),
            ],
          ),
          if (onCompare != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCompare,
              icon: const Icon(LucideIcons.slidersHorizontal, size: 16),
              label: const Text('Compare with previous'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final String label;

  const _PhotoThumbnail({required this.path, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 3/4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(color: context.textSecondaryColor),
        )
      ],
    );
  }
}
