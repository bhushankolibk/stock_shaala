import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../disclaimer/disclaimer_page.dart';
import '../home/home_page.dart';
import '../learn/learn_page.dart';
import '../market/market_page.dart';
import '../simulation/portfolio_page.dart';
import '../profile/profile_page.dart';

/// Bottom-nav container for the 5 main tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    LearnPage(),
    MarketPage(),
    PortfolioPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Daily disclaimer reminder, shown once per day after home loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDailyDisclaimer(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: ''),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded), label: ''),
            BottomNavigationBarItem(
                icon: Icon(Icons.show_chart_rounded), label: ''),
            BottomNavigationBarItem(
                icon: Icon(Icons.work_rounded), label: ''),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: ''),
          ],
        ),
      ),
    );
  }
}
