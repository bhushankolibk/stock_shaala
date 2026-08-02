import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import '../../core/services/disclaimer_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import 'disclaimer_content.dart';

/// Full-screen disclaimer shown ONCE on first ever launch.
class DisclaimerPage extends StatefulWidget {
  const DisclaimerPage({super.key});

  @override
  State<DisclaimerPage> createState() => _DisclaimerPageState();
}

class _DisclaimerPageState extends State<DisclaimerPage> {
  bool _accepted = false;

  Future<void> _continue() async {
    await sl<DisclaimerService>().acceptOnce();
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF060F1E), Color(0xFF0A1428), Color(0xFF060C18)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A0E0E), Color(0xFF2A1010)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.down.withValues(alpha: 0.3)),
                  ),
                  child: const Text('⚠️', style: TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'यह सिर्फ एक '),
                    TextSpan(
                        text: 'Educational',
                        style: TextStyle(color: AppColors.down)),
                    TextSpan(text: ' App है'),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: AppColors.text),
                ),
                const SizedBox(height: 6),
                const Text('आगे बढ़ने से पहले यह ज़रूर पढ़ें',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 18),
                const DisclaimerPoints(),
                const SizedBox(height: 4),
                const SebiNotice(),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _accepted = !_accepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _accepted
                              ? AppColors.accent.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.accent, width: 1.5),
                        ),
                        child: _accepted
                            ? const Icon(Icons.check,
                                size: 12, color: AppColors.accent)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'मैंने पढ़ लिया और समझता/समझती हूँ कि यह app सिर्फ educational है।',
                          style: TextStyle(
                              fontSize: 10,
                              height: 1.5,
                              color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: _accepted ? 1 : 0.4,
                  child: PrimaryButton(
                    'I Understand, Continue →',
                    onTap: _accepted ? _continue : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Daily reminder bottom sheet. Call [showDailyDisclaimer] on home open.
Future<void> showDailyDisclaimer(BuildContext context) async {
  final service = sl<DisclaimerService>();
  if (!service.shouldShowDailyReminder) return;
  await service.markShownToday();

  if (!context.mounted) return;
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card2,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.dim2,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1A0E0E), Color(0xFF2A1010)]),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                      color: AppColors.down.withValues(alpha: 0.3)),
                ),
                child: const Text('⚠️', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Educational',
                          style: TextStyle(color: AppColors.down)),
                      TextSpan(text: ' App Only'),
                    ]),
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text('DAILY REMINDER',
                      style: TextStyle(fontSize: 9, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'StockShaala सिर्फ stock market सीखने के लिए है। हम कोई investment advice या tips नहीं देते।',
            style: TextStyle(
                fontSize: 11, height: 1.6, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          PrimaryButton('Samajh Gaya, Continue →',
              onTap: () => Navigator.pop(ctx)),
        ],
      ),
    ),
  );
}
