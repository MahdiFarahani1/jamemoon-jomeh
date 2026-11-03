import 'package:equatable/equatable.dart';

// Party Game Player Model
class Player extends Equatable {
  static const _unchanged = Object();
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
    Object? teamId = _unchanged,
    Object? awardedTitle = _unchanged,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: identical(teamId, _unchanged) ? this.teamId : teamId as String?,
      awardedTitle: identical(awardedTitle, _unchanged)
          ? this.awardedTitle
          : awardedTitle as String?,
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
