import '../constants/stock_universe.dart';
import '../../data/models/quote_model.dart';
import 'equity_list_service.dart';
import 'stock_quote_service.dart';

/// Home page + Market tab overview data sourced from Upstox's Full Market
/// Quote API, reusing the same [StockQuoteService] as the stock-list
/// feature. Indices/"Top Stocks" come from the curated 12-stock
/// [StockUniverse.stocks]; "Top Gainers" is computed from a deliberately
/// larger, separate pool ([StockUniverse.gainersPoolSymbols]) so it isn't
/// just a reordering of the same 12 stocks.
class MarketOverviewService {
  final StockQuoteService _quoteService;
  final EquityListService _equityService;
  List<({String symbol, String name, String instrumentKey})>? _gainersPool;
  List<({String symbol, String name, String instrumentKey})>? _sectorPool;

  MarketOverviewService(this._quoteService, this._equityService);

  Future<List<Quote>> fetchIndices() async {
    final keys = StockUniverse.indices.map((i) => i.instrumentKey).toList();
    final quotes = await _quoteService.fetchQuotes(keys);
    return [
      for (final i in StockUniverse.indices)
        if (quotes[i.instrumentKey] != null)
          Quote.fromLiveQuote(i.symbol, i.name, quotes[i.instrumentKey]!,
              instrumentKey: i.instrumentKey),
    ];
  }

  Future<List<Quote>> fetchStockQuotes() async {
    final keys = StockUniverse.stocks.map((s) => s.instrumentKey).toList();
    final quotes = await _quoteService.fetchQuotes(keys);
    return [
      for (final s in StockUniverse.stocks)
        if (quotes[s.instrumentKey] != null)
          Quote.fromLiveQuote(s.symbol, s.name, quotes[s.instrumentKey]!,
              instrumentKey: s.instrumentKey),
    ];
  }

  Future<List<({String symbol, String name, String instrumentKey})>>
      _resolveGainersPool() async {
    final cached = _gainersPool;
    if (cached != null) return cached;
    final all = await _equityService.loadAll();
    final bySymbol = {for (final e in all) e.tradingSymbol: e};
    final resolved = [
      for (final symbol in StockUniverse.gainersPoolSymbols)
        if (bySymbol[symbol] != null)
          (
            symbol: symbol,
            name: bySymbol[symbol]!.name,
            instrumentKey: bySymbol[symbol]!.instrumentKey,
          ),
    ];
    _gainersPool = resolved;
    return resolved;
  }

  /// Top [limit] gainers by day change %, drawn from the broader
  /// [StockUniverse.gainersPoolSymbols] pool (not [StockUniverse.stocks]).
  Future<List<Quote>> fetchTopGainers({int limit = 8}) async {
    final pool = await _resolveGainersPool();
    final keys = pool.map((s) => s.instrumentKey).toList();
    final quotes = await _quoteService.fetchQuotes(keys);
    final resolved = [
      for (final s in pool)
        if (quotes[s.instrumentKey] != null)
          Quote.fromLiveQuote(s.symbol, s.name, quotes[s.instrumentKey]!,
              instrumentKey: s.instrumentKey),
    ]..sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return resolved.take(limit).toList();
  }

  Future<List<({String symbol, String name, String instrumentKey})>>
      _resolveSectorPool() async {
    final cached = _sectorPool;
    if (cached != null) return cached;
    final all = await _equityService.loadAll();
    final bySymbol = {for (final e in all) e.tradingSymbol: e};
    final resolved = [
      for (final tag in StockUniverse.sectorTags)
        if (StockUniverse.instrumentKeyFor(tag.symbol) != null ||
            bySymbol[tag.symbol] != null)
          (
            symbol: tag.symbol,
            name: bySymbol[tag.symbol]?.name ?? tag.symbol,
            instrumentKey: StockUniverse.instrumentKeyFor(tag.symbol) ??
                bySymbol[tag.symbol]!.instrumentKey,
          ),
    ];
    _sectorPool = resolved;
    return resolved;
  }

  /// Live quotes for the sector-tagged blue-chip pool
  /// ([StockUniverse.sectorTags]) — used by the sector screener so a
  /// sector filters ~50 stocks instead of just the curated 12.
  Future<List<Quote>> fetchSectorPoolQuotes() async {
    final pool = await _resolveSectorPool();
    final keys = pool.map((s) => s.instrumentKey).toList();
    final quotes = await _quoteService.fetchQuotes(keys);
    return [
      for (final s in pool)
        if (quotes[s.instrumentKey] != null)
          Quote.fromLiveQuote(s.symbol, s.name, quotes[s.instrumentKey]!,
              instrumentKey: s.instrumentKey),
    ];
  }
}
