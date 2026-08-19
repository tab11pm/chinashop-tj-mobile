import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

/// PriceTag renders a money value from the API as a string.
///
/// IMPORTANT: `value` is the String as returned by the API (e.g., "12.50").
/// This widget NEVER calls double.parse()/num.parse() — money is rendered
/// directly as text (D-07).
class PriceTag extends StatelessWidget {
  /// Money string from the API (e.g., "12.50"). Do NOT pass a parsed double.
  final String value;

  /// Currency suffix shown after the value. Defaults to 'с' (сомони).
  final String currency;

  /// Larger emphasis variant (for product cards / detail).
  final bool large;

  /// Full style override (wins over [large]).
  final TextStyle? style;

  const PriceTag({
    super.key,
    required this.value,
    this.currency = 'с',
    this.large = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Reference: price is ink (near-black), Nunito heavy, currency 'с' muted.
    final base = style ??
        TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.ink,
          fontWeight: FontWeight.w900,
          fontSize: large ? 18 : 15,
          letterSpacing: -0.3,
        );

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: value),
          TextSpan(
            text: ' $currency',
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: (base.fontSize ?? 15) - 3,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
