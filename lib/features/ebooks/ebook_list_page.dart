import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/injection.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/content_service.dart';
import '../../core/services/ebook_access_service.dart';
import '../../core/services/ebook_download_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../data/models/ebook_model.dart';

class EbookListPage extends StatefulWidget {
  const EbookListPage({super.key});

  @override
  State<EbookListPage> createState() => _EbookListPageState();
}

class _EbookListPageState extends State<EbookListPage> {
  List<Ebook> _allBooks = [];
  List<Ebook> _filteredBooks = [];
  List<String> _categories = ['All'];
  bool _loading = true;
  String? _error;
  bool _unlocking = false;
  String _selectedCategory = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final books = await sl<ContentService>().loadEbooks();
      if (!mounted) return;
      
      // Extract unique categories dynamically from loaded books
      final extractedCategories = <String>{'All'};
      for (final b in books) {
        if (b.category.isNotEmpty) {
          extractedCategories.add(b.category);
        }
      }

      setState(() {
        _allBooks = books;
        _categories = extractedCategories.toList();
        _applyFilters();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load the library';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        final matchesQuery = query.isEmpty ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            book.description.toLowerCase().contains(query) ||
            book.category.toLowerCase().contains(query);

        if (_selectedCategory == 'All') return matchesQuery;
        final matchesCat = book.category.toLowerCase() == _selectedCategory.toLowerCase();
        return matchesQuery && matchesCat;
      }).toList();
    });
  }

  void _openBook(Ebook book) {
    _showBookDetailsSheet(book);
  }

  void _showBookDetailsSheet(Ebook book) {
    final unlocked = sl<EbookAccessService>().isUnlocked(book.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          MediaQuery.of(sheetContext).padding.bottom + 24,
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
                  child: const Icon(Icons.menu_book_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('By ${book.author}',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          if (book.category.isNotEmpty) ...[
                            const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                            Text(book.category,
                                style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (book.price > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.up.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.up.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '₹${book.price.toInt()}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.up),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Book Description
            Text(
              book.description,
              style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.text),
            ),
            const SizedBox(height: 14),

            // Contact Email Card (Always Visible)
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse('mailto:stockshaala5@gmail.com?subject=eBook%20PDF%20Request%20(₹${book.price.toInt()})%20-%20${Uri.encodeComponent(book.title)}');
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
                            book.price > 0
                                ? 'Get PDF Copy for ₹${book.price.toInt()}'
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
            const SizedBox(height: 16),

            // Action Button
            if (unlocked)
              PrimaryButton(
                'Read eBook Now 📖',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push('/ebook-reader', extra: book);
                },
              )
            else
              PrimaryButton(
                'Watch Free Ad & Read In-App',
                onTap: () => _unlock(sheetContext, book),
              ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                unlocked
                    ? 'Already unlocked for this session'
                    : 'Free in-app reading supported by ads',
                style: TextStyle(
                    fontSize: 10, color: AppColors.muted.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock(BuildContext sheetContext, Ebook book) async {
    if (_unlocking) return;
    _unlocking = true;
    final ads = sl<AdService>();
    final access = sl<EbookAccessService>();

    void grantAndOpen() {
      access.unlock(book.id);
      sl<AnalyticsService>().logAdRewardEarned('ebook_${book.id}');
      _unlocking = false;
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (mounted) {
        setState(() {});
        context.push('/ebook-reader', extra: book);
      }
    }

    final shown = ads.showRewarded(
      onReward: grantAndOpen,
      onAdClosed: () => _unlocking = false,
    );
    if (!shown) grantAndOpen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eBook Library 📚', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: Column(
          children: [
            _searchAndFilterHeader(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _searchAndFilterHeader() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilters(),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search stock market eBooks…',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _applyFilters();
                      },
                      child: const Icon(Icons.clear_rounded, size: 16, color: AppColors.muted),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: AppColors.dim,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
            ),
          ),
        ),

        // Category Filter Chips
        if (_categories.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final active = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: active,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                        _applyFilters();
                      });
                    }
                  },
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.dim,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.black : AppColors.muted,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: active ? AppColors.accent : AppColors.border),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: AppColors.muted, size: 32),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
      );
    }
    if (_filteredBooks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No matching eBooks found.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      itemCount: _filteredBooks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (_, i) => _bookCard(_filteredBooks[i]),
    );
  }

  Widget _bookCard(Ebook book) {
    final unlocked = sl<EbookAccessService>().isUnlocked(book.id);
    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: unlocked ? AppColors.up.withValues(alpha: 0.5) : AppColors.border,
            width: unlocked ? 1.5 : 1.0,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: AppColors.up.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _cover(book, unlocked)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, height: 1.3)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          book.category.isNotEmpty ? book.category : book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (book.price > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.up.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${book.price.toInt()}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.up),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(Ebook book, bool unlocked) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (book.coverImageUrl.isNotEmpty)
          Image.network(
            book.coverImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackPdfThumbnail(book),
          )
        else
          _fallbackPdfThumbnail(book),
        if (!unlocked)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: const Center(
              child: Icon(Icons.lock_rounded, color: Colors.white, size: 26),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              unlocked ? Icons.lock_open_rounded : Icons.play_circle_outline,
              size: 12,
              color: unlocked ? AppColors.up : AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackPdfThumbnail(Ebook book) {
    return FutureBuilder<Uint8List?>(
      future: sl<EbookDownloadService>().coverThumbnail(book),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.dim,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent),
              ),
            ),
          );
        }
        final bytes = snap.data;
        if (bytes == null) {
          return Container(
            color: AppColors.dim,
            child: const Center(
              child: Icon(Icons.menu_book_rounded,
                  color: AppColors.muted, size: 32),
            ),
          );
        }
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}
