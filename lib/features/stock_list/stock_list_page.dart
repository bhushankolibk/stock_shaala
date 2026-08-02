import 'package:flutter/material.dart';
import 'stock_list_controller.dart';
import 'widgets/stock_list_slivers.dart';

class StockListPage extends StatefulWidget {
  const StockListPage({super.key});

  @override
  State<StockListPage> createState() => _StockListPageState();
}

class _StockListPageState extends State<StockListPage> {
  late final StockListController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StockListController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Stocks')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _controller.refreshLoadedPrices,
          child: CustomScrollView(
            slivers: buildStockListSlivers(
              controller: _controller,
              searchController: _searchController,
            ),
          ),
        ),
      ),
    );
  }
}
