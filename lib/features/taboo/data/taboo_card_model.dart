import 'package:equatable/equatable.dart';

class TabooCard extends Equatable {
  final String id;
  final String word;
  final List<String> forbiddenWords;
  final String category;
  final int difficulty;

  const TabooCard({
    required this.id,
    required this.word,
    required this.forbiddenWords,
    required this.category,
    required this.difficulty,
  });

  factory TabooCard.fromJson(Map<String, dynamic> json) {
    return TabooCard(
      id: json['id'] as String,
      word: json['word'] as String,
      forbiddenWords: (json['forbiddenWords'] as List).map((e) => e.toString()).toList(),
      category: json['category'] as String,
      difficulty: (json['difficulty'] as int?) ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, word, forbiddenWords, category, difficulty];
}
