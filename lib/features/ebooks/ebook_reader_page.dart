import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injection.dart';
import '../../core/services/ebook_download_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/ebook_model.dart';

/// Reads an unlocked ebook page-by-page. Screenshots and screen recording
/// are blocked for the lifetime of this screen only (FLAG_SECURE on
/// Android via ScreenProtector) — turned back off in dispose() so the rest
/// of the app is unaffected.
class EbookReaderPage extends StatefulWidget {
  final Ebook book;
  const EbookReaderPage({super.key, required this.book});

  @override
  State<EbookReaderPage> createState() => _EbookReaderPageState();
}

class _EbookReaderPageState extends State<EbookReaderPage> {
  PdfController? _controller;
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    ScreenProtector.protectDataLeakageOn();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = await sl<EbookDownloadService>().localFile(widget.book);
      final controller =
          PdfController(document: PdfDocument.openFile(file.path));
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this book. Check your connection and retry.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    ScreenProtector.protectDataLeakageOff();
    _controller?.dispose();
    super.dispose();
  }

  void _showInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('By ${widget.book.author}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (widget.book.price > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.up.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.up.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '₹${widget.book.price.toInt()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.up),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              widget.book.description,
              style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.text),
            ),
            const SizedBox(height: 14),

            // Contact Email Card
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('mailto:stockshaala5@gmail.com?subject=eBook%20PDF%20Request%20(₹${widget.book.price.toInt()})%20-%20${Uri.encodeComponent(widget.book.title)}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.price > 0
                                ? 'Get PDF Copy for ₹${widget.book.price.toInt()}'
                                : 'Get Original PDF Copy',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                          const SizedBox(height: 2),
                          const Text('Contact: stockshaala5@gmail.com',
                              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, color: AppColors.accent, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
            onPressed: _showInfoSheet,
          ),
          if (_controller != null && _pageCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.dim,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$_currentPage / $_pageCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _body()),
            if (_controller != null && _pageCount > 0) _bottomNavigationToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) return _errorView();
    if (_loading || _controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
            SizedBox(height: 14),
            Text('Loading book…',
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      );
    }
    return PdfView(
      controller: _controller!,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onDocumentLoaded: (doc) => setState(() => _pageCount = doc.pagesCount),
      onPageChanged: (page) => setState(() => _currentPage = page),
    );
  }

  Widget _bottomNavigationToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            onPressed: _currentPage > 1
                ? () => _controller?.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                : null,
          ),
          Text(
            'Page $_currentPage of $_pageCount',
            style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w500),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            onPressed: _currentPage < _pageCount
                ? () => _controller?.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.down, size: 32),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
