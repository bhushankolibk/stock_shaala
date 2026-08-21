import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../data/models/lesson_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/concept_card_model.dart';
import '../../data/models/ebook_model.dart';

/// Loads learning content. Strategy:
///  1. Try Firebase Remote Config (so you can push new content without an update)
///  2. Fall back to bundled JSON assets (works offline, zero cost)
class ContentService {
  final FirebaseRemoteConfig? _remoteConfig;
  ContentService([this._remoteConfig]);

  Future<void> init() async {
    try {
      await _remoteConfig?.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig?.fetchAndActivate();
    } catch (_) {
      // ignore — fall back to assets
    }
  }

  Future<List<Lesson>> loadLessons() async {
    final raw = await _read('lessons', 'assets/data/lessons.json');
    final list = jsonDecode(raw) as List;
    return list.map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<QuizQuestion>> loadQuiz() async {
    final raw = await _read('quiz', 'assets/data/quiz.json');
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConceptCard>> loadConceptCards() async {
    // RC key is "concept" (as configured in Firebase console)
    final raw = await _read('concept', 'assets/data/concept_cards.json');
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ConceptCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Ebook>> loadEbooks() async {
    final raw = await _read('ebooks_config', 'assets/data/ebooks.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['books'] as List? ?? const []);
    final books = list
        .map((e) => Ebook.fromJson(e as Map<String, dynamic>))
        .where((b) => b.isActive)
        .toList();
    books.sort((a, b) => a.order.compareTo(b.order));
    return books;
  }

  Future<QuizQuestion> dailyChallenge() async {
    final all = await loadQuiz();
    final dayIndex = DateTime.now().day % all.length;
    return all[dayIndex];
  }

  Future<String> _read(String rcKey, String assetPath) async {
    final rc = _remoteConfig?.getString(rcKey) ?? '';
    if (rc.isNotEmpty && rc != '[]' && rc != '{}') return rc;
    return rootBundle.loadString(assetPath);
  }
}
