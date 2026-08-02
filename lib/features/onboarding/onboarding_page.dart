import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/services/disclaimer_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      emoji: '📊',
      badge: 'Free',
      badgeColor: AppColors.up,
      headline: 'शेयर बाज़ार सीखें,\nआसान हिंदी में',
      sub:
          'Beginner से Expert तक — step by step। कोई finance degree की ज़रूरत नहीं।'
    ),
    (
      emoji: '🎮',
      badge: '₹5K Virtual',
      badgeColor: AppColors.purple,
      headline: 'Virtual Trading से\nPractice करें',
      sub:
          '₹5,000 virtual cash के साथ NSE stocks खरीदें-बेचें। Ad देखकर और cash भी पाएं। Real money का कोई risk नहीं।'
    ),
    (
      emoji: '🔥',
      badge: 'Daily',
      badgeColor: AppColors.accent,
      headline: 'Streak बनाएं,\nXP कमाएं',
      sub:
          'रोज़ एक challenge हल करें, streak बढ़ाएं और badges unlock करें।'
    ),
  ];

  Future<void> _finish() async {
    await sl<DisclaimerService>()
        .prefs
        .setBool(AppConstants.kOnboardingDone, true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : AppColors.dim2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 170,
                              height: 150,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(s.emoji,
                                  style: const TextStyle(fontSize: 58)),
                            ),
                            Positioned(
                              bottom: -12,
                              right: -12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: s.badgeColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(s.badge,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        Text(s.headline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                height: 1.3)),
                        const SizedBox(height: 10),
                        Text(s.sub,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.65,
                                color: AppColors.muted)),
                      ],
                    );
                  },
                ),
              ),
              PrimaryButton(
                  _page == _slides.length - 1 ? 'Get Started →' : 'Next →',
                  onTap: _next),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _finish,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Skip',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
