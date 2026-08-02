class AppConstants {
  AppConstants._();

  static const appName = 'StockShaala';
  static const appTagline = 'शेयर बाज़ार की पाठशाला';

  // Virtual trading
  static const double startingVirtualCash = 5000.0;
  static const double rewardedCashTopUp = 5000.0;

  // SharedPreferences keys
  static const kDisclaimerAccepted = 'disclaimer_accepted';
  static const kLastDisclaimerDate = 'last_disclaimer_date';
  static const kOnboardingDone = 'onboarding_done';
  static const kLanguage = 'language'; // 'hi' | 'en'

  // Streak / XP keys
  static const kStreakCount = 'streak_count';
  static const kLastActiveDate = 'last_active_date';
  static const kTotalXp = 'total_xp';
  static const kCompletedLessons = 'completed_lessons';
  static const kDailyChallengeDate = 'daily_challenge_date';
  static const kDailyChallengeAnswer = 'daily_challenge_answer';

  // Content API credentials — override via Firebase Remote Config keys:
  // google_api_key, blogger_blog_id, youtube_channel_id
  static const googleApiKey = 'AIzaSyBAsA7Lmect_Zgv6yX-ZXL5P3ujN_A65uE';
  static const bloggerBlogId = '523728309004569387';
  static const youtubeChannelId = 'UCMtwwi8NDASZ0zaqSN8b86w';

  // External links (replace with your real ones)
  static const playStoreId = 'com.bhushan.stockshaala';
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=$playStoreId';
  static const privacyPolicyUrl =
      'https://storage.googleapis.com/stockshaala/privacy_policy.html';

  // AdMob
  static const admobAppId = 'ca-app-pub-3382293395340097~8765684945';
  static const admobBannerId = 'ca-app-pub-3382293395340097/3630163948';
  static const admobInterstitialId = 'ca-app-pub-3382293395340097/5014408127';
  static const admobRewardedId = 'ca-app-pub-3382293395340097/1075163113';

  static const kLessonCompletionCount = 'lesson_completion_count';

  // Watchlist — stored fully on-device, no API involved.
  static const kWatchlistItems = 'watchlist_items';
}
