import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The reusable list of disclaimer points (shared by full screen + sheet).
class DisclaimerPoints extends StatelessWidget {
  const DisclaimerPoints({super.key});

  static const points = [
    (
      icon: '🚫',
      bg: Color(0x1AFF4D6A),
      title: 'No Tips or Recommendations',
      body:
          'हम कोई stock buy/sell की सलाह नहीं देते। सभी examples सिर्फ learning के लिए हैं।'
    ),
    (
      icon: '🎓',
      bg: Color(0x1A3B82F6),
      title: 'Educational Purpose Only',
      body:
          'StockShaala stock market के concepts सिखाने के लिए बना है — real investment के लिए नहीं।'
    ),
    (
      icon: '🎮',
      bg: Color(0x1A00C896),
      title: 'Virtual Trading = Simulation',
      body:
          'Portfolio में इस्तेमाल होने वाला पैसा पूरी तरह virtual है। Real money से कोई संबंध नहीं।'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in points)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(13),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(p.icon,
                      style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(p.body,
                          style: const TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: Color(0xFF8A9DC0))),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// SEBI non-registration notice.
class SebiNotice extends StatelessWidget {
  const SebiNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'StockShaala is not registered with SEBI as an Investment Advisor. '
              'All market data is for educational and simulation purposes only. '
              'Past performance does not guarantee future returns.',
              style: TextStyle(
                  fontSize: 9,
                  height: 1.55,
                  color: AppColors.accent.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }
}
