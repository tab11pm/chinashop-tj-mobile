import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';

/// EditProfileScreen — edit flow for the user's name (D-01).
///
/// Phone and email are set once during the post-OTP "знакомство" step and
/// locked thereafter (product decision — no self-service phone/email
/// changes); they render here as read-only for reference only. Only `name`
/// is editable, submitted via `PATCH /api/users/me`, after which AuthState
/// is refreshed from the server and the screen pops back to the profile
/// screen. Validation errors from the backend (Zod `{error, code}`) surface
/// inline.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameCtrl.text = auth.name ?? '';
    _phoneCtrl.text = auth.phone ?? '';
    _emailCtrl.text = auth.email ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();

    // Nothing to save — phone/email are read-only, so name is the only
    // field that can change.
    if (name.isEmpty) {
      setState(() => _error = 'VALIDATION_FAILED');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final body = <String, dynamic>{'name': name};

    try {
      final client = ref.read(dioClientProvider);
      await client.patch('/api/users/me', data: body);
      await ref.read(authProvider.notifier).refreshFromServer();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileEditSaved)),
      );
      context.pop();
    } catch (e) {
      setState(() {
        _error = errorCodeOf(e);
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.profileEditTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              enabled: !_isProcessing,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.profileNameLabel),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _phoneCtrl,
              readOnly: true,
              enabled: false,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.profilePhoneLabel),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _emailCtrl,
              readOnly: true,
              enabled: false,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailLabel),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.lg),
              AppErrorWidget(error: _error!),
            ],
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onAccent),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.profileEditCta),
                onPressed: _isProcessing ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
