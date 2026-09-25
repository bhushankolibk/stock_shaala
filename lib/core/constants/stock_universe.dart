/// Static list of NSE stocks the app supports for the simulator.
/// Yahoo Finance uses the `.NS` suffix for NSE symbols.
class StockUniverse {
  StockUniverse._();

  static const List<({String symbol, String name, String sector, String instrumentKey})>
      stocks = [
    (
      symbol: 'RELIANCE',
      name: 'Reliance Industries',
      sector: 'Energy',
      instrumentKey: 'NSE_EQ|INE002A01018',
    ),
    (
      symbol: 'TCS',
      name: 'Tata Consultancy',
      sector: 'IT',
      instrumentKey: 'NSE_EQ|INE467B01029',
    ),
    (
      symbol: 'HDFCBANK',
      name: 'HDFC Bank',
      sector: 'Banking',
      instrumentKey: 'NSE_EQ|INE040A01034',
    ),
    (
      symbol: 'INFY',
      name: 'Infosys',
      sector: 'IT',
      instrumentKey: 'NSE_EQ|INE009A01021',
    ),
    (
      symbol: 'ICICIBANK',
      name: 'ICICI Bank',
      sector: 'Banking',
      instrumentKey: 'NSE_EQ|INE090A01021',
    ),
    (
      symbol: 'SBIN',
      name: 'State Bank of India',
      sector: 'Banking',
      instrumentKey: 'NSE_EQ|INE062A01020',
    ),
    (
      symbol: 'WIPRO',
      name: 'Wipro Ltd',
      sector: 'IT',
      instrumentKey: 'NSE_EQ|INE075A01022',
    ),
    (
      symbol: 'SUNPHARMA',
      name: 'Sun Pharma',
      sector: 'Pharma',
      instrumentKey: 'NSE_EQ|INE044A01036',
    ),
    (
      symbol: 'TATAMOTORS',
      name: 'Tata Motors',
      sector: 'Auto',
      instrumentKey: 'NSE_EQ|INE155A01022',
    ),
    (
      symbol: 'ITC',
      name: 'ITC Ltd',
      sector: 'FMCG',
      instrumentKey: 'NSE_EQ|INE154A01025',
    ),
    (
      symbol: 'BHARTIARTL',
      name: 'Bharti Airtel',
      sector: 'Telecom',
      instrumentKey: 'NSE_EQ|INE397D01024',
    ),
    (
      symbol: 'LT',
      name: 'Larsen & Toubro',
      sector: 'Infra',
      instrumentKey: 'NSE_EQ|INE018A01030',
    ),
  ];

  /// Index symbols for Yahoo Finance (used by the stock detail chart).
  static const nifty50 = '^NSEI';
  static const sensex = '^BSESN';
  static const bankNifty = '^NSEBANK';

  /// Index instrument_keys for the Upstox market-quote API.
  static const List<({String symbol, String name, String instrumentKey})>
      indices = [
    (symbol: 'NIFTY 50', name: 'Nifty 50', instrumentKey: 'NSE_INDEX|Nifty 50'),
    (
      symbol: 'BANK NIFTY',
      name: 'Bank Nifty',
      instrumentKey: 'NSE_INDEX|Nifty Bank'
    ),
    (symbol: 'SENSEX', name: 'Sensex', instrumentKey: 'BSE_INDEX|SENSEX'),
  ];

  static String yahooSymbol(String nseSymbol) => '$nseSymbol.NS';

  /// A broader pool of liquid blue-chip trading symbols used only to
  /// compute "Top Gainers" — deliberately larger than [stocks] so gainers
  /// isn't just a reordering of the same 12-stock list. Resolved against
  /// the bundled equity list at runtime (no hardcoded instrument_keys
  /// here, so there's no ISIN-accuracy risk); any symbol not found there
  /// is silently skipped.
  static const List<String> gainersPoolSymbols = [
    'RELIANCE', 'TCS', 'HDFCBANK', 'ICICIBANK', 'INFY', 'HINDUNILVR', 'ITC',
    'SBIN', 'BHARTIARTL', 'BAJFINANCE', 'KOTAKBANK', 'LT', 'HCLTECH',
    'AXISBANK', 'ASIANPAINT', 'MARUTI', 'SUNPHARMA', 'TITAN', 'ULTRACEMCO',
    'WIPRO', 'NESTLEIND', 'ONGC', 'NTPC', 'POWERGRID', 'M&M', 'TATASTEEL',
    'TATAMOTORS', 'ADANIENT', 'ADANIPORTS', 'JSWSTEEL', 'COALINDIA',
    'BAJAJFINSV', 'HDFCLIFE', 'SBILIFE', 'DRREDDY', 'GRASIM', 'CIPLA',
    'EICHERMOT', 'BRITANNIA', 'DIVISLAB', 'APOLLOHOSP', 'HEROMOTOCO',
    'INDUSINDBK', 'BPCL', 'TECHM', 'UPL', 'HINDALCO', 'SHRIRAMFIN', 'LTIM',
    'TRENT',
  ];

