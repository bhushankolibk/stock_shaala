import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/game_round_model.dart';

class CandlestickChartPainter extends CustomPainter {
  final List<CandleData> visibleCandles;
  final List<CandleData> hiddenCandles;
  final double revealProgress;
  final bool isRevealed;

  CandlestickChartPainter({
    required this.visibleCandles,
    required this.hiddenCandles,
    required this.revealProgress,
    required this.isRevealed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allCount = visibleCandles.length + hiddenCandles.length;
    if (allCount == 0) return;

    final revealCount = (hiddenCandles.length * revealProgress).clamp(0, hiddenCandles.length).toInt();
    final candlesToDraw = [
      ...visibleCandles,
      ...hiddenCandles.take(revealCount),
    ];

    // Compute min / max price for scaling
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    final referenceSet = isRevealed ? [...visibleCandles, ...hiddenCandles] : visibleCandles;
    for (final c in referenceSet) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    if (minPrice == maxPrice) {
      minPrice -= 1;
      maxPrice += 1;
    }

    final pricePadding = (maxPrice - minPrice) * 0.14;
    minPrice -= pricePadding;
    maxPrice += pricePadding;
    final priceRange = maxPrice - minPrice;

    // Reserve 55px on right for Price Axis Labels & Badges
    const rightPadding = 55.0;
    final chartWidth = size.width - rightPadding;

    // Y scaling helper
    double getY(double price) {
      final norm = (price - minPrice) / priceRange;
      return size.height - (norm * size.height);
    }

    // 1. Draw Grid Lines & Price Labels
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      // Price Label text along right axis
      final linePrice = maxPrice - (i / gridLines) * priceRange;
      final priceStr = linePrice >= 1000 ? linePrice.toStringAsFixed(0) : linePrice.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(
          text: priceStr,
          style: const TextStyle(color: AppColors.muted, fontSize: 9, fontFamily: 'monospace'),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(chartWidth + 6, y - (tp.height / 2)));
    }

    final candleWidth = chartWidth / allCount;
    final bodyWidth = math.max(3.0, candleWidth * 0.65);

    // 2. Paint visible & revealed candles
    for (int i = 0; i < candlesToDraw.length; i++) {
      final c = candlesToDraw[i];
      final xCenter = (i * candleWidth) + (candleWidth / 2);

      final isBull = c.isBullish;
      final color = isBull ? AppColors.up : AppColors.down;

      final stemPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5;

      final bodyPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Draw wick
      final yHigh = getY(c.high);
      final yLow = getY(c.low);
      canvas.drawLine(Offset(xCenter, yHigh), Offset(xCenter, yLow), stemPaint);

      // Draw body
      final yOpen = getY(c.open);
      final yClose = getY(c.close);
      final top = math.min(yOpen, yClose);
      final bottom = math.max(yOpen, yClose);
      final height = math.max(2.0, bottom - top);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xCenter - (bodyWidth / 2), top, bodyWidth, height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, bodyPaint);
    }

    // 3. Draw Price Line & Price Badge for Latest Candle
    if (candlesToDraw.isNotEmpty) {
      final lastCandle = candlesToDraw.last;
      final lastY = getY(lastCandle.close);
      final lastColor = lastCandle.isBullish ? AppColors.up : AppColors.down;

      // Dashed horizontal price line
      final linePaint = Paint()
        ..color = lastColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.0;

      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0;
      while (startX < chartWidth) {
        canvas.drawLine(
          Offset(startX, lastY),
          Offset(math.min(startX + dashWidth, chartWidth), lastY),
          linePaint,
        );
        startX += dashWidth + dashSpace;
      }

      // Price Tag Pill Badge on right axis
      final priceTagStr = lastCandle.close >= 1000
          ? lastCandle.close.toStringAsFixed(0)
          : lastCandle.close.toStringAsFixed(1);
      final tagTp = TextPainter(
        text: TextSpan(
          text: priceTagStr,
          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      tagTp.layout();

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          chartWidth + 3,
          lastY - (tagTp.height / 2) - 2,
          tagTp.width + 8,
          tagTp.height + 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(badgeRect, Paint()..color = lastColor);
      tagTp.paint(canvas, Offset(chartWidth + 7, lastY - (tagTp.height / 2)));
    }

    // 4. Draw Mystery Zone if not fully revealed
    if (!isRevealed || revealProgress < 1.0) {
      final mysteryStartX = visibleCandles.length * candleWidth + (revealCount * candleWidth);
      final mysteryWidth = chartWidth - mysteryStartX;

      if (mysteryWidth > 0) {
        final mysteryPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.purple.withValues(alpha: 0.12),
              AppColors.purple.withValues(alpha: 0.35),
            ],
          ).createShader(Rect.fromLTWH(mysteryStartX, 0, mysteryWidth, size.height));

        final mysteryBorder = Paint()
          ..color = AppColors.purple.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final mysteryRect = Rect.fromLTWH(mysteryStartX, 4, mysteryWidth, size.height - 8);
        canvas.drawRRect(RRect.fromRectAndRadius(mysteryRect, const Radius.circular(8)), mysteryPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(mysteryRect, const Radius.circular(8)), mysteryBorder);

        // Mystery text / icon
        const textStyle = TextStyle(
          color: AppColors.purple,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        );
        final textPainter = TextPainter(
          text: const TextSpan(text: '❓ BREAKOUT ZONE', style: textStyle),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        if (mysteryWidth > textPainter.width + 6) {
          textPainter.paint(
            canvas,
            Offset(mysteryStartX + (mysteryWidth - textPainter.width) / 2, (size.height - textPainter.height) / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickChartPainter oldDelegate) {
    return oldDelegate.visibleCandles != visibleCandles ||
        oldDelegate.hiddenCandles != hiddenCandles ||
        oldDelegate.revealProgress != revealProgress ||
        oldDelegate.isRevealed != isRevealed;
  }
}
