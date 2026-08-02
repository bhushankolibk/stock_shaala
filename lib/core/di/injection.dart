import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../services/ad_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/blogger_service.dart';
import '../services/content_service.dart';
import '../services/disclaimer_service.dart';
import '../services/equity_list_service.dart';
import '../services/local_db_service.dart';
import '../services/market_api_service.dart';
import '../services/market_overview_service.dart';
import '../services/messaging_service.dart';
import '../services/progress_service.dart';
import '../services/stock_news_service.dart';
import '../services/stock_quote_service.dart';
import '../services/watchlist_service.dart';
import '../services/youtube_service.dart';
import '../../features/simulation/portfolio_repository.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  FirebaseRemoteConfig? rc;
  try {
    rc = FirebaseRemoteConfig.instance;
  } catch (_) {
    rc = null;
  }

  // Services
  sl.registerSingleton<AuthService>(AuthService());
  sl.registerSingleton<LocalDbService>(LocalDbService());
  sl.registerSingleton<MarketApiService>(MarketApiService());
  sl.registerSingleton<ProgressService>(ProgressService(prefs));
  sl.registerSingleton<DisclaimerService>(DisclaimerService(prefs));
  sl.registerSingleton<WatchlistService>(WatchlistService(prefs));

  final content = ContentService(rc);
  await content.init();
  sl.registerSingleton<ContentService>(content);

  // Read the API credentials — Remote Config wins, AppConstants are fallback
  final rcApiKey = rc?.getString('google_api_key') ?? '';
  final rcBlogId = rc?.getString('blogger_blog_id') ?? '';
  final rcChannelId = rc?.getString('youtube_channel_id') ?? '';

  final apiKey = rcApiKey.isNotEmpty ? rcApiKey : AppConstants.googleApiKey;
  final blogId = rcBlogId.isNotEmpty ? rcBlogId : AppConstants.bloggerBlogId;
  final channelId =
      rcChannelId.isNotEmpty ? rcChannelId : AppConstants.youtubeChannelId;

  sl.registerSingleton<BloggerService>(
      BloggerService(blogId: blogId, apiKey: apiKey));
  sl.registerSingleton<YouTubeService>(
      YouTubeService(channelId: channelId, apiKey: apiKey));

  final upstoxToken = rc?.getString('upstox_analytics_token') ?? '';
  sl.registerSingleton<StockNewsService>(
      StockNewsService(token: upstoxToken));
  sl.registerSingleton<StockQuoteService>(
      StockQuoteService(token: upstoxToken));
  sl.registerSingleton<EquityListService>(EquityListService());
  sl.registerSingleton<MarketOverviewService>(
      MarketOverviewService(sl<StockQuoteService>(), sl<EquityListService>()));

  // Repositories
  sl.registerSingleton<PortfolioRepository>(
    PortfolioRepository(sl<LocalDbService>(), sl<MarketApiService>()),
  );

  // Ads
  final ads = AdService();
  await ads.init();
  ads.loadInterstitial();
  ads.loadRewarded();
  sl.registerSingleton<AdService>(ads);

  // Analytics & Messaging
  FirebaseAnalytics? analytics;
  try {
    analytics = FirebaseAnalytics.instance;
  } catch (_) {
    analytics = null;
  }
  sl.registerSingleton<AnalyticsService>(AnalyticsService(analytics));
  sl.registerSingleton<MessagingService>(MessagingService());
}
