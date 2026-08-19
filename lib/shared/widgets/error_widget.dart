import 'package:flutter/material.dart';
import '../../core/api/error_messages.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_tokens.dart';

/// AppErrorWidget — renamed to avoid collision with Flutter's built-in ErrorWidget.
///
/// Displays API errors (DomainException) or plain string errors in a Card.
/// Optionally shows a "Retry" button when onRetry is provided.
class AppErrorWidget extends StatelessWidget {
  /// Error from DomainException or a plain string message.
  final Object error;

  /// Optional callback to retry the failed operation.
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final message = localizedError(context, error);

    return Card(
      margin: const EdgeInsets.all(AppSpace.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  color: AppColors.danger, size: 28),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpace.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retryButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
