import 'package:flutter/material.dart';
import '../../../theme/app_tokens.dart';

/// StarRatingInput — 5-glyph tappable rating selector (UI-SPEC C-7).
///
/// Copy-free (matches the "no hardcoded copy in widget files" discipline
/// from 24-02 Task 2): the caller renders the selected-value label text
/// (localized) below this widget, not inside it.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++) _StarTarget(
              index: i,
              filled: i < value,
              onTap: () => onChanged(i + 1),
            ),
      ],
    );
  }
}

class _StarTarget extends StatefulWidget {
  const _StarTarget({
    required this.index,
    required this.filled,
    required this.onTap,
  });

  final int index;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_StarTarget> createState() => _StarTargetState();
}

class _StarTargetState extends State<_StarTarget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? 0.85 : 1.0,
            duration: AppMotion.tap,
            curve: AppMotion.curveStrong,
            child: Icon(
              widget.filled
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: 40,
              color: widget.filled ? AppColors.rating : AppColors.inkFaint,
            ),
          ),
        ),
      ),
    );
  }
}
