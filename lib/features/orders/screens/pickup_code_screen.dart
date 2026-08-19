import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../theme/app_tokens.dart';
import '../providers/orders_provider.dart';
import '../providers/pickup_code_provider.dart';

abstract class PickupScreenEffects {
  Future<void> engage();
  Future<void> restore();
}

class DefaultPickupScreenEffects implements PickupScreenEffects {
  const DefaultPickupScreenEffects();

  static const MethodChannel _screenAwakeChannel =
      MethodChannel('pinshop_tj/screen_awake');

  @override
  Future<void> engage() async {
    await _screenAwakeChannel.invokeMethod<void>('enable');
    await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
  }

  @override
  Future<void> restore() async {
    await _screenAwakeChannel.invokeMethod<void>('disable');
    await ScreenBrightness.instance.resetApplicationScreenBrightness();
  }
}

class PickupCodeScreen extends ConsumerStatefulWidget {
  const PickupCodeScreen({
    super.key,
    required this.orderId,
    this.effects = const DefaultPickupScreenEffects(),
  });

  final String orderId;
  final PickupScreenEffects effects;

  @override
  ConsumerState<PickupCodeScreen> createState() => _PickupCodeScreenState();
}

class _PickupCodeScreenState extends ConsumerState<PickupCodeScreen> {
  final Map<String, Widget> _qrViews = {};
  bool _clearedDeliveredCache = false;

  @override
  void initState() {
    super.initState();
    widget.effects.engage();
  }

  @override
  void dispose() {
    widget.effects.restore();
    super.dispose();
  }

  void _clearDeliveredCacheOnce() {
    if (_clearedDeliveredCache) return;
    _clearedDeliveredCache = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dioClientProvider).storage.clearPickupCode(widget.orderId);
    });
  }

  Widget _qrView(String payload) {
    return _qrViews.putIfAbsent(
      payload,
      () => PrettyQrView.data(data: payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pickupCodeTitle),
        leading: const BackButton(),
      ),
      body: orderAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => AppErrorWidget(
          error: err,
          onRetry: () => ref.refresh(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          if (order.status == 'delivered') {
            _clearDeliveredCacheOnce();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 64,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      l10n.pickupCodeDeliveredTitle,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      l10n.pickupCodeDeliveredBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final pickupCodeAsync = ref.watch(pickupCodeProvider(widget.orderId));
          return pickupCodeAsync.when(
            loading: () => const LoadingState(),
            error: (err, _) => AppErrorWidget(
              error: err,
              onRetry: () => ref.refresh(pickupCodeProvider(widget.orderId)),
            ),
            data: (pickupCode) {
              final groupedCode = pickupCode.code.length == 6
                  ? '${pickupCode.code.substring(0, 3)} ${pickupCode.code.substring(3)}'
                  : pickupCode.code;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: _qrView(pickupCode.qrPayload),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Text(
                            groupedCode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            l10n.pickupCodeHelper,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pickupCode.fromCache) ...[
                      const SizedBox(height: AppSpace.lg),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius:
                              BorderRadius.circular(AppRadii.control),
                        ),
                        child: Text(
                          l10n.pickupCodeOfflineBanner,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
