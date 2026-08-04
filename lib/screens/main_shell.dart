import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/stylish_bottom_nav.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    TransactionsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: StylishBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          StylishNavItem(
            icon: Icons.qr_code_2_outlined,
            activeIcon: Icons.qr_code_2_rounded,
            label: t.navCard,
          ),
          StylishNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: t.navSales,
          ),
          StylishNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: t.navProfile,
          ),
        ],
      ),
    );
  }
}
