import 'package:equatable/equatable.dart';

// Party Game Team Model
class Team extends Equatable {
  final String id;
  final String name;
  final int colorValue;
  final int score;
  final String iconKey;

  const Team({
    required this.id,
    required this.name,
    required this.colorValue,
    this.score = 0,
    this.iconKey = 'star',
  });

  Team copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? score,
    String? iconKey,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      score: score ?? this.score,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'score': score,
      'iconKey': iconKey,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      score: (json['score'] as int?) ?? 0,
      iconKey: (json['iconKey'] as String?) ?? 'star',
    );
  }

  @override
  List<Object?> get props => [id, name, colorValue, score, iconKey];
}
