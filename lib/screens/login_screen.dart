import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/biometric_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/gold_particles_background.dart';
import '../widgets/language_toggle.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

const Color _gold = Color(0xFFE7C877);
const Color _goldDeep = Color(0xFFC9A24B);
const Color _onGold = Color(0xFF2A1E05);

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

      final store = AuthStorage.instance;
      await store.setRememberMe(_remember);
      if (_remember || _biometricEnabled) {
        await store.saveCredentials(mobile, password);
      } else {
        await store.clearCredentials();
      }

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
      backgroundColor: const Color(0xFF0B0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8, left: 8),
            child: LanguageToggleButton(),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GoldParticlesBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _animated(0.0, 0.5, _logoHeader()),
                const SizedBox(height: 20),
                _animated(
                    0.15,
                    0.6,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            t.welcomeBack,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _WavingHand(size: 26),
                      ],
                    )),
                const SizedBox(height: 6),
                _animated(
                    0.2,
                    0.65,
                    Text(
                      t.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6)),
                    )),
                const SizedBox(height: 28),
                _animated(0.3, 0.85, _formCard(t)),
                const SizedBox(height: 16),
                _animated(
                    0.65,
                    1.0,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.noAccountYet,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6))),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                          child: Text(t.createAccount,
                              style: const TextStyle(
                                  color: _gold, fontWeight: FontWeight.w800)),
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

  /// Gold app-icon-style logo with a soft glow, matching the concept.
  Widget _logoHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gold, _goldDeep],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _goldDeep.withValues(alpha: 0.45),
              blurRadius: 34,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const BrandLogo(size: 66),
      ),
    );
  }

  /// The dark, translucent form card holding the inputs and actions.
  Widget _formCard(AppStrings t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            floatingLabelStyle: const TextStyle(color: _gold),
            prefixIconColor: _gold,
            suffixIconColor: Colors.white54,
            enabledBorder: _border(Colors.white.withValues(alpha: 0.15)),
            border: _border(Colors.white.withValues(alpha: 0.15)),
            focusedBorder: _border(_gold, width: 1.5),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: t.mobileNumber,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                ),
                validator: (v) => (v == null || v.trim().length < 6)
                    ? t.enterMobile
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: t.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? t.enterPassword : null,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    activeColor: _gold,
                    checkColor: _onGold,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5)),
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _remember = !_remember),
                      child: Text(t.rememberMe,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  TextButton(
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
                        style: const TextStyle(
                            color: _gold, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _onGold,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(_onGold),
                          ),
                        )
                      : Text(t.signIn),
                ),
              ),
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: 12),
                _biometricButton(t),
              ],
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _biometricButton(AppStrings t) {
    final isFace = _biometricTypes.contains(BiometricType.face);
    final icon = isFace ? Icons.face_rounded : Icons.fingerprint_rounded;
    final label = isFace ? t.loginWithFace : t.loginWithFingerprint;
    return OutlinedButton.icon(
      onPressed: _loading ? null : _biometricLogin,
      icon: Icon(icon, color: _gold),
      label: Text(label,
          style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: _gold.withValues(alpha: 0.6), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// A 👋 emoji that waves — rocking back and forth around the wrist, like a
/// real wave. Pivots at the bottom so it swings from the base of the palm.
class _WavingHand extends StatefulWidget {
  final double size;
  const _WavingHand({this.size = 24});

  @override
  State<_WavingHand> createState() => _WavingHandState();
}

class _WavingHandState extends State<_WavingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _wave = Tween<double>(
    begin: -0.18,
    end: 0.32,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _wave,
      builder: (_, child) => Transform.rotate(
        angle: _wave.value,
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: Text('👋', style: TextStyle(fontSize: widget.size)),
    );
  }
}
