import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/app_colors.dart';

class PhotoComparisonSheet extends StatefulWidget {
  final dynamic current;
  final dynamic previous;

  const PhotoComparisonSheet({
    super.key,
    required this.current,
    required this.previous,
  });

  @override
  State<PhotoComparisonSheet> createState() => _PhotoComparisonSheetState();
}

class _PhotoComparisonSheetState extends State<PhotoComparisonSheet> {
  double _sliderPosition = 0.5;
  bool _showSide = false;

  String? get _currentPhoto => _showSide ? widget.current.photoSidePath : widget.current.photoFrontPath;
  String? get _previousPhoto => _showSide ? widget.previous.photoSidePath : widget.previous.photoFrontPath;

  @override
  Widget build(BuildContext context) {
    final hasBothFront = widget.current.photoFrontPath != null && widget.previous.photoFrontPath != null;
    final hasBothSide = widget.current.photoSidePath != null && widget.previous.photoSidePath != null;
    
    // Automatically fallback if the selected view doesn't exist
    if (_showSide && !hasBothSide) _showSide = false;
    if (!_showSide && !hasBothFront && hasBothSide) _showSide = true;

    final canCompare = _currentPhoto != null && _previousPhoto != null;
    final weightDiff = widget.current.weight - widget.previous.weight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Comparison', style: AppTypography.heading3),
                    const SizedBox(height: 2),
                    Text(
                      '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg difference',
                      style: AppTypography.bodySmall.copyWith(
                        color: weightDiff <= 0 ? AppColors.protein : AppColors.fat,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (hasBothFront && hasBothSide)
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Front')),
                      ButtonSegment(value: true, label: Text('Side')),
                    ],
                    selected: {_showSide},
                    onSelectionChanged: (set) => setState(() => _showSide = set.first),
                    style: SegmentedButton.styleFrom(
                      textStyle: AppTypography.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          if (!canCompare)
            _buildMissingPhotos(context)
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSlider(context),
              ),
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _sliderPosition += details.delta.dx / width;
                _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
              });
            },
            child: Stack(
              children: [
                // After (Current) - Bottom layer
                Positioned.fill(
                  child: Image.file(
                    File(_currentPhoto!),
                    fit: BoxFit.cover,
                  ),
                ),
                // Before (Previous) - Top layer clipped
                Positioned.fill(
                  child: ClipRect(
                    clipper: _SliderClipper(_sliderPosition),
                    child: Image.file(
                      File(_previousPhoto!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Slider line & handle
                Positioned(
                  left: width * _sliderPosition - 14,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      Expanded(child: Container(width: 4, color: Colors.white)),
                      Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 0)
                        ]),
                        child: const Icon(Icons.swap_horiz, size: 18, color: Colors.black),
                      ),
                      Expanded(child: Container(width: 4, color: Colors.white)),
                    ],
                  ),
                ),
                // Date Labels
                Positioned(
                  left: 12, top: 12,
                  child: _DateChip(date: widget.previous.date, label: 'Before'),
                ),
                Positioned(
                  right: 12, top: 12,
                  child: _DateChip(date: widget.current.date, label: 'After'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMissingPhotos(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          'Missing photos for comparison.',
          style: AppTypography.bodyMedium.copyWith(color: context.textSecondaryColor),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final DateTime date;
  final String label;

  const _DateChip({required this.date, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: Colors.white70)),
          Text(
            DateFormat('MM/dd/yy').format(date),
            style: AppTypography.labelMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double position;
  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => position != oldClipper.position;
}
