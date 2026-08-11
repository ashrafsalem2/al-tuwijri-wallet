import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/biometric_service.dart';
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
  final _mobileCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  bool _remember = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  List<BiometricType> _biometricTypes = const [];

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _bootstrap();
  }

  /// Load remembered credentials + biometric state before the first frame data.
  Future<void> _bootstrap() async {
    final store = AuthStorage.instance;
    final remember = await store.getRememberMe();
    final bioEnabled = await store.getBiometricEnabled();
    final bioAvailable = await BiometricService.instance.isAvailable();
    final types = await BiometricService.instance.enrolledTypes();

    ({String mobile, String password})? creds;
    if (remember) creds = await store.readCredentials();

    if (!mounted) return;
    setState(() {
      _remember = remember;
      _biometricEnabled = bioEnabled;
      _biometricAvailable = bioAvailable;
      _biometricTypes = types;
      if (creds != null) {
        _mobileCtrl.text = creds.mobile;
        _passCtrl.text = creds.password;
      }
    });

    // If biometric is set up, invite the user to use it right away.
    if (bioAvailable && bioEnabled) {
      _biometricLogin();
    }
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

  // ---- login flows ----

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await _doLogin(
      _mobileCtrl.text.trim(),
      _passCtrl.text,
      offerBiometric: true,
    );
  }

  Future<void> _biometricLogin() async {
    final reason = AppStrings.of(context).biometricReason;
    final creds = await AuthStorage.instance.readCredentials();
    if (creds == null) return; // nothing stored to unlock
    final ok = await BiometricService.instance.authenticate(reason);
    if (!ok) return;
    await _doLogin(creds.mobile, creds.password, offerBiometric: false);
  }

  Future<void> _doLogin(
    String mobile,
    String password, {
    required bool offerBiometric,
  }) async {
    setState(() => _loading = true);
    try {
      await ApiService.instance.login(mobile: mobile, password: password);
      final customer = await ApiService.instance.getCustomer();
      Session.instance.setCustomer(customer);

      // Persist / forget credentials per the "remember me" choice.
      final store = AuthStorage.instance;
      await store.setRememberMe(_remember);
      if (_remember || _biometricEnabled) {
        await store.saveCredentials(mobile, password);
      } else {
        await store.clearCredentials();
      }

      // Offer to turn on biometric login the first time (device only).
      if (mounted &&
          offerBiometric &&
          _biometricAvailable &&
          !_biometricEnabled) {
        await _maybeEnableBiometric(mobile, password);
      }

      if (!mounted) return;
      _goToShell();
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

  Future<void> _maybeEnableBiometric(String mobile, String password) async {
    final t = AppStrings.of(context);
    final wants = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint_rounded,
            size: 42, color: AppColors.brand),
        title: Text(t.enableBiometricTitle, textAlign: TextAlign.center),
        content: Text(t.enableBiometricBody, textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.notNow)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.enable),
          ),
        ],
      ),
    );
    if (wants != true) return;

    final ok = await BiometricService.instance.authenticate(t.biometricReason);
    if (!ok) return;

    final store = AuthStorage.instance;
    await store.setBiometricEnabled(true);
    await store.saveCredentials(mobile, password);
    final deviceId = await store.deviceId();
    await ApiService.instance.enrollBiometric(
      mobile: mobile,
      deviceId: deviceId,
      deviceName: 'Mobile',
    );
    if (mounted) {
      setState(() => _biometricEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.biometricEnabled)),
      );
    }
  }

  void _goToShell() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8, left: 8),
            child: LanguageToggleButton(),
          )
        ],
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
              _animated(
                  0.15,
                  0.6,
                  Text(
                    t.welcomeBack,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  )),
              const SizedBox(height: 6),
              _animated(
                  0.2,
                  0.65,
                  Text(
                    t.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  )),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _animated(
                        0.3,
                        0.75,
                        TextFormField(
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
                    _animated(
                        0.4,
                        0.85,
                        TextFormField(
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
                    const SizedBox(height: 6),
                    // Remember me + forgot password on one row.
                    _animated(
                        0.45,
                        0.9,
                        Row(
                          children: [
                            Checkbox(
                              value: _remember,
                              activeColor: AppColors.brand,
                              onChanged: (v) =>
                                  setState(() => _remember = v ?? false),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _remember = !_remember),
                                child: Text(t.rememberMe,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    initialMobile:
                                        _mobileCtrl.text.trim().isEmpty
                                            ? '05'
                                            : _mobileCtrl.text.trim(),
                                  ),
                                ),
                              ),
                              child: Text(t.forgotPassword,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        )),
                    const SizedBox(height: 12),
                    _animated(
                        0.5,
                        0.95,
                        ElevatedButton(
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
                    if (_biometricAvailable && _biometricEnabled) ...[
                      const SizedBox(height: 12),
                      _animated(0.55, 1.0, _biometricButton(t)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _animated(
                  0.65,
                  1.0,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.noAccountYet,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: Text(t.createAccount,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _biometricButton(AppStrings t) {
    final isFace = _biometricTypes.contains(BiometricType.face);
    final icon = isFace ? Icons.face_rounded : Icons.fingerprint_rounded;
    final label = isFace ? t.loginWithFace : t.loginWithFingerprint;
    return OutlinedButton.icon(
      onPressed: _loading ? null : _biometricLogin,
      icon: Icon(icon, color: AppColors.brand),
      label: Text(label,
          style: const TextStyle(
              color: AppColors.brand, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.brand, width: 1.4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _lottieHeader() {
    return SizedBox(
      height: 200,
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
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.brand.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock_person_rounded,
            size: 64, color: AppColors.brand),
      ),
    );
  }
}
