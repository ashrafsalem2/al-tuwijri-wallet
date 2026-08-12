import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _baseUrlCtrl =
      TextEditingController(text: ApiService.baseUrl);

  bool _bioAvailable = false;
  bool _bioEnabled = false;
  bool _bioBusy = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled = await AuthStorage.instance.getBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometric(bool want) async {
    final t = AppStrings.of(context);
    setState(() => _bioBusy = true);
    try {
      final store = AuthStorage.instance;
      if (!want) {
        // Turn OFF: clear the flag and revoke the device server-side.
        await store.setBiometricEnabled(false);
        final mobile = ApiService.currentMobile;
        if (mobile != null) {
          final deviceId = await store.deviceId();
          await ApiService.instance
              .disableBiometric(mobile: mobile, deviceId: deviceId);
        }
        if (!mounted) return;
        setState(() => _bioEnabled = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.biometricDisabled)));
        return;
      }

      // Turn ON: we need stored credentials to unlock later.
      var creds = await store.readCredentials();
      final mobile = ApiService.currentMobile ?? creds?.mobile ?? '';
      if (creds == null) {
        // No saved password — ask for it and verify before enabling.
        final password = await _promptPassword(t);
        if (password == null) return; // cancelled
        try {
          await ApiService.instance.login(mobile: mobile, password: password);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(t.wrongPassword),
              backgroundColor: AppColors.danger));
          return;
        }
        await store.saveCredentials(mobile, password);
        creds = (mobile: mobile, password: password);
      }

      final ok = await BiometricService.instance.authenticate(t.biometricReason);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.biometricFailed)));
        return;
      }

      await store.setBiometricEnabled(true);
      final deviceId = await store.deviceId();
      await ApiService.instance.enrollBiometric(
          mobile: mobile, deviceId: deviceId, deviceName: 'Mobile');
      if (!mounted) return;
      setState(() => _bioEnabled = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.biometricEnabled)));
    } finally {
      if (mounted) setState(() => _bioBusy = false);
    }
  }

  Future<String?> _promptPassword(AppStrings t) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.confirmPasswordToEnable, style: const TextStyle(fontSize: 17)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.password,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(t.enable),
          ),
        ],
      ),
    );
  }

  void _save(AppStrings t) {
    ApiService.baseUrl = _baseUrlCtrl.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.saved),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(t.language),
          const SizedBox(height: 8),
          const LanguageSegmented(),
          const SizedBox(height: 24),
          if (_bioAvailable) ...[
            _sectionLabel(t.biometricSection),
            const SizedBox(height: 8),
            _biometricCard(t),
            const SizedBox(height: 24),
          ],
          _sectionLabel(t.apiSettings),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.apiBaseUrl,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _baseUrlCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: 'http://localhost:5080',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(t.apiBaseUrlHint,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _save(t),
            icon: const Icon(Icons.check_rounded),
            label: Text(t.save),
          ),
        ],
      ),
    );
  }

  Widget _biometricCard(AppStrings t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            const Icon(Icons.fingerprint_rounded,
                color: AppColors.brand, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(t.biometricToggleLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 2),
                    child: Text(t.biometricToggleHint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
            _bioBusy
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.brand)),
                  )
                : Switch(
                    value: _bioEnabled,
                    activeThumbColor: AppColors.brand,
                    onChanged: (v) => _toggleBiometric(v),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary)),
      );
}
