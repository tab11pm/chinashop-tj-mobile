import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../phone_input.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_tokens.dart';

/// AuthScreen — two-step OTP authentication.
///
/// APP-01: phone number → POST /api/auth/otp/request { phone }
///         OTP code   → POST /api/auth/otp/verify { phone, code }
///
/// Step 1: Phone input + "Send OTP" button
/// Step 2: OTP input + "Verify" button
///
/// On success: authProvider sets isAuthenticated=true → go_router redirects to /home.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

const _otpLength = 6;
const _resendCooldown = Duration(seconds: 60);

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  bool _otpSent = false;
  String? _localError;
  Timer? _resendTimer;
  Duration _resendRemaining = Duration.zero;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendRemaining = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _resendRemaining - const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        timer.cancel();
        setState(() => _resendRemaining = Duration.zero);
      } else {
        setState(() => _resendRemaining = remaining);
      }
    });
  }

  Future<void> _sendOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneDigits = tajikLocalPhoneDigits(_phoneController.text);
    if (phoneDigits.length != tajikLocalPhoneLength) {
      setState(() => _localError = l10n.errorEnterPhone);
      return;
    }
    final phone = tajikPhoneToE164(phoneDigits);
    setState(() => _localError = null);
    try {
      await ref.read(authProvider.notifier).requestOtp(phone);
      setState(() => _otpSent = true);
      _startResendCooldown();
      // Move focus to the freshly shown OTP field so the keyboard targets it
      // (the step swap otherwise leaves the keyboard up with no focused input).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNode.requestFocus();
      });
    } catch (_) {
      // Error shown via authProvider.state.error
    }
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = tajikPhoneToE164(_phoneController.text);
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _localError = l10n.errorEnterCode);
      return;
    }
    setState(() => _localError = null);
    try {
      await ref.read(authProvider.notifier).verifyOtp(phone, code);
      // go_router redirect fires automatically when isAuthenticated=true
    } catch (_) {
      // Error shown via authProvider.state.error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable top block: lang switcher, logo, heading, field — one card.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_otpSent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _otpSent = false;
                              _otpController.clear();
                              _localError = null;
                            }),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.ink,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _LangMini(
                              locale: authState.locale,
                              onSelect: (locale) => ref
                                  .read(authProvider.notifier)
                                  .setLocale(locale),
                            ),
                          ),
                        ),

                      // Logo badge — matches `.auth .logo` (green) / OTP step's
                      // cream variant with hairline border.
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color:
                              _otpSent ? AppColors.surface : AppColors.accent,
                          borderRadius: BorderRadius.circular(17),
                          border: _otpSent
                              ? Border.all(color: AppColors.line)
                              : null,
                          boxShadow: _otpSent
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _otpSent
                              ? Icons.sms_outlined
                              : Icons.storefront_outlined,
                          color: _otpSent
                              ? AppColors.inkMuted
                              : AppColors.onAccent,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 22),

                      Text(
                        _otpSent ? l10n.enterOtpTitle : l10n.enterPhoneTitle,
                        style: const TextStyle(
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.w700,
                          fontSize: 23,
                          height: 1.25,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_otpSent)
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              color: AppColors.inkMuted,
                            ),
                            children: [
                              TextSpan(text: l10n.sentOtpSubtitlePrefix),
                              TextSpan(
                                text: tajikPhoneToE164(
                                    _phoneController.text),
                                style: const TextStyle(color: AppColors.ink),
                              ),
                              const TextSpan(text: '. '),
                              TextSpan(
                                text: l10n.changePhoneLink,
                                style: const TextStyle(
                                  color: AppColors.accentHover,
                                  fontWeight: FontWeight.w700,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => setState(() {
                                        _otpSent = false;
                                        _otpController.clear();
                                        _localError = null;
                                      }),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          l10n.sendSmsSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      const SizedBox(height: 24),

                      if (!_otpSent) ...[
                        _AuthFieldLabel(l10n.phoneLabel),
                        const SizedBox(height: 6),
                        _AuthField(
                          key: const ValueKey('auth-phone-field'),
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixText: '$tajikPhonePrefix ',
                          hintText: '90 123 45 67',
                          inputFormatters: [
                            const TajikPhoneInputFormatter(),
                            LengthLimitingTextInputFormatter(
                                tajikLocalPhoneLength),
                          ],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _sendOtp(),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          l10n.sendSmsSubtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ] else ...[
                        _AuthFieldLabel(l10n.otpLabel),
                        const SizedBox(height: 6),
                        _OtpBoxes(
                          key: const ValueKey('auth-otp-field'),
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          length: _otpLength,
                          onCompleted: _verifyOtp,
                        ),
                      ],

                      if (_localError != null ||
                          authState.error != null) ...[
                        const SizedBox(height: 16),
                        AppErrorWidget(
                          error: _localError ?? authState.error ?? '',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom-pinned CTA block — matches `.auth .cta { margin-top: auto }`.
              if (!_otpSent) ...[
                _AuthCta(
                  label: l10n.sendOtpButton,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _sendOtp,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.authLegalText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ] else ...[
                _AuthCta(
                  label: l10n.verifyButton,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _verifyOtp,
                ),
                const SizedBox(height: 10),
                Center(
                  child: _resendRemaining > Duration.zero
                      ? Text(
                          l10n.resendCodeIn(_formatCountdown(
                              _resendRemaining)),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkMuted,
                          ),
                        )
                      : TextButton(
                          onPressed: authState.isLoading ? null : _sendOtp,
                          child: Text(l10n.resendCode),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCountdown(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// `.auth label` — small uppercase field label above each input.
class _AuthFieldLabel extends StatelessWidget {
  const _AuthFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.inkMuted,
      ),
    );
  }
}

/// `.auth .field` — cream card input with hairline border + green focus glow.
class _AuthField extends StatefulWidget {
  const _AuthField({
    super.key,
    required this.controller,
    this.keyboardType,
    this.prefixText,
    this.hintText,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? prefixText;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
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
          counterText: '',
          prefixText: widget.prefixText,
          prefixStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// `.otp` — N digit boxes (filled/cursor/empty) backed by a single hidden
/// [TextField] so paste, keyboard, and autofill all work normally.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final VoidCallback onCompleted;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  void _onTextChange() {
    setState(() {});
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digits = widget.controller.text;
    return GestureDetector(
      onTap: () => widget.focusNode.requestFocus(),
      child: Stack(
        children: [
          Row(
            children: List.generate(widget.length, (i) {
              final hasDigit = i < digits.length;
              final isCursor = _focused && i == digits.length;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: i == widget.length - 1 ? 0 : 9),
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasDigit || isCursor
                          ? AppColors.accent
                          : AppColors.line,
                    ),
                    boxShadow: isCursor
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.14),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    hasDigit ? digits[i] : '',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              );
            }),
          ),
          // Invisible field carries real text input/focus/paste/autofill.
          Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.auth .cta` — full-width green CTA with glow shadow.
class _AuthCta extends StatelessWidget {
  const _AuthCta({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onAccent,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

/// `.auth .lang-mini` — compact TJ/RU/EN pill, top-right of the phone step.
class _LangMini extends StatelessWidget {
  const _LangMini({required this.locale, required this.onSelect});

  final String locale;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangMiniButton(
            label: 'TJ',
            selected: locale == 'tg',
            onTap: () => onSelect('tg'),
          ),
          _LangMiniButton(
            label: 'RU',
            selected: locale == 'ru',
            onTap: () => onSelect('ru'),
          ),
          _LangMiniButton(
            label: 'EN',
            selected: locale == 'en',
            onTap: () => onSelect('en'),
          ),
        ],
      ),
    );
  }
}

class _LangMiniButton extends StatelessWidget {
  const _LangMiniButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: selected ? const Color(0xFF05140B) : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}
