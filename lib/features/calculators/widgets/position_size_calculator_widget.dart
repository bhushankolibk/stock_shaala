import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class PositionSizeCalculatorWidget extends StatefulWidget {
  const PositionSizeCalculatorWidget({super.key});

  @override
  State<PositionSizeCalculatorWidget> createState() => _PositionSizeCalculatorWidgetState();
}

class _PositionSizeCalculatorWidgetState extends State<PositionSizeCalculatorWidget> {
  final _capitalCtrl = TextEditingController(text: '100000');
  final _riskPctCtrl = TextEditingController(text: '2.0');
  final _entryCtrl = TextEditingController(text: '500');
  final _stopLossCtrl = TextEditingController(text: '480');
  final _targetCtrl = TextEditingController(text: '550');

  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _riskPctCtrl.dispose();
    _entryCtrl.dispose();
    _stopLossCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capital = double.tryParse(_capitalCtrl.text.replaceAll(',', '')) ?? 0.0;
    final riskPct = double.tryParse(_riskPctCtrl.text) ?? 0.0;
    final entry = double.tryParse(_entryCtrl.text.replaceAll(',', '')) ?? 0.0;
    final stopLoss = double.tryParse(_stopLossCtrl.text.replaceAll(',', '')) ?? 0.0;
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '')) ?? 0.0;

    int shareQuantity = 0;
    double maxLossAmount = 0.0;
    double maxProfitAmount = 0.0;
    double capitalRequired = 0.0;
    double rrRatio = 0.0;

    final riskPerShare = (entry - stopLoss).abs();
    final rewardPerShare = (target - entry).abs();

    if (capital > 0 && riskPct > 0 && entry > 0 && riskPerShare > 0) {
      maxLossAmount = capital * (riskPct / 100);
      shareQuantity = (maxLossAmount / riskPerShare).floor();
      capitalRequired = shareQuantity * entry;
      maxProfitAmount = shareQuantity * rewardPerShare;
      rrRatio = rewardPerShare / riskPerShare;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Capital & Risk Inputs Card
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ACCOUNT & RISK SETTINGS', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _inputTextField('Total Capital (₹)', _capitalCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputTextField('Max Risk Per Trade (%)', _riskPctCtrl),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('TRADE PRICE LEVELS', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _inputTextField('Entry Price (₹)', _entryCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputTextField('Stop-Loss (₹)', _stopLossCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _inputTextField('Target (₹)', _targetCtrl)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculated Position Size Card
        GlassCard(
          color: AppColors.card2,
          borderColor: AppColors.blue.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECOMMENDED POSITION SIZE', style: AppTheme.mono(size: 10, color: AppColors.muted)),
                  Pill('R:R 1 : ${rrRatio.toStringAsFixed(1)}', rrRatio >= 2.0 ? AppColors.up : AppColors.accent),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Text(
                      '$shareQuantity Shares',
                      style: AppTheme.mono(size: 34, weight: FontWeight.w900, color: AppColors.blue),
                    ),
                    Text('Capital Required: ${_fmt.format(capitalRequired)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn('Max Loss (Stop Loss)', _fmt.format(maxLossAmount), AppColors.down),
                  _statColumn('Target Profit', _fmt.format(maxProfitAmount), AppColors.up),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pro Trading Tip
        GlassCard(
          color: AppColors.dim,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppColors.up),
                  SizedBox(width: 6),
                  Text('Pro Trader Risk Rule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.up)),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Never risk more than 1-2% of your capital on a single trade. Position sizing ensures you stay profitable even with a 50% win rate if your Risk-to-Reward ratio is 1:2 or higher!',
                style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
