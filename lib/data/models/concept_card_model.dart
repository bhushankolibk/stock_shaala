class ConceptCard {
  final String id;
  final String category;
  final String term;
  final String body;
  final String example;

  const ConceptCard({
    required this.id,
    required this.category,
    required this.term,
    required this.body,
    required this.example,
  });

  factory ConceptCard.fromJson(Map<String, dynamic> j) => ConceptCard(
        id: j['id'] as String,
        category: j['category'] as String,
        term: j['term'] as String,
        body: j['body'] as String,
        example: j['example'] as String,
      );
}
