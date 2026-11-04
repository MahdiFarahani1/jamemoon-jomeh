import 'package:equatable/equatable.dart';

class CharadesWord extends Equatable {
  static int letterCount(String word) =>
      word.replaceAll(RegExp(r'[\s\u200c\u200d]'), '').runes.length;

  static int pointsFor(String word) {
    final length = letterCount(word);
    return length <= 1
        ? 1
        : length >= 4
        ? 3
        : 2;
  }

  static bool isPlayable(String word) =>
      !word.trim().contains(RegExp(r'[\s\u200c\u200d]')) &&
      letterCount(word) >= 1 &&
      letterCount(word) <= 4 &&
      !RegExp(r'[0-9۰-۹٠-٩]').hasMatch(word);

  static bool isValid(String word) =>
      word.trim().isNotEmpty && !RegExp(r'[0-9۰-۹٠-٩]').hasMatch(word);

  final String id;
  final String word;
  final String category;
  final int points;
  final int difficulty;
  final bool isCustom;

  const CharadesWord({
    required this.id,
    required this.word,
    required this.category,
    required this.points,
    this.difficulty = 2,
    this.isCustom = false,
  });

  factory CharadesWord.fromJson(Map<String, dynamic> json) {
    return CharadesWord(
      id: json['id'] as String,
      word: json['word'] as String,
      category: json['category'] as String,
      points: (json['points'] as int?) ?? pointsFor(json['word'] as String),
      difficulty: (json['difficulty'] as int?) ?? 2,
      isCustom:
          json['isCustom'] == true ||
          (json['id'] as String).startsWith('custom_'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'category': category,
    'points': points,
    'difficulty': difficulty,
    'isCustom': isCustom,
  };

  @override
  List<Object?> get props => [id, word, category, points, difficulty, isCustom];
}
