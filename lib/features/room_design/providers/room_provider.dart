import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room.dart';
import '../models/room_position.dart';
import '../models/room_state.dart';
import '../models/speaker.dart';
import '../models/listening_position.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../../acoustic/models/reflection_point.dart';
import '../../acoustic/services/sweet_spot_calculator.dart';
import '../../acoustic/services/reflection_calculator.dart';

RoomState _buildDefaultState() {
  const room = Room(widthMeters: 5.0, lengthMeters: 6.0, heightMeters: 2.4);
  // Place left speaker at 1/3 width, 1/5 length
  final leftPos = RoomPosition(room.widthMeters / 3, room.lengthMeters / 5);
  // Place right speaker symmetrically
  final rightPos =
      RoomPosition(room.widthMeters * 2 / 3, room.lengthMeters / 5);
  // Listening position at center, 60% depth
  final listenPos =
      RoomPosition(room.widthMeters / 2, room.lengthMeters * 0.6);

  return RoomState(
    room: room,
    leftSpeaker: Speaker(
      channel: SpeakerChannel.left,
      position: leftPos,
    ),
    rightSpeaker: Speaker(
      channel: SpeakerChannel.right,
      position: rightPos,
    ),
    listeningPosition: ListeningPosition(position: listenPos),
  );
}

class RoomNotifier extends Notifier<RoomState> {
  @override
  RoomState build() => _buildDefaultState();

  void updateRoom(Room room) {
    state = state.copyWith(room: room);
  }

  void updateLeftSpeakerPosition(RoomPosition position) {
    final clamped = _clampToRoom(position);
    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(position: clamped),
    );
  }

  void updateRightSpeakerPosition(RoomPosition position) {
    final clamped = _clampToRoom(position);
    state = state.copyWith(
      rightSpeaker: state.rightSpeaker.copyWith(position: clamped),
    );
  }

  void updateListeningPosition(RoomPosition position) {
    final clamped = _clampToRoom(position);
    state = state.copyWith(
      listeningPosition: ListeningPosition(position: clamped),
    );
  }

  void resetToDefaults() {
    state = _buildDefaultState();
  }

  void autoPlaceSpeakers() {
    final room = state.room;
    final leftPos = RoomPosition(room.widthMeters / 3, room.lengthMeters / 5);
    final rightPos =
        RoomPosition(room.widthMeters * 2 / 3, room.lengthMeters / 5);
    final listenPos =
        RoomPosition(room.widthMeters / 2, room.lengthMeters * 0.6);

    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(position: leftPos),
      rightSpeaker: state.rightSpeaker.copyWith(position: rightPos),
      listeningPosition: ListeningPosition(position: listenPos),
    );
  }

  void suggestOptimalListeningPosition() {
    final calc = const SweetSpotCalculator();
    final suggestedPos = calc.suggestListeningPosition(
      state.leftSpeaker,
      state.rightSpeaker,
    );
    final clamped = _clampToRoom(suggestedPos);
    state = state.copyWith(
      listeningPosition: ListeningPosition(position: clamped),
    );
  }

  RoomPosition _clampToRoom(RoomPosition pos) {
    const margin = 0.1;
    final room = state.room;
    return RoomPosition(
      pos.x.clamp(margin, room.widthMeters - margin),
      pos.y.clamp(margin, room.lengthMeters - margin),
    );
  }
}

final roomProvider = NotifierProvider<RoomNotifier, RoomState>(
  RoomNotifier.new,
);

final sweetSpotResultProvider = Provider<SweetSpotResult>((ref) {
  final roomState = ref.watch(roomProvider);
  const calculator = SweetSpotCalculator();
  return calculator.calculate(
    leftSpeaker: roomState.leftSpeaker,
    rightSpeaker: roomState.rightSpeaker,
    listeningPosition: roomState.listeningPosition,
  );
});

final reflectionPointsProvider = Provider<List<ReflectionPoint>>((ref) {
  final roomState = ref.watch(roomProvider);
  const calculator = ReflectionCalculator();
  return calculator.calculateReflections(
    room: roomState.room,
    leftSpeaker: roomState.leftSpeaker,
    rightSpeaker: roomState.rightSpeaker,
    listeningPosition: roomState.listeningPosition,
  );
});
