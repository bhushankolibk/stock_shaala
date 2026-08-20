import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class SipCalculatorWidget extends StatefulWidget {
  const SipCalculatorWidget({super.key});

  @override
  State<SipCalculatorWidget> createState() => _SipCalculatorWidgetState();
}

class _SipCalculatorWidgetState extends State<SipCalculatorWidget> {
  bool _isSip = true; // true = SIP, false = Lumpsum
  double _monthlyAmount = 5000;
  double _lumpsumAmount = 100000;
  double _expectedReturn = 12.0;
  double _years = 10.0;

  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final invested = _isSip
        ? _monthlyAmount * 12 * _years
        : _lumpsumAmount;

    final totalValue = _isSip
        ? _calculateSipFutureValue(_monthlyAmount, _expectedReturn, _years.toInt())
        : _calculateLumpsumFutureValue(_lumpsumAmount, _expectedReturn, _years.toInt());

    final returnsGained = max(0.0, totalValue - invested);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Mode Switcher (SIP vs Lumpsum)
        Row(
          children: [
            Expanded(child: _modeButton('SIP (Monthly)', _isSip, () => setState(() => _isSip = true))),
            const SizedBox(width: 10),
            Expanded(child: _modeButton('Lumpsum (One-Time)', !_isSip, () => setState(() => _isSip = false))),
          ],
        ),
        const SizedBox(height: 16),

        // Input Controls Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sliderControl(
                label: _isSip ? 'Monthly Investment' : 'Total Lumpsum Investment',
                valueStr: _fmt.format(_isSip ? _monthlyAmount : _lumpsumAmount),
                value: _isSip ? _monthlyAmount : _lumpsumAmount,
                min: 500,
                max: _isSip ? 100000 : 1000000,
                divisions: 199,
                onChanged: (v) => setState(() {
                  if (_isSip) {
                    _monthlyAmount = v;
                  } else {
                    _lumpsumAmount = v;
                  }
                }),
              ),
              const SizedBox(height: 14),
              _sliderControl(
                label: 'Expected Return Rate (p.a.)',
                valueStr: '${_expectedReturn.toStringAsFixed(1)}%',
                value: _expectedReturn,
                min: 1.0,
                max: 30.0,
                divisions: 290,
                onChanged: (v) => setState(() => _expectedReturn = v),
              ),
              const SizedBox(height: 14),
              _sliderControl(
                label: 'Time Horizon (Years)',
                valueStr: '${_years.toInt()} Yr${_years.toInt() > 1 ? 's' : ''}',
                value: _years,
                min: 1.0,
                max: 30.0,
                divisions: 29,
                onChanged: (v) => setState(() => _years = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result & Pie Chart Display Card
        GlassCard(
          color: AppColors.card2,
          borderColor: AppColors.accent.withValues(alpha: 0.3),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ESTIMATED WEALTH', style: AppTheme.mono(size: 10, color: AppColors.muted)),
                  Pill('Compounded', AppColors.accent),
                ],
              ),
              const SizedBox(height: 14),

              // Pie Chart & Legend Row
              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 32,
                          sections: [
                            PieChartSectionData(
                              color: AppColors.blue,
                              value: invested,
                              title: '',
                              radius: 22,
                            ),
                            PieChartSectionData(
                              color: AppColors.up,
                              value: returnsGained,
                              title: '',
                              radius: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem('Invested Amount', _fmt.format(invested), AppColors.blue),
                          const SizedBox(height: 10),
                          _legendItem('Est. Wealth Gained', _fmt.format(returnsGained), AppColors.up),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 24),

              // Total Future Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Future Value:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(_fmt.format(totalValue),
                      style: AppTheme.mono(size: 18, weight: FontWeight.w900, color: AppColors.accent)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.accent : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: active ? AppColors.accent : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sliderControl({
    required String label,
    required String valueStr,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            Text(valueStr, style: AppTheme.mono(size: 13, weight: FontWeight.bold, color: AppColors.text)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.dim,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.2),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String title, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              Text(value, style: AppTheme.mono(size: 12, weight: FontWeight.bold, color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }

  double _calculateSipFutureValue(double monthlyP, double rate, int years) {
    final i = rate / 12 / 100;
    final n = years * 12;
    if (i == 0) return monthlyP * n;
    return monthlyP * ((pow(1 + i, n) - 1) / i) * (1 + i);
  }

  double _calculateLumpsumFutureValue(double p, double rate, int years) {
    return p * pow(1 + (rate / 100), years);
  }
}
