import 'package:equatable/equatable.dart';

class FiveSecondsQuestion extends Equatable {
  final String id;
  final String question;
  final String category;

  const FiveSecondsQuestion({
    required this.id,
    required this.question,
    required this.category,
  });

  factory FiveSecondsQuestion.fromJson(Map<String, dynamic> json) {
    return FiveSecondsQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      category: json['category'] as String,
    );
  }

  @override
  List<Object?> get props => [id, question, category];
}

