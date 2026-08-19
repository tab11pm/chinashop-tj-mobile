import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/b2b_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';

class B2bApplyScreen extends ConsumerStatefulWidget {
  const B2bApplyScreen({super.key});

  @override
  ConsumerState<B2bApplyScreen> createState() => _B2bApplyScreenState();
}

class _B2bApplyScreenState extends ConsumerState<B2bApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();

  bool _isProcessing = false;
  String? _error;

  static const int _shopNameMax = 120;
  static const int _taxIdMax = 64;
  static const int _cityMax = 80;
  static const int _volumeMax = 120;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchAddresses();
    });
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _taxIdCtrl.dispose();
    _cityCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, int max, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.b2bFieldRequired;
    if (v.length > max) return l10n.b2bFieldTooLong;
    return null;
  }

  String? _optionalValidator(String? value, int max, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.length > max) return l10n.b2bFieldTooLong;
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await ref.read(applicationProvider.notifier).apply(
            shopName: _shopNameCtrl.text.trim(),
            taxId: _taxIdCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            expectedVolume: _volumeCtrl.text.trim().isEmpty
                ? null
                : _volumeCtrl.text.trim(),
          );
      if (mounted) {
        context.pushReplacement(AppRoutes.b2bApplication);
      }
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
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);
    final phone = profileState.addresses.isNotEmpty
        ? profileState.addresses.first.phone
        : '-';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(l10n.b2bApplyTitle),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ApplicationStatusBanner(
                  icon: Icons.hourglass_top,
                  title: l10n.b2bApplyTitle,
                  subtitle: l10n.b2bApplyIntro,
                ),
                TextFormField(
                  controller: _shopNameCtrl,
                  enabled: !_isProcessing,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.b2bShopNameLabel,
                    hintText: l10n.b2bShopNameHint,
                  ),
                  validator: (v) => _requiredValidator(v, _shopNameMax, l10n),
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _taxIdCtrl,
                  enabled: !_isProcessing,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.b2bTaxIdLabel,
                    hintText: l10n.b2bTaxIdHint,
                  ),
                  validator: (v) => _requiredValidator(v, _taxIdMax, l10n),
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _cityCtrl,
                  enabled: !_isProcessing,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.b2bCityLabel,
                    hintText: l10n.b2bCityHint,
                  ),
                  validator: (v) => _requiredValidator(v, _cityMax, l10n),
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _volumeCtrl,
                  enabled: !_isProcessing,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.b2bVolumeLabel,
                    hintText: l10n.b2bVolumeHint,
                  ),
                  validator: (v) => _optionalValidator(v, _volumeMax, l10n),
                ),
                const SizedBox(height: AppSpace.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppColors.inkFaint,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          l10n.b2bPhoneFromProfile(phone),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  AppErrorWidget(error: _error!),
                ],
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            ),
                          )
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(_isProcessing
                        ? l10n.b2bSubmitting
                        : l10n.b2bSubmitApplication),
                    onPressed: _isProcessing ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplicationStatusBanner extends StatelessWidget {
  const _ApplicationStatusBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.lg),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCE4B6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF92400E), size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
