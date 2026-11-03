import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/storage_service.dart';

class CustomCardsCubit extends Cubit<List<Map<String, dynamic>>> {
  CustomCardsCubit(this.storage) : super(storage.getCustomCards());
  final StorageService storage;
  Future<void> add(String word, String category) async {
    if (word.trim().isEmpty) return;
    final next = [
      ...state,
      {
        'id': 'custom_${DateTime.now().microsecondsSinceEpoch}',
        'word': word.trim(),
        'category': category.trim().isEmpty ? 'شخصی' : category.trim(),
      },
    ];
    await storage.saveCustomCards(next);
    if (!isClosed) emit(next);
  }

  Future<void> remove(int index) async {
    final next = [...state]..removeAt(index);
    await storage.saveCustomCards(next);
    if (!isClosed) emit(next);
  }
}

class PickerState {
  const PickerState({this.name, this.busy = false});
  final String? name;
  final bool busy;
}

class PickerCubit extends Cubit<PickerState> {
  PickerCubit() : super(const PickerState());
  final Random random = Random();
  Future<void> pick(List<String> names) async {
    if (names.isEmpty || state.busy) return;
    emit(const PickerState(busy: true));
    for (var i = 0; i < 9; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (isClosed) return;
      emit(PickerState(name: names[random.nextInt(names.length)], busy: true));
    }
    if (!isClosed) emit(PickerState(name: names[random.nextInt(names.length)]));
  }
}

class WheelState {
  const WheelState({this.rotation = 0, this.selected, this.busy = false});
  final double rotation;
  final int? selected;
  final bool busy;
}

class WheelCubit extends Cubit<WheelState> {
  WheelCubit() : super(const WheelState());
  final Random random = Random();
  Future<void> spin(int count, {bool reducedMotion = false}) async {
    if (state.busy) return;
    final selected = random.nextInt(count);
    final segment = 2 * pi / count;
    // Painter starts at 12 o'clock; rotate the selected slice's midpoint to the pointer.
    final normalized = state.rotation % (2 * pi);
    final destination = ((2 * pi - (selected + .5) * segment) % (2 * pi));
    final delta = (destination - normalized + 2 * pi) % (2 * pi);
    final target = state.rotation + 2 * pi * 5 + delta;
    emit(WheelState(rotation: target, busy: true));
    if (!reducedMotion) await Future<void>.delayed(const Duration(seconds: 3));
    if (!isClosed) emit(WheelState(rotation: target, selected: selected));
  }
}
