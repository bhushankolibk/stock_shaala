import 'package:dio/dio.dart';
import '../../data/models/quote_model.dart';
import '../constants/stock_universe.dart';

/// Fetches market data from Yahoo Finance's free (unofficial) chart endpoint.
/// No API key required. Works on mobile (CORS only blocks web).
class MarketApiService {
  final Dio _dio;

  MarketApiService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 13) StockShaala/1.0',
              },
            ));

  static const _base = 'https://query1.finance.yahoo.com/v8/finance/chart';

  /// Fetch a single quote. [name] is a friendly display name.
  Future<Quote> fetchQuote(String yahooSymbol, String name) async {
    final res = await _dio.get('$_base/$yahooSymbol');
    return Quote.fromYahooChart(res.data as Map<String, dynamic>, name);
  }

  /// Fetch many NSE stock quotes (called on pull-to-refresh).
  Future<List<Quote>> fetchStockQuotes() async {
    final futures = StockUniverse.stocks.map((s) async {
      try {
        return await fetchQuote(
          StockUniverse.yahooSymbol(s.symbol),
          s.name,
        ).then((q) => Quote(
              symbol: s.symbol,
              name: s.name,
              price: q.price,
              change: q.change,
              changePercent: q.changePercent,
              dayHigh: q.dayHigh,
              dayLow: q.dayLow,
              week52High: q.week52High,
              week52Low: q.week52Low,
              previousClose: q.previousClose,
            ));
      } catch (_) {
        return null;
      }
    });
    final results = await Future.wait(futures);
    return results.whereType<Quote>().toList();
  }

  /// Fetch the three headline indices.
  Future<List<Quote>> fetchIndices() async {
    final indices = <String, String>{
      StockUniverse.nifty50: 'NIFTY 50',
      StockUniverse.sensex: 'SENSEX',
      StockUniverse.bankNifty: 'BANK NIFTY',
    };
    final futures = indices.entries.map((e) async {
      try {
        return await fetchQuote(e.key, e.value);
      } catch (_) {
        return null;
      }
    });
    final results = await Future.wait(futures);
    return results.whereType<Quote>().toList();
  }

  /// Historical close prices for the mini chart on the detail screen.
  Future<List<double>> fetchHistory(
    String yahooSymbol, {
    String range = '1mo',
    String interval = '1d',
  }) async {
    final res = await _dio.get(
      '$_base/$yahooSymbol',
      queryParameters: {'range': range, 'interval': interval},
    );
    final result = res.data['chart']['result'][0];
    final closes = (result['indicators']['quote'][0]['close'] as List)
        .where((e) => e != null)
        .map((e) => (e as num).toDouble())
        .toList();
    return closes;
  }
}
