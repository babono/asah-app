import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/errors.dart';
import '../../core/widgets/widgets.dart';
import 'logo.dart';

/// Sign in with phone number and a one-time code (F5, F8; design screen 0).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _e164 {
    var digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '${AppConfig.defaultDialCode}$digits';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _resendIn <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn--);
    });
  }

  Future<void> _sendCode() async {
    if (_phone.text.replaceAll(RegExp(r'\D'), '').length < 8) return;
    setState(() => _busy = true);
    try {
      // Accounts are created by HQ (F4), so never sign up from here.
      await ref.read(supabaseProvider).auth.signInWithOtp(phone: _e164, shouldCreateUser: false);
      if (!mounted) return;
      setState(() => _codeStep = true);
      _startTimer();
    } catch (e) {
      if (mounted) {
        final msg = e is AuthException && (e.message.contains('Signups not allowed') || e.statusCode == '422')
            ? context.l10n.phoneNotRegistered
            : friendlyError(e);
        showSnack(context, msg, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify([String? code]) async {
    final token = code ?? _code.text;
    if (token.length != 6) return;
    setState(() => _busy = true);
    try {
      await ref.read(supabaseProvider).auth.verifyOTP(phone: _e164, token: token, type: OtpType.sms);
      // The router moves on when the session arrives.
    } catch (e) {
      if (mounted) {
        _code.clear();
        showSnack(context, context.l10n.wrongCode, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = ref.watch(localeProvider)?.languageCode ?? Localizations.localeOf(context).languageCode;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: _LanguageToggle(
                  value: lang,
                  onChanged: (v) => ref.read(localeProvider.notifier).set(v),
                ),
              ),
            ),
            // With the keyboard up there is no room for the headline: keep the form and button visible.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: keyboardUp
                  ? const SizedBox(width: double.infinity, height: 16)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AsahWordmark(),
                          const SizedBox(height: 20),
                          Text(l10n.signInHeadline,
                              style: const TextStyle(
                                  fontSize: 26, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 12),
                          const Text(AppConfig.clientName,
                              style: TextStyle(fontSize: 15, color: AppColors.onPrimaryMuted)),
                        ],
                      ),
                    ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(24, keyboardUp ? 24 : 32, 24, keyboardUp ? 16 : 24 + MediaQuery.of(context).padding.bottom),
                // Scrolls when the keyboard leaves less room than the form needs.
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: IntrinsicHeight(child: _codeStep ? _codeForm(context) : _phoneForm(context)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneForm(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.signIn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(l10n.signInSub, style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Text(l10n.phoneNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textStrong)),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ]'))],
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: '812 3456 7890',
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(right: BorderSide(color: AppColors.border)),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              alignment: Alignment.center,
              width: 64,
              child: const Text(AppConfig.defaultDialCode,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textStrong)),
            ),
          ),
          onSubmitted: (_) => _sendCode(),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : _sendCode,
          child: _busy ? const _Spinner() : Text(l10n.sendCode),
        ),
        const SizedBox(height: 12),
        Text(l10n.noAccount, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _codeForm(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() {
              _codeStep = false;
              _code.clear();
            }),
            icon: const Icon(Icons.chevron_left_rounded),
            label: Text(l10n.changeNumber),
          ),
        ),
        Text(l10n.enterCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(l10n.sentTo(_e164), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 14),
          decoration: const InputDecoration(hintText: '······', counterText: ''),
          onChanged: (v) {
            if (v.length == 6) _verify(v);
          },
        ),
        const SizedBox(height: 16),
        _resendIn > 0
            ? Text(l10n.resendIn(_resendIn), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
            : Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _busy ? null : _sendCode, child: Text(l10n.resendCode)),
              ),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : () => _verify(),
          child: _busy ? const _Spinner() : Text(l10n.verifyAndContinue),
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String code, String label) {
      final on = value == code;
      return Semantics(
        selected: on,
        button: true,
        child: GestureDetector(
          onTap: () => onChanged(code),
          child: Container(
            constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(999)),
            child: Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? AppColors.primary : Colors.white)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [chip('en', 'EN'), chip('id', 'ID')]),
    );
  }
}
