import 'package:flutter/material.dart';
import '../../core/widgets/banner_ad_widget.dart';
import 'widgets/stock_news_view.dart';

class StockNewsPage extends StatelessWidget {
  final List<String> instrumentKeys;
  final String title;

  const StockNewsPage({
    super.key,
    required this.instrumentKeys,
    this.title = 'Stock News',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(child: StockNewsView(instrumentKeys: instrumentKeys)),
    );
  }
}