  /// Sector tags for the same blue-chip pool as [gainersPoolSymbols], used
  /// by the sector screener so "Banking"/"IT"/etc. filter ~50 stocks
  /// instead of just the curated 12 in [stocks]. Resolved against the
  /// bundled equity list at runtime, same as [gainersPoolSymbols]; a
  /// symbol not found there is silently skipped.
  static const List<({String symbol, String sector})> sectorTags = [
    (symbol: 'RELIANCE', sector: 'Energy'),
    (symbol: 'TCS', sector: 'IT'),
    (symbol: 'HDFCBANK', sector: 'Banking'),
    (symbol: 'ICICIBANK', sector: 'Banking'),
    (symbol: 'INFY', sector: 'IT'),
    (symbol: 'HINDUNILVR', sector: 'FMCG'),
    (symbol: 'ITC', sector: 'FMCG'),
    (symbol: 'SBIN', sector: 'Banking'),
    (symbol: 'BHARTIARTL', sector: 'Telecom'),
    (symbol: 'BAJFINANCE', sector: 'Finance'),
    (symbol: 'KOTAKBANK', sector: 'Banking'),
    (symbol: 'LT', sector: 'Infra'),
    (symbol: 'HCLTECH', sector: 'IT'),
    (symbol: 'AXISBANK', sector: 'Banking'),
    (symbol: 'ASIANPAINT', sector: 'FMCG'),
    (symbol: 'MARUTI', sector: 'Auto'),
    (symbol: 'SUNPHARMA', sector: 'Pharma'),
    (symbol: 'TITAN', sector: 'FMCG'),
    (symbol: 'ULTRACEMCO', sector: 'Infra'),
    (symbol: 'WIPRO', sector: 'IT'),
    (symbol: 'NESTLEIND', sector: 'FMCG'),
    (symbol: 'ONGC', sector: 'Energy'),
    (symbol: 'NTPC', sector: 'Energy'),
    (symbol: 'POWERGRID', sector: 'Energy'),
    (symbol: 'M&M', sector: 'Auto'),
    (symbol: 'TATASTEEL', sector: 'Metals'),
    (symbol: 'TATAMOTORS', sector: 'Auto'),
    (symbol: 'ADANIENT', sector: 'Infra'),
    (symbol: 'ADANIPORTS', sector: 'Infra'),
    (symbol: 'JSWSTEEL', sector: 'Metals'),
    (symbol: 'COALINDIA', sector: 'Energy'),
    (symbol: 'BAJAJFINSV', sector: 'Finance'),
    (symbol: 'HDFCLIFE', sector: 'Finance'),
    (symbol: 'SBILIFE', sector: 'Finance'),
    (symbol: 'DRREDDY', sector: 'Pharma'),
    (symbol: 'GRASIM', sector: 'Infra'),
    (symbol: 'CIPLA', sector: 'Pharma'),
    (symbol: 'EICHERMOT', sector: 'Auto'),
    (symbol: 'BRITANNIA', sector: 'FMCG'),
    (symbol: 'DIVISLAB', sector: 'Pharma'),
    (symbol: 'APOLLOHOSP', sector: 'Healthcare'),
    (symbol: 'HEROMOTOCO', sector: 'Auto'),
    (symbol: 'INDUSINDBK', sector: 'Banking'),
    (symbol: 'BPCL', sector: 'Energy'),
    (symbol: 'TECHM', sector: 'IT'),
    (symbol: 'UPL', sector: 'Chemicals'),
    (symbol: 'HINDALCO', sector: 'Metals'),
    (symbol: 'SHRIRAMFIN', sector: 'Finance'),
    (symbol: 'LTIM', sector: 'IT'),
    (symbol: 'TRENT', sector: 'FMCG'),
  ];

  /// Upstox instrument_key for a given NSE symbol, e.g. "NSE_EQ|INE002A01018".
  static String? instrumentKeyFor(String nseSymbol) {
    for (final s in stocks) {
      if (s.symbol == nseSymbol) return s.instrumentKey;
    }
    return null;
  }
}
