import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/services/content_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/concept_card_model.dart';

class ConceptCardsPage extends StatefulWidget {
  const ConceptCardsPage({super.key});

  @override
  State<ConceptCardsPage> createState() => _ConceptCardsPageState();
}

class _ConceptCardsPageState extends State<ConceptCardsPage> {
  final _controller = PageController(viewportFraction: 0.92);
  List<ConceptCard> _cards = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    sl<ContentService>().loadConceptCards().then((c) {
      if (mounted) setState(() => _cards = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Concept Cards  ${_cards.isEmpty ? '' : '${_index + 1}/${_cards.length}'}'),
      ),
      body: _cards.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 2))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: _cards.length,
                    itemBuilder: (_, i) => _card(_cards[i]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_cards.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: active ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: active ? AppColors.accent : AppColors.dim2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text('← swipe to navigate →',
                    style: TextStyle(fontSize: 10, color: AppColors.muted)),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _card(ConceptCard c) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141E30), Color(0xFF0D1623)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Text(c.category.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.accent)),
            ),
            const SizedBox(height: 12),
            Text(c.term,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(c.body,
                style: const TextStyle(
                    fontSize: 13, height: 1.7, color: Color(0xFF8A9DC0))),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.up.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                    left: BorderSide(color: AppColors.up, width: 2)),
              ),
              child: Text('🧮 ${c.example}',
                  style: const TextStyle(
                      fontSize: 11, height: 1.6, color: AppColors.up)),
            ),
          ],
        ),
      );
}
