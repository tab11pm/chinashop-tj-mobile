import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../auth/phone_input.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/api/error_messages.dart';
import '../../../theme/app_tokens.dart';

/// AddressFormScreen — dedicated full-screen add/edit address form (D-02/D-03/D-04).
///
/// Replaces the old `_showAddAddressSheet` bottom sheet in `profile_screen.dart`
/// (add-only, silent validation). One screen handles both modes:
///   - Add mode: `addressId` is null. Submits via `createAddress`.
///   - Edit mode: `addressId` is non-null. Submits via `updateAddress`.
///
/// Routing note: go_router only passes a path param for the edit route (no
/// `extra`), so the `addressEdit` route builder in `app_router.dart` looks the
/// address up by id from `profileProvider`'s already-fetched address list and
/// passes it as `initial` (fast path). If `initial` is null in edit mode (cold
/// deep-link, process-death restore, or stale/empty cache), this screen does NOT
/// render a blank editable form bound to a real id — it fetches the address list
/// and resolves the id, showing a loader and then a "could not load" retry state
/// if it cannot be found. This prevents a submit from PATCHing blank values over
/// the real address (WR-05).
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId, this.initial});

  /// Non-null in edit mode; null in add mode.
  final String? addressId;

  /// Optional pre-fetched address to seed the form with in edit mode.
  final UserAddress? initial;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _regionCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  bool _isProcessing = false;
  String? _error;

  /// The address whose values seed the edit form. Either passed in via
  /// [AddressFormScreen.initial] (fast path — already in profileProvider cache)
  /// or resolved by [_loadInitial] on a cold deep-link / stale cache.
  UserAddress? _resolved;

  /// True while we are fetching the address list to resolve [_resolved] in edit
  /// mode when no cached `initial` was passed. When this is false and
  /// [_resolved] is still null, the address could not be loaded (deleted, stale
  /// id, or fetch failure) and the "could not load" state is shown instead of
  /// an editable blank form bound to a real id (WR-05).
  bool _loadingInitial = false;

  bool get _isEdit => widget.addressId != null;

  /// In edit mode, the form may be submitted only once the target address is
  /// resolved. Add mode never needs a resolved address.
  bool get _canEditSubmit => !_isEdit || _resolved != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _resolved = initial;
      _seedControllers(initial);
    } else if (_isEdit) {
      // Cold deep-link / process-death restore / stale cache: the address was
      // not in profileProvider when the route built. Resolve it by id before
      // letting the user edit — never present a blank form bound to a real id.
      _loadingInitial = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
    }
  }

  void _seedControllers(UserAddress a) {
    _regionCtrl.text = a.region;
    _cityCtrl.text = a.city;
    _lineCtrl.text = a.line;
    _phoneCtrl.text = tajikLocalPhoneDigits(a.phone);
    _commentCtrl.text = a.comment ?? '';
  }

  /// Fetches the address list and resolves the target address by id. There is no
  /// GET-by-id endpoint, so we refresh the list and look the id up. On success
  /// the controllers are seeded and the form renders; otherwise we surface a
  /// "could not load" state with retry rather than a blank editable form.
  Future<void> _loadInitial() async {
    setState(() => _loadingInitial = true);

    await ref.read(profileProvider.notifier).fetchAddresses();
    if (!mounted) return;

    final state = ref.read(profileProvider);
    final found =
        state.addresses.where((a) => a.id == widget.addressId).firstOrNull;

    setState(() {
      _loadingInitial = false;
      // If found is null the fetch failed (state.error set) or the id is no
      // longer present — _resolved stays null and build() shows the error state.
      if (found != null) {
        _resolved = found;
        _seedControllers(found);
      }
    });
  }

  @override
  void dispose() {
    _regionCtrl.dispose();
    _cityCtrl.dispose();
    _lineCtrl.dispose();
    _phoneCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.fieldRequiredError;
    return null;
  }

  String? _phoneValidator(String? value, AppLocalizations l10n) {
    final digits = tajikLocalPhoneDigits(value ?? '');
    if (digits.length != tajikLocalPhoneLength) {
      return l10n.addressPhoneInvalidError;
    }
    return null;
  }

  Future<void> _submit() async {
    // Defensive guard: in edit mode never PATCH until the real address is
    // resolved — a blank/partial body would overwrite it (WR-05). The submit
    // button is not rendered in the unresolved state, so this is belt-and-braces.
    if (!_canEditSubmit) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'region': _regionCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'line': _lineCtrl.text.trim(),
      'phone': tajikPhoneToE164(tajikLocalPhoneDigits(_phoneCtrl.text)),
      if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await ref.read(profileProvider.notifier).updateAddress(widget.addressId!, body);
      } else {
        await ref.read(profileProvider.notifier).createAddress(body);
      }
      if (mounted) context.pop();
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

    // Edit mode without a resolved address: show a loader while fetching, then a
    // "could not load" state with retry — never an editable blank form bound to
    // a real id (WR-05). The submit button is intentionally absent here.
    if (_isEdit && _resolved == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text(l10n.editAddressTitle),
          leading: const BackButton(),
        ),
        body: _loadingInitial
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: AppErrorWidget(
                  error: l10n.addressLoadError,
                  onRetry: _loadInitial,
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editAddressTitle : l10n.addAddressTitle),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _regionCtrl,
                enabled: !_isProcessing,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.regionField),
                validator: (v) => _requiredValidator(v, l10n),
              ),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _cityCtrl,
                enabled: !_isProcessing,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.cityField),
                validator: (v) => _requiredValidator(v, l10n),
              ),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _lineCtrl,
                enabled: !_isProcessing,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.addressLineField),
                validator: (v) => _requiredValidator(v, l10n),
              ),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _phoneCtrl,
                enabled: !_isProcessing,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneField,
                  hintText: '901234567',
                  prefixText: '$tajikPhonePrefix ',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                inputFormatters: [
                  const TajikPhoneInputFormatter(),
                  LengthLimitingTextInputFormatter(tajikLocalPhoneLength),
                ],
                textInputAction: TextInputAction.next,
                validator: (v) => _phoneValidator(v, l10n),
              ),
              const SizedBox(height: AppSpace.sm),
              TextFormField(
                controller: _commentCtrl,
                enabled: !_isProcessing,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.commentField),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.lg),
                AppErrorWidget(error: _error!),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
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
              label: Text(l10n.saveAddressButton),
              onPressed: _isProcessing ? null : _submit,
            ),
          ),
        ),
      ),
    );
  }
}
