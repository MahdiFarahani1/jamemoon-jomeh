import 'package:equatable/equatable.dart';

class CharadesWord extends Equatable {
  final String id;
  final String word;
  final String category;
  final int points;

  const CharadesWord({
    required this.id,
    required this.word,
    required this.category,
    required this.points,
  });

  factory CharadesWord.fromJson(Map<String, dynamic> json) {
    return CharadesWord(
      id: json['id'] as String,
      word: json['word'] as String,
      category: json['category'] as String,
      points: (json['points'] as int?) ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, word, category, points];
}

