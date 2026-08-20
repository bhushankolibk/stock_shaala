import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class CagrCalculatorWidget extends StatefulWidget {
  const CagrCalculatorWidget({super.key});

  @override
  State<CagrCalculatorWidget> createState() => _CagrCalculatorWidgetState();
}

class _CagrCalculatorWidgetState extends State<CagrCalculatorWidget> {
  final _initialController = TextEditingController(text: '100000');
  final _finalController = TextEditingController(text: '250000');
  double _years = 5.0;

  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _initialController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialVal = double.tryParse(_initialController.text.replaceAll(',', '')) ?? 0.0;
    final finalVal = double.tryParse(_finalController.text.replaceAll(',', '')) ?? 0.0;

    double cagrPct = 0.0;
    double absReturnPct = 0.0;
    double multiplier = 1.0;
    double totalGain = max(0.0, finalVal - initialVal);

    if (initialVal > 0 && finalVal > 0 && _years > 0) {
      cagrPct = (pow(finalVal / initialVal, 1 / _years) - 1) * 100;
      absReturnPct = ((finalVal - initialVal) / initialVal) * 100;
      multiplier = finalVal / initialVal;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Input Fields Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INITIAL & FINAL VALUE', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inputTextField(
                      label: 'Initial Value (₹)',
                      controller: _initialController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputTextField(
                      label: 'Final Value (₹)',
                      controller: _finalController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Investment Period (Years)', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text('${_years.toInt()} Year${_years.toInt() > 1 ? 's' : ''}',
                      style: AppTheme.mono(size: 13, weight: FontWeight.bold, color: AppColors.text)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.dim,
                  thumbColor: AppColors.accent,
                  trackHeight: 3,
                ),
                child: Slider(
                  value: _years.clamp(1.0, 30.0),
                  min: 1.0,
                  max: 30.0,
                  divisions: 29,
                  onChanged: (v) => setState(() => _years = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CAGR Results Card
        GlassCard(
          color: AppColors.card2,
          borderColor: AppColors.up.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('COMPOUNDED ANNUAL GROWTH RATE', style: AppTheme.mono(size: 10, color: AppColors.muted)),
                  Pill('${multiplier.toStringAsFixed(2)}x Growth', AppColors.up),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${cagrPct.toStringAsFixed(2)}%',
                      style: AppTheme.mono(
                        size: 36,
                        weight: FontWeight.w900,
                        color: cagrPct >= 0 ? AppColors.up : AppColors.down,
                      ),
                    ),
                    const Text('Annualized CAGR (per year)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn('Absolute Return', '${absReturnPct.toStringAsFixed(1)}%', AppColors.blue),
                  _statColumn('Total Profit Gained', _fmt.format(totalGain), AppColors.up),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Educational Insight Card
        GlassCard(
          color: AppColors.dim,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accent),
                  SizedBox(width: 6),
                  Text('CAGR vs Absolute Return',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Absolute Return shows overall percentage profit, while CAGR calculates smoothed yearly growth rate accounting for compounding. Mutual funds and stocks are compared using CAGR!',
                style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputTextField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTheme.mono(size: 13, weight: FontWeight.bold),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true,
            fillColor: AppColors.dim,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
          ),
        ),
      ],
    );
  }

  Widget _statColumn(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.mono(size: 14, weight: FontWeight.bold, color: color)),
      ],
    );
  }
}
