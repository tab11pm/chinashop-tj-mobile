import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';

class DeliveredCelebration extends StatefulWidget {
  const DeliveredCelebration({
    super.key,
    required this.onDismissed,
    this.duration = const Duration(milliseconds: 2500),
  });

  final VoidCallback onDismissed;
  final Duration duration;

  @override
  State<DeliveredCelebration> createState() => _DeliveredCelebrationState();
}

class _DeliveredCelebrationState extends State<DeliveredCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scale = CurvedAnimation(parent: _ctrl, curve: AppMotion.curveStrong);
    final fade = CurvedAnimation(parent: _ctrl, curve: AppMotion.curve);

    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(scale),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.accentBorder),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPlate,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: AppColors.accentDeep,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Text(
                    l10n.deliveredCelebrationTitle,
                    style: const TextStyle(
                      fontFamily: 'Onest',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
