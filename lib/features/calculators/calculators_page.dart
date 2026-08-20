import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/cagr_calculator_widget.dart';
import 'widgets/position_size_calculator_widget.dart';
import 'widgets/sip_calculator_widget.dart';

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Financial Calculators 🧮',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.dim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _navTab(0, 'SIP / Lumpsum'),
                    _navTab(1, 'CAGR'),
                    _navTab(2, 'Position Size'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SipCalculatorWidget(),
          CagrCalculatorWidget(),
          PositionSizeCalculatorWidget(),
        ],
      ),
    );
  }

  Widget _navTab(int index, String label) {
    final active = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? Colors.black : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
