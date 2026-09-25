/// A promotional/referral offer (e.g. "Open a free Upstox Demat account
/// and earn ₹200") shown on the Rewards page. Fully driven by Remote
/// Config so new offers/partners can be pushed without an app update —
/// see ContentService.loadRewards.
class RewardOffer {
  final String id;
  final String brand;
  final String logoUrl;
  final String bannerUrl;
  final String title;
  final String subtitle;
  final String description;
  final String rewardText;
  final String code;
  final String ctaText;
  final String ctaUrl;
  final String badge;
  final String terms;
  final String gradientStart;
  final String gradientEnd;
  final bool isActive;
  final int order;

  const RewardOffer({
    required this.id,
    required this.brand,
    required this.logoUrl,
    required this.bannerUrl,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.rewardText,
    required this.code,
    required this.ctaText,
    required this.ctaUrl,
    required this.badge,
    required this.terms,
    required this.gradientStart,
    required this.gradientEnd,
    required this.isActive,
    required this.order,
  });

  factory RewardOffer.fromJson(Map<String, dynamic> json) => RewardOffer(
        id: json['id'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        logoUrl: json['logo_url'] as String? ?? '',
        bannerUrl: json['banner_url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        description: json['description'] as String? ?? '',
        rewardText: json['reward_text'] as String? ?? '',
        code: json['code'] as String? ?? '',
        ctaText: json['cta_text'] as String? ?? 'Claim Offer',
        ctaUrl: json['cta_url'] as String? ?? '',
        badge: json['badge'] as String? ?? '',
        terms: json['terms'] as String? ?? '',
        gradientStart: json['gradient_start'] as String? ?? '#1A2840',
        gradientEnd: json['gradient_end'] as String? ?? '#0F1923',
        isActive: json['is_active'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
