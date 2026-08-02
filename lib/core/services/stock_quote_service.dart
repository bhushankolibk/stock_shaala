import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/live_quote_model.dart';

/// Raised for any failure while fetching live quotes, with a message
/// that's safe to show directly in the UI.
class LiveQuoteException implements Exception {
  final String message;
  const LiveQuoteException(this.message);

  @override
  String toString() => message;
}

/// Fetches live market quotes from Upstox's Full Market Quote API.
class StockQuoteService {
  final Dio _dio;
  final String _token;

  StockQuoteService({required String token, Dio? dio})
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
                  : []));

  static const _base = 'https://api.upstox.com/v2/market-quote/quotes';
  static const _maxKeysPerRequest = 500;

  /// Fetches quotes for [instrumentKeys], keyed by instrument_key (matched
  /// via each entry's own "instrument_token" field, not the outer
  /// "EXCHANGE:SYMBOL" response key). Batches of 500 keys run in parallel.
  Future<Map<String, LiveQuote>> fetchQuotes(List<String> instrumentKeys) async {
    if (instrumentKeys.isEmpty) return {};
    if (_token.isEmpty) {
      throw const LiveQuoteException(
          'Live prices are not configured yet (missing Upstox token).');
    }

    final batches = <List<String>>[];
    for (var i = 0; i < instrumentKeys.length; i += _maxKeysPerRequest) {
      final end = (i + _maxKeysPerRequest < instrumentKeys.length)
          ? i + _maxKeysPerRequest
          : instrumentKeys.length;
      batches.add(instrumentKeys.sublist(i, end));
    }

    final results = await Future.wait(batches.map(_fetchBatch));
    final merged = <String, LiveQuote>{};
    for (final r in results) {
      merged.addAll(r);
    }
    return merged;
  }

  Future<Map<String, LiveQuote>> _fetchBatch(List<String> instrumentKeys) async {
    try {
      final res = await _dio.get(
        _base,
        queryParameters: {'instrument_key': instrumentKeys.join(',')},
        options: Options(headers: {'Authorization': 'Bearer $_token'}),
      );

      final body = res.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final map = <String, LiveQuote>{};
      for (final value in data.values) {
        final entry = value as Map<String, dynamic>;
        final instrumentToken = entry['instrument_token']?.toString();
        if (instrumentToken == null) continue;
        map[instrumentToken] = LiveQuote.fromJson(entry);
      }
      return map;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[StockQuoteService] request failed: '
            'status=${e.response?.statusCode} type=${e.type} '
            'message=${e.message}');
      }
      throw LiveQuoteException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Live price session expired. Please try again later.';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Could not load live prices right now.';
    }
  }
}
