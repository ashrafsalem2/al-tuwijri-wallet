import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Customer? _c = Session.instance.customer.value;
  late final _nameCtrl = TextEditingController(text: _c?.name ?? '');
  late final _emailCtrl = TextEditingController(text: _c?.email ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppStrings t) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.updateProfile(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      // Reflect the change locally so every screen updates.
      final current = Session.instance.customer.value;
      if (current != null) {
        Session.instance.customer.value = current.copyWith(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.profileUpdated),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.editProfile,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: t.fullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? t.enterName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: t.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? t.enterEmail : null,
              ),
              const SizedBox(height: 16),
              // Mobile is the account id / barcode — shown read-only.
              TextFormField(
                initialValue: _c?.mobile ?? '',
                enabled: false,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: t.mobileNumber,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : () => _save(t),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(t.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
