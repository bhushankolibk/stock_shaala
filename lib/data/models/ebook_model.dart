class Ebook {
  final String id;
  final String title;
  final String author;
  final String description;
  final String pdfUrl;
  final String coverImageUrl;
  final String category;
  final int version;
  final double sizeMb;
  final double price;
  final bool isActive;
  final int order;

  const Ebook({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.pdfUrl,
    required this.coverImageUrl,
    required this.category,
    required this.version,
    required this.sizeMb,
    required this.price,
    required this.isActive,
    required this.order,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) => Ebook(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pdfUrl: json['pdf_url'] as String? ?? '',
        coverImageUrl: json['cover_image_url'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        version: (json['version'] as num?)?.toInt() ?? 1,
        sizeMb: (json['size_mb'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        isActive: json['is_active'] as bool? ?? true,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );
}
