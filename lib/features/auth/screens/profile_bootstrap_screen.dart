import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../theme/app_tokens.dart';
import '../providers/auth_provider.dart';

class ProfileBootstrapScreen extends ConsumerWidget {
  const ProfileBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: authState.isProfileRefreshing || authState.error == null
            ? const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('profile-bootstrap-spinner'),
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppErrorWidget(
                        key: const ValueKey('profile-bootstrap-error'),
                        error: authState.error!,
                        onRetry: () {
                          ref.read(authProvider.notifier).refreshFromServer();
                        },
                      ),
                      OutlinedButton(
                        key: const ValueKey('profile-bootstrap-logout'),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                        },
                        child: Text(l10n.logoutButton),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
