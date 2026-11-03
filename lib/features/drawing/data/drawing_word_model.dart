import 'package:equatable/equatable.dart';

class DrawingWord extends Equatable {
  final String id;
  final String word;
  final String category;
  final int difficulty;

  const DrawingWord({
    required this.id,
    required this.word,
    required this.category,
    required this.difficulty,
  });

  factory DrawingWord.fromJson(Map<String, dynamic> json) {
    return DrawingWord(
      id: json['id'] as String,
      word: json['word'] as String,
      category: json['category'] as String,
      difficulty: (json['difficulty'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'category': category,
    'difficulty': difficulty,
  };

  @override
  List<Object?> get props => [id, word, category, difficulty];
}
