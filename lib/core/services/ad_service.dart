import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// Wraps AdMob banner / interstitial / rewarded ad loading and display.
class AdService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  Future<void> init() => MobileAds.instance.initialize().then((_) {});

  /// Loads a single native ad rendered by the "listTileNative" Android
  /// factory (see ListTileNativeAdFactory.kt), styled to blend into the
  /// app's card-based feeds. Each call produces one ad — callers own and
  /// dispose the returned [NativeAd] themselves (see NativeAdCard).
  NativeAd createNativeAd({
    required void Function(NativeAd ad) onLoaded,
    required void Function() onFailed,
  }) {
    return NativeAd(
      adUnitId: AppConstants.admobAdvanceNativeId,
      factoryId: 'listTileNative',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onLoaded(ad as NativeAd),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          onFailed();
        },
      ),
    )..load();
  }

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

  /// Shows the preloaded interstitial, if any. [onAdClosed] fires once the
  /// ad is dismissed or fails to show — pass it when the caller needs to
  /// wait for the ad to close before proceeding (e.g. navigating).
  void showInterstitialIfReady({void Function()? onAdClosed}) {
    final ad = _interstitial;
    if (ad == null) {
      onAdClosed?.call();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        loadInterstitial();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        loadInterstitial();
        onAdClosed?.call();
      },
    );
    ad.show();
  }

  int _quickFeatureTaps = 0;

  /// Frequency-capped interstitial for tap-throughs into a feature hub
  /// (e.g. the home "Quick Features" grid). Showing a full-screen ad on
  /// every single tap tanks navigation feel and burns through inventory,
  /// so only every [everyNTaps]th tap even attempts one, and only when a
  /// preloaded ad is actually ready.
  ///
  /// Returns true if an ad was shown — the caller should navigate from
  /// [onAdClosed] instead of immediately, so the ad isn't skipped past.
  /// Returns false if this tap didn't trigger an ad (not the Nth tap, or
  /// none was ready) — the caller should navigate immediately instead.
  bool maybeShowQuickFeatureInterstitial({
    required void Function() onAdClosed,
    int everyNTaps = 5,
  }) {
    _quickFeatureTaps++;
    if (_quickFeatureTaps % everyNTaps != 0 || _interstitial == null) {
      return false;
    }
    showInterstitialIfReady(onAdClosed: onAdClosed);
    return true;
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
