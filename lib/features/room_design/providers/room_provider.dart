import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../acoustic/models/reflection_point.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../../acoustic/services/aiming_calculator.dart';
import '../../acoustic/services/reflection_calculator.dart';
import '../../acoustic/services/sweet_spot_calculator.dart';
import '../models/editable_distance_target.dart';
import '../models/listening_position.dart';
import '../models/room.dart';
import '../models/room_position.dart';
import '../models/room_state.dart';
import '../models/speaker.dart';

RoomState _buildDefaultState() {
  const room = Room(widthMeters: 5.0, lengthMeters: 6.0);
  // Place left speaker at 1/3 width, 1/5 length
  final leftPos = RoomPosition(room.widthMeters / 3, room.lengthMeters / 5);
  // Place right speaker symmetrically
  final rightPos = RoomPosition(
    room.widthMeters * 2 / 3,
    room.lengthMeters / 5,
  );
  // Listening position at center, 60% depth
  final listenPos = RoomPosition(room.widthMeters / 2, room.lengthMeters * 0.6);

  return RoomState(
    room: room,
    leftSpeaker: Speaker(
      channel: SpeakerChannel.left,
      position: leftPos,
      toeInDegrees: 0.0,
    ),
    rightSpeaker: Speaker(
      channel: SpeakerChannel.right,
      position: rightPos,
      toeInDegrees: 0.0,
    ),
    listeningPosition: ListeningPosition(position: listenPos),
  );
}

class RoomNotifier extends Notifier<RoomState> {
  @override
  RoomState build() => _buildDefaultState();

  void updateRoom(Room room) {
    state = state.copyWith(room: room);
    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(
        position: _clampToRoom(state.leftSpeaker.position),
      ),
      rightSpeaker: state.rightSpeaker.copyWith(
        position: _clampToRoom(state.rightSpeaker.position),
      ),
      listeningPosition: ListeningPosition(
        position: _clampToRoom(state.listeningPosition.position),
      ),
    );
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

  void updateLeftSpeakerToeIn(double toeInDegrees) {
    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(
        toeInDegrees: toeInDegrees.clamp(0.0, 45.0),
      ),
    );
  }

  void updateRightSpeakerToeIn(double toeInDegrees) {
    state = state.copyWith(
      rightSpeaker: state.rightSpeaker.copyWith(
        toeInDegrees: toeInDegrees.clamp(0.0, 45.0),
      ),
    );
  }

  void resetToDefaults() {
    state = _buildDefaultState();
  }

  void setDistanceToWall({
    required MeasuredEntity entity,
    required RoomWall wall,
    required double distanceMeters,
  }) {
    final room = state.room;
    final maxDistance = _maxDistanceForWall(wall);
    final clampedDistance = distanceMeters.clamp(0.0, maxDistance).toDouble();

    RoomPosition move(RoomPosition pos) {
      switch (wall) {
        case RoomWall.left:
          return RoomPosition(clampedDistance, pos.y);
        case RoomWall.right:
          return RoomPosition(room.widthMeters - clampedDistance, pos.y);
        case RoomWall.front:
          return RoomPosition(pos.x, clampedDistance);
        case RoomWall.back:
          return RoomPosition(pos.x, room.lengthMeters - clampedDistance);
      }
    }

    switch (entity) {
      case MeasuredEntity.focus:
        updateListeningPosition(move(state.listeningPosition.position));
        break;
      case MeasuredEntity.leftSpeaker:
        updateLeftSpeakerPosition(move(state.leftSpeaker.position));
        break;
      case MeasuredEntity.rightSpeaker:
        updateRightSpeakerPosition(move(state.rightSpeaker.position));
        break;
    }
  }

  double _maxDistanceForWall(RoomWall wall) {
    final room = state.room;
    switch (wall) {
      case RoomWall.left:
      case RoomWall.right:
        return room.widthMeters;
      case RoomWall.front:
      case RoomWall.back:
        return room.lengthMeters;
    }
  }

  RoomPosition _clampToRoom(RoomPosition pos) {
    const margin = 0.1;
    final room = state.room;
    const minX = margin;
    final maxX = room.widthMeters > margin * 2
        ? room.widthMeters - margin
        : room.widthMeters;
    const minY = margin;
    final maxY = room.lengthMeters > margin * 2
        ? room.lengthMeters - margin
        : room.lengthMeters;

    return RoomPosition(
      pos.x.clamp(minX, maxX).toDouble(),
      pos.y.clamp(minY, maxY).toDouble(),
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

final recommendedAimingPointProvider = Provider<RoomPosition>((ref) {
  final roomState = ref.watch(roomProvider);
  const calculator = AimingCalculator();
  return calculator.calculateRecommendedAimingPoint(
    leftSpeaker: roomState.leftSpeaker,
    rightSpeaker: roomState.rightSpeaker,
    listeningPosition: roomState.listeningPosition,
  );
});

final recommendedLeftToeInProvider = Provider<double>((ref) {
  final roomState = ref.watch(roomProvider);
  final aimingPoint = ref.watch(recommendedAimingPointProvider);
  const calculator = AimingCalculator();
  return calculator.calculateRequiredToeIn(
    speaker: roomState.leftSpeaker,
    targetPoint: aimingPoint,
  );
});

final recommendedRightToeInProvider = Provider<double>((ref) {
  final roomState = ref.watch(roomProvider);
  final aimingPoint = ref.watch(recommendedAimingPointProvider);
  const calculator = AimingCalculator();
  return calculator.calculateRequiredToeIn(
    speaker: roomState.rightSpeaker,
    targetPoint: aimingPoint,
  );
});
