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

  /// Relative time like "5m ago", "3h ago", "2d ago".
  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(time);
  }
}
