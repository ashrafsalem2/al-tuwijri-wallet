import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialMobile;
  const ForgotPasswordScreen({super.key, this.initialMobile = '05'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _mobileCtrl = TextEditingController(text: widget.initialMobile);
  final _otpCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _codeSent = false;
  String? _devOtp; // shown in dev builds only

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ));

  Future<void> _sendCode(AppStrings t) async {
    if ((_mobileCtrl.text.trim().length) < 6) {
      _snack(t.enterMobile, AppColors.danger);
      return;
    }
    setState(() => _busy = true);
    try {
      final code =
          await ApiService.instance.forgotPassword(mobile: _mobileCtrl.text);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _devOtp = code;
        if (code != null) _otpCtrl.text = code; // prefill for easy dev testing
      });
      _snack(t.codeSent, AppColors.success);
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset(AppStrings t) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ApiService.instance.resetPassword(
        mobile: _mobileCtrl.text,
        otp: _otpCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      _snack(t.passwordResetDone, AppColors.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _snack(e.toString(), AppColors.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_reset_rounded,
                      size: 42, color: AppColors.brand),
                ),
                SizedBox(height: 18),
                Text(t.resetTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                SizedBox(height: 6),
                Text(t.resetSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)),
                SizedBox(height: 26),
                TextFormField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  enabled: !_codeSent,
                  decoration: InputDecoration(
                    labelText: t.mobileNumber,
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                ),
                if (!_codeSent) ...[
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _sendCode(t),
                    child: _busy ? _spinner() : Text(t.sendCode),
                  ),
                ],
                if (_codeSent) ...[
                  SizedBox(height: 16),
                  if (_devOtp != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Color(0xFF9A7B2E)),
                          SizedBox(width: 6),
                          Text(t.devCode(_devOtp!),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9A7B2E))),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: t.verificationCode,
                      prefixIcon: Icon(Icons.pin_rounded),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? t.enterCode : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: t.newPassword,
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.length < 4) ? t.passwordTooShort : null,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _reset(t),
                    child: _busy ? _spinner() : Text(t.resetPasswordAction),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : () => _sendCode(t),
                    child: Text(t.resendCode),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _spinner() => SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
}
