import 'package:equatable/equatable.dart';

class HotPotatoTopic extends Equatable {
  final String id;
  final String topic;
  final String category;

  const HotPotatoTopic({
    required this.id,
    required this.topic,
    required this.category,
  });

  factory HotPotatoTopic.fromJson(Map<String, dynamic> json) {
    return HotPotatoTopic(
      id: json['id'] as String,
      topic: json['topic'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    'category': category,
  };

  @override
  List<Object?> get props => [id, topic, category];
}
