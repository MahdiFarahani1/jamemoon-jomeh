import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../data/drawing_word_model.dart';

class DrawnStroke extends Equatable {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  const DrawnStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });

  DrawnStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    bool? isEraser,
  }) {
    return DrawnStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
    );
  }

  @override
  List<Object?> get props => [points, color, strokeWidth, isEraser];
}

class DrawingState extends Equatable {
  final bool isGameOver;
  final DrawingWord? currentWord;
  final List<DrawnStroke> strokes;
  final Color activeColor;
  final double strokeWidth;
  final bool isEraser;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isTimerRunning;
  final bool isPassPhonePhase;
  final bool isWordRevealed;
  final bool isRoundOver;
  final String activeTeamName;
  final int activeTeamIndex;
  final int currentRound;
  final int totalRounds;
  final int roundScore;
  final bool isQuickMode;

  const DrawingState({
    this.isGameOver = false,
    this.currentWord,
    this.strokes = const [],
    this.activeColor = Colors.white,
    this.strokeWidth = 4.0,
    this.isEraser = false,
    this.remainingSeconds = 60,
    this.totalSeconds = 60,
    this.isTimerRunning = false,
    this.isPassPhonePhase = true,
    this.isWordRevealed = false,
    this.isRoundOver = false,
    this.activeTeamName = 'تیم ۱',
    this.activeTeamIndex = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.roundScore = 0,
    this.isQuickMode = false,
  });

  DrawingState copyWith({
    bool? isGameOver,
    DrawingWord? currentWord,
    List<DrawnStroke>? strokes,
    Color? activeColor,
    double? strokeWidth,
    bool? isEraser,
    int? remainingSeconds,
    int? totalSeconds,
    bool? isTimerRunning,
    bool? isPassPhonePhase,
    bool? isWordRevealed,
    bool? isRoundOver,
    String? activeTeamName,
    int? activeTeamIndex,
    int? currentRound,
    int? totalRounds,
    int? roundScore,
    bool? isQuickMode,
  }) {
    return DrawingState(
      isGameOver: isGameOver ?? this.isGameOver,
      currentWord: currentWord ?? this.currentWord,
      strokes: strokes ?? this.strokes,
      activeColor: activeColor ?? this.activeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isEraser: isEraser ?? this.isEraser,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPassPhonePhase: isPassPhonePhase ?? this.isPassPhonePhase,
      isWordRevealed: isWordRevealed ?? this.isWordRevealed,
      isRoundOver: isRoundOver ?? this.isRoundOver,
      activeTeamName: activeTeamName ?? this.activeTeamName,
      activeTeamIndex: activeTeamIndex ?? this.activeTeamIndex,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      roundScore: roundScore ?? this.roundScore,
      isQuickMode: isQuickMode ?? this.isQuickMode,
    );
  }

  @override
  List<Object?> get props => [
    isGameOver,
    currentWord,
    strokes,
    activeColor,
    strokeWidth,
    isEraser,
    remainingSeconds,
    totalSeconds,
    isTimerRunning,
    isPassPhonePhase,
    isWordRevealed,
    isRoundOver,
    activeTeamName,
    activeTeamIndex,
    currentRound,
    totalRounds,
    roundScore,
    isQuickMode,
  ];
}
