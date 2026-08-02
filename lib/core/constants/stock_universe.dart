/// Static list of NSE stocks the app supports for the simulator.
/// Yahoo Finance uses the `.NS` suffix for NSE symbols.
class StockUniverse {
  StockUniverse._();

  static const List<({String symbol, String name, String sector})> stocks = [
    (symbol: 'RELIANCE', name: 'Reliance Industries', sector: 'Energy'),
    (symbol: 'TCS', name: 'Tata Consultancy', sector: 'IT'),
    (symbol: 'HDFCBANK', name: 'HDFC Bank', sector: 'Banking'),
    (symbol: 'INFY', name: 'Infosys', sector: 'IT'),
    (symbol: 'ICICIBANK', name: 'ICICI Bank', sector: 'Banking'),
    (symbol: 'SBIN', name: 'State Bank of India', sector: 'Banking'),
    (symbol: 'WIPRO', name: 'Wipro Ltd', sector: 'IT'),
    (symbol: 'SUNPHARMA', name: 'Sun Pharma', sector: 'Pharma'),
    (symbol: 'TATAMOTORS', name: 'Tata Motors', sector: 'Auto'),
    (symbol: 'ITC', name: 'ITC Ltd', sector: 'FMCG'),
    (symbol: 'BHARTIARTL', name: 'Bharti Airtel', sector: 'Telecom'),
    (symbol: 'LT', name: 'Larsen & Toubro', sector: 'Infra'),
  ];

  /// Index symbols for Yahoo Finance.
  static const nifty50 = '^NSEI';
  static const sensex = '^BSESN';
  static const bankNifty = '^NSEBANK';

  static String yahooSymbol(String nseSymbol) => '$nseSymbol.NS';
}
