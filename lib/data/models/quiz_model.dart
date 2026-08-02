import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  final String id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        category: j['category'] as String,
        question: j['question'] as String,
        options: (j['options'] as List).cast<String>(),
        correctIndex: j['correct_index'] as int,
        explanation: j['explanation'] as String,
      );

  @override
  List<Object?> get props => [id];
}
