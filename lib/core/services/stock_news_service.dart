import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/stock_news_model.dart';

/// Raised for any failure while fetching stock news, with a message
/// that's safe to show directly in the UI.
class StockNewsException implements Exception {
  final String message;
  const StockNewsException(this.message);

  @override
  String toString() => message;
}

/// Fetches per-instrument news from Upstox's News API.
class StockNewsService {
  final Dio _dio;
  final String _token;

  StockNewsService({required String token, Dio? dio})
      : _token = token,
        _dio = dio ??
            (Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ))
              ..interceptors.addAll(kDebugMode
                  ? [
                      LogInterceptor(
                          requestHeader: false,
                          requestBody: true,
                          responseBody: true)
                    ]
                  : [])) {
    if (kDebugMode) {
      debugPrint(_token.isEmpty
          ? '[StockNewsService] upstox_analytics_token is EMPTY — Remote Config key not set/fetched, no API calls will be made.'
          : '[StockNewsService] token loaded (${_token.length} chars).');
    }
  }

  static const _base = 'https://api.upstox.com/v2/news';
  static const _maxKeysPerRequest = 30;

  /// News doesn't change second-to-second, so identical requests within
  /// this window are served from cache instead of hitting the API again —
  /// the same instrument-key set gets requested repeatedly as the user
  /// switches the "All Stocks"/"My Watchlist" toggle, reopens a stock's
  /// news page, or the widget rebuilds.
  static const _cacheTtl = Duration(minutes: 5);
  final _cache = <String, ({DateTime fetchedAt, Map<String, List<StockNews>> data})>{};

  /// Fetches news for [instrumentKeys], keyed by instrument_key.
  /// Splits into batches of 30 keys per request (Upstox's limit) and merges
  /// the results. Served from an in-memory cache when the same key set was
  /// fetched within [_cacheTtl], unless [forceRefresh] is set (pull-to-refresh).
  Future<Map<String, List<StockNews>>> fetchNews(
    List<String> instrumentKeys, {
    int pageNumber = 1,
    int pageSize = 100,
    bool forceRefresh = false,
  }) async {
    if (instrumentKeys.isEmpty) return {};

    final cacheKey =
        '${(List<String>.of(instrumentKeys)..sort()).join(',')}|$pageNumber|$pageSize';
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < _cacheTtl) {
        if (kDebugMode) {
          debugPrint('[StockNewsService] cache hit (${instrumentKeys.length} '
              'key(s)), skipping API call.');
        }
        return cached.data;
      }
    }

    if (_token.isEmpty) {
      throw const StockNewsException(
          'News is not configured yet (missing Upstox token).');
    }

    final merged = <String, List<StockNews>>{};
    for (var i = 0; i < instrumentKeys.length; i += _maxKeysPerRequest) {
      final end = (i + _maxKeysPerRequest < instrumentKeys.length)
          ? i + _maxKeysPerRequest
          : instrumentKeys.length;
      final batch = instrumentKeys.sublist(i, end);
      final batchResult =
          await _fetchBatch(batch, pageNumber: pageNumber, pageSize: pageSize);
      batchResult.forEach((key, list) {
        merged.putIfAbsent(key, () => []).addAll(list);
      });
    }
    _cache[cacheKey] = (fetchedAt: DateTime.now(), data: merged);
    return merged;
  }

  Future<Map<String, List<StockNews>>> _fetchBatch(
    List<String> instrumentKeys, {
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      final res = await _dio.get(
        _base,
        queryParameters: {
          'category': 'instrument_keys',
          'instrument_keys': instrumentKeys.join(','),
          'page_number': pageNumber,
          'page_size': pageSize,
        },
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final parsed = data.map((key, value) => MapEntry(
            key,
            (value as List)
                .map((e) => StockNews.fromJson(e as Map<String, dynamic>))
                .toList(),
          ));

      if (kDebugMode) {
        debugPrint('[StockNewsService] GET $_base -> ${res.statusCode} '
            'status=${body['status']} keys=${instrumentKeys.join(',')}');
        if (parsed.isEmpty) {
          debugPrint('[StockNewsService] response "data" is empty — '
              'no news in the last 7 days for these instrument_keys.');
        } else {
          parsed.forEach((key, list) {
            debugPrint('[StockNewsService]   $key: ${list.length} article(s)'
                '${list.isNotEmpty ? ' — latest: "${list.first.heading}"' : ''}');
          });
        }
      }

      return parsed;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[StockNewsService] request failed: '
            'status=${e.response?.statusCode} type=${e.type} '
            'data=${e.response?.data} message=${e.message}');
      }
      throw StockNewsException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'News session expired. Please try again later.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Could not load news right now.';
    }
  }
}
