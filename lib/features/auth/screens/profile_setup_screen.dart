import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// ProfileSetupScreen — post-OTP "знакомство" step (design demo Zone 5,
/// Auth-3): collects name + email, both required, before the user can
/// reach channel-choice/home. Shown only when AuthState.needsProfileSetup
/// is true (see go_router redirect condition 1.5).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  String? _lastSyncedName;
  String? _lastSyncedEmail;
  String? _lastSyncedPhone;
  String? _localError;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _syncFromAuthState(AuthState authState) {
    final nextName = authState.name?.trim() ?? '';
    if (nextName != _lastSyncedName) {
      final previousName = _lastSyncedName ?? '';
      if (_nameController.text.isEmpty ||
          _nameController.text == previousName) {
        _nameController.text = nextName;
      }
      _lastSyncedName = nextName;
    }

    final nextEmail = authState.email?.trim() ?? '';
    if (nextEmail != _lastSyncedEmail) {
      _emailController.text = nextEmail;
      _lastSyncedEmail = nextEmail;
    }

    final nextPhone = authState.phone?.trim() ?? '';
    if (nextPhone != _lastSyncedPhone) {
      _phoneController.text = nextPhone;
      _lastSyncedPhone = nextPhone;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      setState(() => _localError = l10n.errorEnterName);
      return;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _localError = l10n.errorEnterEmail);
      return;
    }
    setState(() => _localError = null);
    try {
      await ref.read(authProvider.notifier).completeProfile(name, email);
      // go_router redirect proceeds to /welcome once needsProfileSetup flips false.
    } catch (_) {
      // Error shown via authState.error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;
    _syncFromAuthState(authState);
    // Name/phone/email are set once at account creation and then locked
    // (product decision — no self-service email/phone changes). But a
    // brand-new user has no email yet, so the field must stay editable
    // until they've actually set one — otherwise it can never be filled in.
    final emailAlreadySet = (authState.email ?? '').trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // `.auth .pdots` — 3-dot progress, all on (step 3 of 3).
                      const Row(
                        children: [
                          Expanded(child: _ProgressDot(on: true)),
                          SizedBox(width: 6),
                          Expanded(child: _ProgressDot(on: true)),
                          SizedBox(width: 6),
                          Expanded(child: _ProgressDot(on: true)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // `.auth .welcome-ill` — 👋 illustration badge.
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accent,
                              AppColors.accentHover,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('👋', style: TextStyle(fontSize: 42)),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        l10n.profileSetupStep,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: AppColors.accentHover,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        l10n.profileSetupTitle,
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w700,
                          fontSize: 23,
                          height: 1.25,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.profileSetupSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _RequiredFieldLabel(l10n.nameLabel),
                      const SizedBox(height: 6),
                      _ProfileField(
                        key: const ValueKey('profile-setup-name-field'),
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        hintText: l10n.nameHint,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        icon: Icons.person_outline,
                        onSubmitted: (_) => _emailFocusNode.requestFocus(),
                      ),
                      const SizedBox(height: 16),

                      _FieldLabel(l10n.phoneLabel),
                      const SizedBox(height: 6),
                      _ProfileField(
                        key: const ValueKey('profile-setup-phone-field'),
                        controller: _phoneController,
                        hintText: l10n.phoneHint,
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      _RequiredFieldLabel(l10n.emailLabel),
                      const SizedBox(height: 6),
                      _ProfileField(
                        key: const ValueKey('profile-setup-email-field'),
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        hintText: l10n.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        icon: Icons.mail_outline,
                        readOnly: emailAlreadySet,
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        l10n.emailHelpText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: AppColors.inkMuted,
                        ),
                      ),

                      if (_localError != null || authState.error != null) ...[
                        const SizedBox(height: 16),
                        AppErrorWidget(
                          error: _localError ?? authState.error ?? '',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onAccent,
                            ),
                          )
                        : Text(
                            l10n.profileSetupCta,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.auth .pdots i` — single progress segment.
class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: on ? AppColors.accent : AppColors.line,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// `.auth label` with a required-field asterisk (`.auth .req`).
class _RequiredFieldLabel extends StatelessWidget {
  const _RequiredFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.inkMuted,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppColors.accentHover,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.inkMuted,
      ),
    );
  }
}

/// `.auth .field` — cream card input with an icon prefix, matching
/// AuthScreen's `_AuthField` but with an icon glyph instead of a phone prefix.
class _ProfileField extends StatefulWidget {
  const _ProfileField({
    super.key,
    required this.controller,
    required this.icon,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final IconData icon;
  final FocusNode? focusNode;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  FocusNode? _internalFocusNode;
  bool _focused = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _ProfileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_onFocusChange);
    _focused = _focusNode.hasFocus;
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _focused ? AppColors.accent : AppColors.line,
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Row(
        children: [
          Icon(widget.icon, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              readOnly: widget.readOnly,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
