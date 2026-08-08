import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/sales_transaction.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/formatters.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Future<TransactionDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.getTransactionDetail(widget.transactionId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransactionDetail>(
      future: _future,
      builder: (context, snapshot) {
        // Once loaded, title the screen with the receipt number (detail.id);
        // until then, fall back to the id we navigated with.
        final title = snapshot.hasData ? snapshot.data!.id : widget.transactionId;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            final d = snapshot.data!;
            final t = AppStrings.of(context);
            return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              _HeaderCard(detail: d),
              // Scannable receipt barcode — only within 14 days of the sale, so
              // the cashier can pull up the receipt for a refund.
              if (_isBarcodeActive(d.date)) ...[
                const SizedBox(height: 12),
                _ReceiptBarcode(
                  data: d.id,
                  // A refund receipt shows only the bare barcode — no notes.
                  hint: d.isRefunded ? null : t.refundBarcodeHint,
                  note: d.isRefunded ? null : t.refundBarcodeValidity,
                ),
              ],
              const SizedBox(height: 16),
              _sectionTitle(t.items),
              const SizedBox(height: 8),
              _ItemsCard(items: d.items, currency: d.currency),
              const SizedBox(height: 16),
              _sectionTitle(t.summary),
              const SizedBox(height: 8),
              _SummaryCard(detail: d),
              const SizedBox(height: 16),
              _sectionTitle(t.details),
              const SizedBox(height: 8),
              _MetaCard(detail: d),
            ],
          );
          }),
        );
      },
    );
  }

  /// The refund barcode is valid for 3 days from the sale date.
  bool _isBarcodeActive(DateTime saleDate) =>
      DateTime.now().difference(saleDate).inDays <= 3;

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      );
}

class _HeaderCard extends StatelessWidget {
  final TransactionDetail detail;
  const _HeaderCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  detail.branch,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.status(detail.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatDateTime(detail.date, locale: t.code),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5),
          ),
          const SizedBox(height: 2),
          Text(
            formatHijri(detail.date, locale: t.code),
            style: const TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Text(
            formatMoney(detail.total, detail.currency, locale: t.code),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// White card holding the scannable Code-128 barcode of the receipt number.
/// Shown in the detail header so the cashier can scan it to retrieve the
/// receipt when processing a refund.
class _ReceiptBarcode extends StatelessWidget {
  final String data;
  final String? hint;
  final String? note;
  const _ReceiptBarcode({
    required this.data,
    this.hint,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (hint != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: data,
            width: double.infinity,
            height: 74,
            drawText: true,
            color: Colors.black,
            backgroundColor: Colors.white,
            style: const TextStyle(
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.accent),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    note!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final List<TransactionItem> items;
  final String currency;
  const _ItemsCard({required this.items, required this.currency});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${items[i].qty}×',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          t.each(formatMoney(items[i].unitPrice, currency,
                              locale: t.code)),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(items[i].lineTotal, currency, locale: t.code),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              Divider(height: 1, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final TransactionDetail detail;
  const _SummaryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _row(t.subtotal,
              formatMoney(detail.subtotal, detail.currency, locale: t.code)),
          if (detail.discount > 0)
            _row(t.discount,
                '- ${formatMoney(detail.discount, detail.currency, locale: t.code)}'),
          _row(t.vat, formatMoney(detail.vat, detail.currency, locale: t.code)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          _row(
            t.total,
            formatMoney(detail.total, detail.currency, locale: t.code),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final TransactionDetail detail;
  const _MetaCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _meta(Icons.confirmation_number_outlined, t.transactionId, detail.id),
          // Hidden until BC exposes the real tender type (see backend notes).
          _meta(Icons.credit_card_rounded, t.payment, detail.paymentMethod),
          _meta(Icons.person_outline_rounded, t.cashier, detail.cashier),
          _meta(Icons.store_mall_directory_outlined, t.branch, detail.branch),
        ],
      ),
    );
  }

  /// A meta row — renders nothing when the value is blank.
  Widget _meta(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.brand),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
