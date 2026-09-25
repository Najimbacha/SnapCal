import 'package:flutter/material.dart';

import 'reveal.dart';

/// A headline that arrives a word at a time, each rising into place just
/// after the one before. Line breaks fall where they would for plain text,
/// and it reads as one sentence to a screen reader.
class WordRise extends StatelessWidget {
  const WordRise(
    this.text, {
    super.key,
    required this.style,
    this.delay = Duration.zero,
    this.stagger = const Duration(milliseconds: 70),
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Duration delay;
  final Duration stagger;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              for (var i = 0; i < words.length; i++) ...[
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: Reveal(
                    delay: delay + stagger * i,
                    offset: const Offset(0, 18),
                    duration: const Duration(milliseconds: 560),
                    child: Text(words[i], style: style),
                  ),
                ),
                if (i < words.length - 1) const TextSpan(text: ' '),
              ],
            ],
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}
