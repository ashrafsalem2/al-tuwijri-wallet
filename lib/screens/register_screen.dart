import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController(text: '05');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.instance.register(
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final customer = await ApiService.instance.getCustomer();
      Session.instance.setCustomer(customer);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _animated(double start, double end, Widget child) {
    final anim = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, c) => Transform.translate(
          offset: Offset(0, (1 - anim.value) * 22),
          child: c,
        ),
        child: child,
      ),
    );
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
                _animated(0.0, 0.5, Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded,
                      size: 42, color: AppColors.brand),
                )),
                SizedBox(height: 20),
                _animated(0.1, 0.55, Text(
                  t.registerTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                )),
                SizedBox(height: 6),
                _animated(0.15, 0.6, Text(
                  t.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                )),
                SizedBox(height: 28),
                _animated(0.25, 0.7, TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: t.fullName,
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.enterName : null,
                )),
                SizedBox(height: 16),
                _animated(0.32, 0.77, TextFormField(
                  controller: _mobileCtrl,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.mobileNumber,
                    prefixIcon: Icon(Icons.phone_iphone_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? t.enterMobile
                      : null,
                )),
                SizedBox(height: 16),
                _animated(0.39, 0.84, TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: t.email,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? t.enterEmail
                      : null,
                )),
                SizedBox(height: 16),
                _animated(0.46, 0.91, TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: t.password,
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
                )),
                SizedBox(height: 28),
                _animated(0.55, 1.0, ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(t.createAccount),
                )),
                SizedBox(height: 12),
                _animated(0.6, 1.0, Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.haveAccount,
                        style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.signIn,
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
