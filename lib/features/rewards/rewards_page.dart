import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/di/injection.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/app_services.dart';
import '../../core/services/content_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/reward_offer_model.dart';

/// Rewards & Offers — referral/partner offers (e.g. "Open a free Upstox
/// account, earn ₹200") pushed entirely from Remote Config, so new
/// partners/campaigns can go live without an app update.
/// See ContentService.loadRewards for the RC key and JSON shape.
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  List<RewardOffer> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offers = await sl<ContentService>().loadRewards();
      if (mounted)
        setState(() {
          _offers = offers;
          _loading = false;
        });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load offers right now.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards & Offers')),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.card,
          onRefresh: _load,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return _messageState(
        emoji: '📡',
        title: 'Could not load offers',
        subtitle: _error!,
        showRetry: true,
      );
    }
    if (_offers.isEmpty) {
      return _messageState(
        emoji: '🎁',
        title: 'No offers right now',
        subtitle: 'Check back soon — new rewards drop regularly.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 24),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Rewards For You',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sign up through our partner links to unlock real cash & credit rewards.',
            style:
                TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _offers.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  _offerCard(_offers[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Image-forward offer card (banner on top, info panel below) — modeled
  /// on how partner-offer feeds (PhonePe/Cred style) present rewards, laid
  /// out as a horizontal scroll row so more offers just extend sideways
  /// rather than growing the page taller. Full details (description,
  /// code, CTA, terms) live in the bottom sheet opened by [_openDetail].
  Widget _offerCard(RewardOffer offer) {
    final gradientStart = _colorFromHex(offer.gradientStart, AppColors.dim);
    final gradientEnd = _colorFromHex(offer.gradientEnd, AppColors.surface);

    return GestureDetector(
      onTap: () => _openDetail(offer),
      child: Container(
        width: 168,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _offerBanner(offer, gradientStart, gradientEnd),
                if (offer.badge.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _badgeChip(offer.badge),
                  ),
              ],
            ),
            Builder(builder: (_) {
              // Primary line prefers the reward highlight; secondary line
              // falls back through title → subtitle. Any field can be
              // blank from Remote Config, so each line is only rendered
              // when it actually has text — an empty Text() still
              // reserves its line-height, which is what left visible
              // gaps in cards for offers missing optional fields.
              final primary = offer.rewardText.isNotEmpty
                  ? offer.rewardText
                  : offer.title;
              final secondary = offer.rewardText.isNotEmpty
                  ? offer.title
                  : offer.subtitle;
              if (primary.isEmpty && secondary.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primary.isNotEmpty)
                      Text(primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text)),
                    if (primary.isNotEmpty && secondary.isNotEmpty)
                      const SizedBox(height: 3),
                    if (secondary.isNotEmpty)
                      Text(secondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                              height: 1.3)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _offerBanner(
      RewardOffer offer, Color gradientStart, Color gradientEnd) {
    const height = 130.0;
    if (offer.bannerUrl.isNotEmpty) {
      return Image.network(
        offer.bannerUrl,
        width: 168,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _bannerFallback(offer, gradientStart, gradientEnd, height),
      );
    }
    return _bannerFallback(offer, gradientStart, gradientEnd, height);
  }

  Widget _bannerFallback(RewardOffer offer, Color gradientStart,
      Color gradientEnd, double height) {
    return Container(
      width: 168,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: _brandLogo(offer, size: 44),
    );
  }

  void _openDetail(RewardOffer offer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OfferDetailSheet(
        offer: offer,
        onCopyCode: _copyCode,
        onClaim: _claim,
      ),
    );
  }

  Future<void> _copyCode(BuildContext sheetContext, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!sheetContext.mounted) return;
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(
        content: Text('Code "$code" copied!'),
        backgroundColor: AppColors.up,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _claim(RewardOffer offer) async {
    await sl<AnalyticsService>()
        .logEvent('reward_offer_claimed', {'offer_id': offer.id});
    if (offer.ctaUrl.isNotEmpty) {
      await AppServices.openUrl(offer.ctaUrl);
    }
  }

  Widget _messageState({
    required String emoji,
    required String title,
    required String subtitle,
    bool showRetry = false,
  }) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.muted)),
                if (showRetry) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _load,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Retry',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _colorFromHex(String hex, Color fallback) {
  final cleaned = hex.replaceAll('#', '').trim();
  if (cleaned.length != 6 && cleaned.length != 8) return fallback;
  final value =
      int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
  return value == null ? fallback : Color(value);
}

Widget _brandLogo(RewardOffer offer, {double size = 34}) {
  if (offer.logoUrl.isEmpty) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text('🏦', style: TextStyle(fontSize: size * 0.46)),
    );
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.28),
    child: Image.network(
      offer.logoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppColors.dim,
        alignment: Alignment.center,
        child: Text('🏦', style: TextStyle(fontSize: size * 0.46)),
      ),
    ),
  );
}

Widget _badgeChip(String badge) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.up.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.up.withValues(alpha: 0.3)),
      ),
      child: Text(badge.toUpperCase(),
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.up)),
    );

/// Full offer detail — opened from a tap on the compact [RewardsPage] list
/// row, so the list itself stays dense even with many offers.
class _OfferDetailSheet extends StatelessWidget {
  final RewardOffer offer;
  final void Function(BuildContext sheetContext, String code) onCopyCode;
  final void Function(RewardOffer offer) onClaim;

  const _OfferDetailSheet({
    required this.offer,
    required this.onCopyCode,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final gradientStart = _colorFromHex(offer.gradientStart, AppColors.dim);
    final gradientEnd = _colorFromHex(offer.gradientEnd, AppColors.surface);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offer.bannerUrl.isNotEmpty)
                Image.network(
                  offer.bannerUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offer.bannerUrl.isEmpty)
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: AppColors.dim2,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        _brandLogo(offer, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(offer.brand.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.muted)),
                        ),
                        if (offer.badge.isNotEmpty) _badgeChip(offer.badge),
                      ],
                    ),
                    if (offer.title.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(offer.title,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: AppColors.text)),
                    ],
                    if (offer.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(offer.subtitle,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.muted,
                              height: 1.4)),
                    ],
                    if (offer.rewardText.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(offer.rewardText,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                    if (offer.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(offer.description,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A9DC0),
                              height: 1.6)),
                    ],
                    if (offer.code.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => onCopyCode(context, offer.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.confirmation_number_outlined,
                                  size: 15, color: AppColors.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(offer.code,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.4,
                                        color: AppColors.text,
                                        fontFamily: 'monospace')),
                              ),
                              const Icon(Icons.copy_rounded,
                                  size: 15, color: AppColors.muted),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => onClaim(offer),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(offer.ctaText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black)),
                      ),
                    ),
                    if (offer.terms.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(offer.terms,
                          style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.muted,
                              height: 1.5,
                              fontStyle: FontStyle.italic)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
