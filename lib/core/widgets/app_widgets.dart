import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A rounded card matching the UI mockups.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// Small status pill (streak, XP, etc.).
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Primary gradient button.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const PrimaryButton(this.label, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
      ),
    );
  }
}

/// Ticker badge (3-letter colored square).
class TickerBadge extends StatelessWidget {
  final String symbol;
  final Color color;
  const TickerBadge(this.symbol, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        symbol.length >= 3 ? symbol.substring(0, 3) : symbol,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  static Color colorFor(String symbol) {
    final colors = [
      AppColors.blue,
      AppColors.accent,
      AppColors.up,
      AppColors.purple,
      AppColors.down,
    ];
    return colors[symbol.hashCode.abs() % colors.length];
  }
}
