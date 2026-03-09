import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../acoustic/models/optimization_result.dart';
import '../../acoustic/models/reflection_point.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../../acoustic/services/aiming_calculator.dart';
import '../../acoustic/services/reflection_calculator.dart';
import '../../acoustic/services/room_context_quality_adjuster.dart';
import '../../acoustic/services/room_optimizer.dart';
import '../../acoustic/services/sweet_spot_calculator.dart';
import '../models/editable_distance_target.dart';
import '../models/listening_position.dart';
import '../models/room.dart';
import '../models/room_blocker_zone.dart';
import '../models/room_position.dart';
import '../models/room_state.dart';
import '../models/speaker.dart';

RoomState _buildDefaultState() {
  const room = Room(widthMeters: 5.0, lengthMeters: 6.0);
  final leftPos = RoomPosition(room.widthMeters / 3, room.lengthMeters / 5);
  final rightPos = RoomPosition(
    room.widthMeters * 2 / 3,
    room.lengthMeters / 5,
  );
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
  int _nextBlockerId = 1;

  @override
  RoomState build() => _buildDefaultState();

  void updateRoom(Room room) {
    state = state.copyWith(
      room: room,
      blockerZones: _clampBlockersToRoom(state.blockerZones, room),
    );
    _ensureEntitiesOutsideBlockers();
  }

  void updateLeftSpeakerPosition(RoomPosition position) {
    final next = _coerceValidPosition(position, state.leftSpeaker.position);
    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(position: next),
    );
  }

  void updateRightSpeakerPosition(RoomPosition position) {
    final next = _coerceValidPosition(position, state.rightSpeaker.position);
    state = state.copyWith(
      rightSpeaker: state.rightSpeaker.copyWith(position: next),
    );
  }

  void updateListeningPosition(RoomPosition position) {
    final next =
        _coerceValidPosition(position, state.listeningPosition.position);
    state = state.copyWith(
      listeningPosition: ListeningPosition(position: next),
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

  void addBlockedZone({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final normalized = _normalizedAndClampedBlocker(
      x: x,
      y: y,
      width: width,
      height: height,
      room: state.room,
      id: _nextBlockerId,
    );
    if (normalized == null) return;

    _nextBlockerId += 1;
    state = state.copyWith(
      blockerZones: [...state.blockerZones, normalized],
    );
    _ensureEntitiesOutsideBlockers();
  }

  void addBlockedZoneFromPoints(RoomPosition start, RoomPosition end) {
    final x = math.min(start.x, end.x);
    final y = math.min(start.y, end.y);
    final width = (start.x - end.x).abs();
    final height = (start.y - end.y).abs();
    addBlockedZone(x: x, y: y, width: width, height: height);
  }

  void removeBlockedZone(int zoneId) {
    state = state.copyWith(
      blockerZones: state.blockerZones.where((z) => z.id != zoneId).toList(),
    );
  }

  void moveBlockedZone({
    required int zoneId,
    required RoomPosition topLeft,
  }) {
    final room = state.room;
    final zones = [...state.blockerZones];
    final index = zones.indexWhere((z) => z.id == zoneId);
    if (index == -1) return;

    final zone = zones[index];
    final maxX = (room.widthMeters - zone.width).clamp(0.0, double.infinity);
    final maxY = (room.lengthMeters - zone.height).clamp(0.0, double.infinity);

    zones[index] = zone.copyWith(
      x: topLeft.x.clamp(0.0, maxX).toDouble(),
      y: topLeft.y.clamp(0.0, maxY).toDouble(),
    );

    state = state.copyWith(blockerZones: zones);
    _ensureEntitiesOutsideBlockers();
  }

  void clearBlockedZones() {
    state = state.copyWith(blockerZones: const []);
  }

  void resetToDefaults() {
    _nextBlockerId = 1;
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

  void _ensureEntitiesOutsideBlockers() {
    state = state.copyWith(
      leftSpeaker: state.leftSpeaker.copyWith(
        position: _nearestValidPosition(state.leftSpeaker.position),
      ),
      rightSpeaker: state.rightSpeaker.copyWith(
        position: _nearestValidPosition(state.rightSpeaker.position),
      ),
      listeningPosition: state.listeningPosition.copyWith(
        position: _nearestValidPosition(state.listeningPosition.position),
      ),
    );
  }

  RoomPosition _coerceValidPosition(
      RoomPosition desired, RoomPosition fallback) {
    final clamped = _clampToRoom(desired);
    if (!_isInsideBlocked(clamped)) {
      return clamped;
    }
    return _nearestValidPosition(fallback);
  }

  RoomPosition _nearestValidPosition(RoomPosition seed) {
    final origin = _clampToRoom(seed);
    if (!_isInsideBlocked(origin)) {
      return origin;
    }

    final room = state.room;
    final maxRadius = math.max(room.widthMeters, room.lengthMeters);

    for (var radius = 0.05; radius <= maxRadius; radius += 0.05) {
      for (var deg = 0; deg < 360; deg += 15) {
        final radians = deg * math.pi / 180;
        final candidate = _clampToRoom(
          RoomPosition(
            origin.x + math.cos(radians) * radius,
            origin.y + math.sin(radians) * radius,
          ),
        );
        if (!_isInsideBlocked(candidate)) {
          return candidate;
        }
      }
    }

    return origin;
  }

  bool _isInsideBlocked(RoomPosition pos, [List<RoomBlockerZone>? zones]) {
    final blockers = zones ?? state.blockerZones;
    return blockers.any((zone) => zone.contains(pos));
  }

  List<RoomBlockerZone> _clampBlockersToRoom(
    List<RoomBlockerZone> blockers,
    Room room,
  ) {
    return blockers
        .map(
          (zone) => _normalizedAndClampedBlocker(
            x: zone.x,
            y: zone.y,
            width: zone.width,
            height: zone.height,
            room: room,
            id: zone.id,
          ),
        )
        .whereType<RoomBlockerZone>()
        .toList();
  }

  RoomBlockerZone? _normalizedAndClampedBlocker({
    required double x,
    required double y,
    required double width,
    required double height,
    required Room room,
    required int id,
  }) {
    const minSize = 0.05;

    final normalizedWidth = width.abs();
    final normalizedHeight = height.abs();

    if (normalizedWidth < minSize || normalizedHeight < minSize) {
      return null;
    }

    final maxX = room.widthMeters.clamp(0.0, double.infinity);
    final maxY = room.lengthMeters.clamp(0.0, double.infinity);

    final clampedX = x.clamp(0.0, maxX).toDouble();
    final clampedY = y.clamp(0.0, maxY).toDouble();

    final availableWidth = (maxX - clampedX).clamp(0.0, double.infinity);
    final availableHeight = (maxY - clampedY).clamp(0.0, double.infinity);

    final clampedWidth = normalizedWidth.clamp(0.0, availableWidth).toDouble();
    final clampedHeight =
        normalizedHeight.clamp(0.0, availableHeight).toDouble();

    if (clampedWidth < minSize || clampedHeight < minSize) {
      return null;
    }

    return RoomBlockerZone(
      id: id,
      x: clampedX,
      y: clampedY,
      width: clampedWidth,
      height: clampedHeight,
    );
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

// Shared hover state so sidebar and canvas can highlight the same blocker.
final hoveredBlockerIdProvider = StateProvider<int?>((ref) => null);

final roomProvider = NotifierProvider<RoomNotifier, RoomState>(
  RoomNotifier.new,
);

final sweetSpotResultProvider = Provider<SweetSpotResult>((ref) {
  final roomState = ref.watch(roomProvider);
  const calculator = SweetSpotCalculator();
  final base = calculator.calculate(
    leftSpeaker: roomState.leftSpeaker,
    rightSpeaker: roomState.rightSpeaker,
    listeningPosition: roomState.listeningPosition,
  );

  const adjuster = RoomContextQualityAdjuster();
  return adjuster.apply(base: base, state: roomState);
});

final optimizationResultProvider = Provider<OptimizationResult>((ref) {
  final roomState = ref.watch(roomProvider);
  const optimizer = RoomOptimizer();
  return optimizer.optimize(roomState);
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
