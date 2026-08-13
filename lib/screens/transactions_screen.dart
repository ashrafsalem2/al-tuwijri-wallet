import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/sales_transaction.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/formatters.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle_button.dart';
import 'transaction_detail_screen.dart';

/// Bumped by the shell each time the Sales tab is opened, so the list can
/// refresh the moment the user switches to it (the tab is kept alive by the
/// IndexedStack and would otherwise never reload).
final ValueNotifier<int> salesTabTick = ValueNotifier<int>(0);

/// How often the list quietly re-checks Business Central for new POS sales.
const Duration _pollInterval = Duration(seconds: 15);

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum _StatusFilter { all, completed, refunded }

class _TransactionsScreenState extends State<TransactionsScreen>
    with WidgetsBindingObserver {
  List<SalesTransaction>? _items; // null = still loading the first time
  Object? _error;
  Timer? _timer;

  final _searchCtrl = TextEditingController();
  String _query = '';
  _StatusFilter _status = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    salesTabTick.addListener(_onTabOpened);
    _load();
    _timer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    salesTabTick.removeListener(_onTabOpened);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Apply the search text + status chip to the loaded list.
  List<SalesTransaction> _applyFilters(List<SalesTransaction> all) {
    final q = _query.trim().toLowerCase();
    return all.where((txn) {
      final matchesStatus = switch (_status) {
        _StatusFilter.all => true,
        _StatusFilter.completed => !txn.isRefunded,
        _StatusFilter.refunded => txn.isRefunded,
      };
      if (!matchesStatus) return false;
      if (q.isEmpty) return true;
      final haystack = [
        txn.branch,
        txn.paymentMethod, // receipt no
        txn.total.toStringAsFixed(2),
        txn.total.toStringAsFixed(0),
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  // Refresh when the app comes back to the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  // Refresh the instant the user switches to the Sales tab.
  void _onTabOpened() => _load(silent: true);

  /// Fetch the list. When [silent] the current list stays on screen while the
  /// call runs (no spinner, no flicker) and errors are swallowed so a dropped
  /// poll doesn't wipe good data.
  Future<void> _load({bool silent = false}) async {
    try {
      final data = await ApiService.instance.getTransactions();
      if (!mounted) return;
      setState(() {
        _items = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.myTransactions,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: const [
          ThemeToggleButton(),
          Padding(
            padding: EdgeInsetsDirectional.only(end: 8, start: 4),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppStrings t) {
    if (_items == null && _error != null) {
      return _ErrorState(onRetry: () => _load(), message: '$_error');
    }
    if (_items == null) {
      return Center(child: CircularProgressIndicator());
    }
    final all = _items!;
    final visible = _applyFilters(all);
    // Only show the filter bar once there's something to filter.
    final showFilters = all.isNotEmpty;

    return Column(
      children: [
        if (showFilters) _filterBar(t),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () => _load(silent: true),
            child: (all.isEmpty || visible.isEmpty)
                ? ListView(
                    // ListView so pull-to-refresh still works when empty.
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            all.isEmpty ? t.noTransactions : t.noResults,
                            style: TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, i) => _TransactionCard(
                      txn: visible[i],
                      index: i,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(AppStrings t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.searchTransactionsHint,
              prefixIcon: Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded),
                      tooltip: t.clearSearch,
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _statusChip(t.filterAll, _StatusFilter.all),
              SizedBox(width: 8),
              _statusChip(t.filterCompleted, _StatusFilter.completed),
              SizedBox(width: 8),
              _statusChip(t.filterRefunded, _StatusFilter.refunded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, _StatusFilter value) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final SalesTransaction txn;
  final int index;
  const _TransactionCard({required this.txn, required this.index});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 20), child: child),
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transactionId: txn.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (txn.isRefunded ? AppColors.danger : AppColors.brand)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    txn.isRefunded
                        ? Icons.undo_rounded
                        : Icons.shopping_bag_rounded,
                    color: txn.isRefunded ? AppColors.danger : AppColors.brand,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.branch,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${formatDate(txn.date, locale: t.code)} • ${t.itemsCount(txn.itemsCount)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        formatHijri(txn.date, locale: t.code),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(txn.total, txn.currency, locale: t.code),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: txn.isRefunded
                            ? AppColors.danger
                            : AppColors.textPrimary,
                        decoration: txn.isRefunded
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    _StatusChip(status: txn.status, label: t.status(txn.status)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const _StatusChip({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final refunded = status.toLowerCase() == 'refunded';
    final color = refunded ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;
  const _ErrorState({required this.onRetry, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.danger),
            SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry,
                child: Text(AppStrings.of(context).retry)),
          ],
        ),
      ),
    );
  }
}
