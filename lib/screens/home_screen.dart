import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String _mobile = Session.instance.customer.value?.mobile ?? '';
  late Future<Map<String, dynamic>> _membership;

  @override
  void initState() {
    super.initState();
    _membership = _verify();
  }

  Future<Map<String, dynamic>> _verify() {
    return ApiService.instance.verifyMembership(_mobile).then((data) {
      // Show the member's LIVE Business Central points in the app bar.
      if (data['isMember'] == true && data['points'] is Map) {
        final balance = (data['points']['balance'] as num?)?.toInt();
        if (balance != null) Session.instance.setPoints(balance);
      }
      return data;
    });
  }

  void _retry() {
    setState(() {
      _membership = _verify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return ValueListenableBuilder<Customer?>(
      valueListenable: Session.instance.customer,
      builder: (context, customer, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 76,
            titleSpacing: 16,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                  child: Text(
                    (customer?.firstName.characters.first ?? '?').toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer?.name ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded,
                              size: 15, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            t.points(customer?.points ?? 0),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: const [
              Padding(
                padding: EdgeInsetsDirectional.only(end: 12),
                child: LanguageToggleButton(),
              ),
            ],
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            future: _membership,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return _CenteredMessage(
                  icon: null,
                  spinner: true,
                  title: t.verifyingMembership,
                );
              }
              if (snap.hasError) {
                return _CenteredMessage(
                  icon: Icons.wifi_off_rounded,
                  title: t.verifyFailed,
                  subtitle: '${snap.error}',
                  action: FilledButton(
                    onPressed: _retry,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand),
                    child: Text(t.retry),
                  ),
                );
              }
              final isMember = snap.data?['isMember'] == true;
              return isMember
                  ? _MemberCard(mobile: _mobile, t: t)
                  : _CenteredMessage(
                      icon: Icons.person_off_rounded,
                      title: t.notMemberTitle,
                      subtitle: t.notMemberHint,
                    );
            },
          ),
        );
      },
    );
  }
}

/// The membership card (QR) shown only to verified BC members.
class _MemberCard extends StatelessWidget {
  final String mobile;
  final AppStrings t;
  const _MemberCard({required this.mobile, required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.showAtCheckout,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.scanHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            _QrCard(data: mobile),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_iphone_rounded,
                      size: 18, color: AppColors.brand),
                  const SizedBox(width: 8),
                  Text(
                    mobile,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered state used for loading / not-a-member / error.
class _CenteredMessage extends StatelessWidget {
  final IconData? icon;
  final bool spinner;
  final String title;
  final String? subtitle;
  final Widget? action;
  const _CenteredMessage({
    required this.title,
    this.icon,
    this.spinner = false,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (spinner)
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.brand),
              )
            else if (icon != null)
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 46, color: AppColors.brand),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String data;
  const _QrCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Bigger code = easier to scan.
    final side = MediaQuery.of(context).size.width.clamp(300.0, 480.0) * 0.84;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: QrImageView(
        data: data.isEmpty ? 'no-mobile' : data,
        version: QrVersions.auto,
        size: side,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(18),
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        embeddedImage: const AssetImage('assets/images/brand_logo.png'),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(side * 0.15, side * 0.15),
        ),
        embeddedImageEmitsError: false,
      ),
    );
  }
}
