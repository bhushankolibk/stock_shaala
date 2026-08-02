import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// Wraps AdMob banner / interstitial / rewarded ad loading and display.
class AdService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  Future<void> init() => MobileAds.instance.initialize().then((_) {});

  BannerAd createBannerAd({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: AppConstants.admobBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => onLoaded()),
    )..load();
  }

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  void showInterstitialIfReady() {
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        loadInterstitial();
      },
    );
    ad.show();
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: AppConstants.admobRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  /// Shows a rewarded ad if one is loaded. [onReward] fires only when the
  /// user actually earns the reward. [onAdClosed] fires once the ad is
  /// dismissed or fails to show, regardless of whether the reward was
  /// earned — use it to resume an action that should proceed either way.
  /// Returns false (no-op) if no ad is ready — callers should fall back to
  /// granting the action directly so ad inventory never blocks a core
  /// feature.
  bool showRewarded({
    required void Function() onReward,
    void Function()? onAdClosed,
  }) {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadRewarded();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        loadRewarded();
        onAdClosed?.call();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onReward());
    return true;
  }
}
