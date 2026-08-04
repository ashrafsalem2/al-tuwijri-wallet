import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController(text: '0501234567');
  final _passCtrl = TextEditingController(text: 'demo123');
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fadeSlide(double start, double end) {
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.instance.login(
        mobile: _mobileCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final customer = await ApiService.instance.getCustomer();
      Session.instance.setCustomer(customer);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = (e is ApiException && e.lockedSeconds != null)
          ? AppStrings.of(context).tooManyAttempts(e.lockedSeconds!)
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _animated(double start, double end, Widget child) {
    final anim = _fadeSlide(start, end);
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, c) => Transform.translate(
          offset: Offset(0, (1 - anim.value) * 24),
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
        actions: const [Padding(
          padding: EdgeInsets.only(right: 8, left: 8),
          child: LanguageToggleButton(),
        )],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _animated(0.0, 0.5, _lottieHeader()),
              const SizedBox(height: 8),
              _animated(0.15, 0.6, Text(
                t.welcomeBack,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              )),
              const SizedBox(height: 6),
              _animated(0.2, 0.65, Text(
                t.loginSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              )),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _animated(0.3, 0.75, TextFormField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: t.mobileNumber,
                        prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6)
                          ? t.enterMobile
                          : null,
                    )),
                    const SizedBox(height: 16),
                    _animated(0.4, 0.85, TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: t.password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? t.enterPassword
                          : null,
                    )),
                    const SizedBox(height: 28),
                    _animated(0.5, 0.95, ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(t.signIn),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _animated(0.55, 1.0, Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordScreen(
                        initialMobile: _mobileCtrl.text.trim().isEmpty
                            ? '05'
                            : _mobileCtrl.text.trim(),
                      ),
                    ),
                  ),
                  child: Text(t.forgotPassword,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              )),
              const SizedBox(height: 8),
              _animated(0.6, 1.0, Center(
                child: Text(
                  t.demoHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              )),
              const SizedBox(height: 4),
              _animated(0.65, 1.0, Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.noAccountYet,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(t.createAccount,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lottieHeader() {
    return SizedBox(
      height: 220,
      child: Lottie.asset(
        'assets/lottie/login.json',
        repeat: true,
        errorBuilder: (context, error, stack) => _lottieFallback(),
      ),
    );
  }

  Widget _lottieFallback() {
    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock_person_rounded,
            size: 68, color: AppColors.brand),
      ),
    );
  }
}
