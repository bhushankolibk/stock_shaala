import 'package:intl/intl.dart';

class Fmt {
  Fmt._();
  static final _inr = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _inr2 = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String money(num v) => _inr.format(v);
  static String money2(num v) => _inr2.format(v);
  static String pct(num v) =>
      '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  static String signedMoney(num v) =>
      '${v >= 0 ? '+' : '-'}${_inr.format(v.abs())}';
}
