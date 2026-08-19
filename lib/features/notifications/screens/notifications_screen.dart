import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../theme/app_tokens.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.notifications.isEmpty
              ? AppErrorWidget(
                  error: state.error!,
                  onRetry: () => ref
                      .read(notificationsProvider.notifier)
                      .fetchNotifications(),
                )
              : state.notifications.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_none,
                      title: l10n.notificationsEmpty,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(notificationsProvider.notifier)
                          .fetchNotifications(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        itemCount: state.notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpace.sm),
                        itemBuilder: (context, index) {
                          final notification = state.notifications[index];
                          return Material(
                            color: notification.isRead
                                ? AppColors.surface
                                : AppColors.accentPlate,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            child: ListTile(
                              leading: Icon(
                                _iconFor(notification.type),
                                color: AppColors.accentDeep,
                              ),
                              title: Text(_titleFor(l10n, notification.type)),
                              subtitle: Text(
                                notification.payload['customerMessage']
                                        ?.toString() ??
                                    _amountText(l10n, notification),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                if (!notification.isRead) {
                                  await ref
                                      .read(notificationsProvider.notifier)
                                      .markRead(notification.id);
                                }
                                if (context.mounted &&
                                    notification.orderId != null) {
                                  context.push(
                                    AppRoutes.orderPath(notification.orderId!),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _titleFor(AppLocalizations l10n, String type) {
    switch (type) {
      case 'order_item_cancelled':
        return l10n.notificationItemCancelled;
      case 'refund_succeeded':
        return l10n.notificationRefundSucceeded;
      case 'refund_failed':
        return l10n.notificationRefundFailed;
      case 'refund_manual_required':
        return l10n.notificationRefundManualRequired;
      default:
        return l10n.notificationsTitle;
    }
  }

  String _amountText(
    AppLocalizations l10n,
    CustomerNotification notification,
  ) {
    final amount = notification.payload['amountTjs']?.toString();
    return amount == null ? '' : l10n.notificationRefundAmount(amount);
  }

  IconData _iconFor(String type) =>
      type == 'order_item_cancelled' ? Icons.remove_shopping_cart : Icons.replay;
}
