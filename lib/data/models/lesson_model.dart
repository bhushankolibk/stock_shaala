import 'package:equatable/equatable.dart';

enum LessonStatus { done, active, locked }

class Lesson extends Equatable {
  final String id;
  final String title;
  final String category;
  final int durationMin;
  final int xp;
  final String content; // markdown-ish body
  final LessonStatus status;

  const Lesson({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMin,
    required this.xp,
    required this.content,
    this.status = LessonStatus.locked,
  });

  Lesson copyWith({LessonStatus? status}) => Lesson(
        id: id,
        title: title,
        category: category,
        durationMin: durationMin,
        xp: xp,
        content: content,
        status: status ?? this.status,
      );

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        id: j['id'] as String,
        title: j['title'] as String,
        category: j['category'] as String,
        durationMin: j['duration_min'] as int,
        xp: j['xp'] as int,
        content: j['content'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, status];
}
