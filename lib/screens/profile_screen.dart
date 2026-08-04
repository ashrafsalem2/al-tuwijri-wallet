import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.navProfile,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ValueListenableBuilder<Customer?>(
        valueListenable: Session.instance.customer,
        builder: (context, c, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _entrance(0, _headerCard(context, c, t)),
              const SizedBox(height: 18),
              _entrance(1, Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(t.language,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              )),
              const SizedBox(height: 10),
              _entrance(2, const LanguageSegmented()),
              const SizedBox(height: 18),
              _entrance(3, _tile(
                icon: Icons.person_outline_rounded,
                label: t.editProfile,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ),
              )),
              const SizedBox(height: 10),
              _entrance(4, _tile(
                icon: Icons.lock_outline_rounded,
                label: t.changePassword,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
              )),
              const SizedBox(height: 10),
              _entrance(5, _tile(
                icon: Icons.settings_outlined,
                label: t.settings,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              )),
              const SizedBox(height: 10),
              _entrance(6, _logoutButton(context, t)),
            ],
          );
        },
      ),
    );
  }

  Widget _entrance(int i, Widget child) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 350 + i * 80),
        curve: Curves.easeOut,
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: c),
        ),
        child: child,
      );

  Widget _headerCard(BuildContext context, Customer? c, AppStrings t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              (c?.firstName.characters.first ?? '?').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c?.name ?? '-',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if ((c?.tier ?? '').isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(c!.tier,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDark)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.stars_rounded,
                        size: 15, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      t.points(c?.points ?? 0),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (c?.mobile ?? '').isNotEmpty
                      ? c!.mobile
                      : t.memberSince(c?.memberSince ?? ''),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brand, size: 22),
              const SizedBox(width: 14),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context, AppStrings t) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: Text(t.logout,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _confirmLogout(context, t),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AppStrings t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(t.logoutConfirmTitle),
        content: Text(t.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.logout),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    Session.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOut)),
            child: child,
          ),
        ),
      ),
      (route) => false,
    );
  }
}
