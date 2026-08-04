import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_strings.dart';
import '../models/customer.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/language_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return ValueListenableBuilder<Customer?>(
      valueListenable: Session.instance.customer,
      builder: (context, customer, _) {
        final mobile = customer?.mobile ?? '';
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
          body: Center(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          ),
        );
      },
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
        // Quiet zone: clean white margin around the code (~4 modules).
        padding: const EdgeInsets.all(18),
        // High error correction (~30%) so the centered logo does NOT make the
        // code unscannable — required whenever an embedded image is used.
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        // Standard square modules + black for maximum contrast: the biggest
        // reliability win for hardware/phone scanners.
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        // Small centered logo so it covers as little of the code as possible.
        embeddedImage: const AssetImage('assets/images/brand_logo.png'),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(side * 0.15, side * 0.15),
        ),
        // If the logo asset is missing, still render the QR cleanly.
        embeddedImageEmitsError: false,
      ),
    );
  }
}
