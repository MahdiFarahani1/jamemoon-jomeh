import 'package:equatable/equatable.dart';

// Party Game Player Model
class Player extends Equatable {
  final String id;
  final String name;
  final String? teamId;
  final String? awardedTitle;

  const Player({
    required this.id,
    required this.name,
    this.teamId,
    this.awardedTitle,
  });

  Player copyWith({
    String? id,
    String? name,
    String? teamId,
    String? awardedTitle,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      awardedTitle: awardedTitle ?? this.awardedTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teamId': teamId,
      'awardedTitle': awardedTitle,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      teamId: json['teamId'] as String?,
      awardedTitle: json['awardedTitle'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, teamId, awardedTitle];
}
