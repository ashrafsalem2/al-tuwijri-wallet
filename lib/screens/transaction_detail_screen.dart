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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.transactionId,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<TransactionDetail>(
        future: _future,
        builder: (context, snapshot) {
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
        },
      ),
    );
  }

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
          _meta(Icons.credit_card_rounded, t.payment, detail.paymentMethod),
          _meta(Icons.person_outline_rounded, t.cashier, detail.cashier),
          _meta(Icons.store_mall_directory_outlined, t.branch, detail.branch),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String label, String value) {
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
