import 'dart:math' as math;

import '../../room_design/models/room_blocker_zone.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/room_state.dart';
import '../models/sweet_spot_result.dart';

class RoomContextQualityAdjuster {
  const RoomContextQualityAdjuster();

  static const double minSpeakerSideWallMeters = 0.5;
  static const double minSpeakerFrontWallMeters = 0.6;
  static const double minListenerBackWallMeters = 1.0;
  static const double blockerComfortDistanceMeters = 0.35;

  SweetSpotResult apply({
    required SweetSpotResult base,
    required RoomState state,
  }) {
    final penalties = _penaltyScore(state);
    final adjustedAccuracy =
        (base.triangleAccuracy - penalties).clamp(0.0, 1.0);

    final notes = <String>[];
    if (_isNearSideWall(state)) {
      notes.add('Increase side-wall distance for both speakers.');
    }
    if (_isNearFrontWall(state)) {
      notes.add('Move speakers further from the front wall.');
    }
    if (_isListenerBackOrMidRisk(state)) {
      notes
          .add('Move listening position away from back wall or room midpoint.');
    }
    if (_isNearBlocker(state)) {
      notes.add('Increase clearance from blocked areas or furniture.');
    }

    final feedback = notes.isEmpty
        ? base.feedback
        : '${base.feedback} ${notes.join(' ')}'.trim();

    return SweetSpotResult(
      leftDistance: base.leftDistance,
      rightDistance: base.rightDistance,
      speakerSpacing: base.speakerSpacing,
      listeningDistance: base.listeningDistance,
      triangleAccuracy: adjustedAccuracy,
      isOptimal: adjustedAccuracy >= 0.85,
      feedback: feedback,
    );
  }

  double _penaltyScore(RoomState state) {
    final room = state.room;
    final left = state.leftSpeaker.position;
    final right = state.rightSpeaker.position;
    final listener = state.listeningPosition.position;

    final leftSidePenalty = _gapPenalty(left.x, minSpeakerSideWallMeters, 0.16);
    final rightSidePenalty =
        _gapPenalty(room.widthMeters - right.x, minSpeakerSideWallMeters, 0.16);

    final leftFrontPenalty =
        _gapPenalty(left.y, minSpeakerFrontWallMeters, 0.12);
    final rightFrontPenalty =
        _gapPenalty(right.y, minSpeakerFrontWallMeters, 0.12);

    final backWallPenalty = _gapPenalty(
      room.lengthMeters - listener.y,
      minListenerBackWallMeters,
      0.15,
    );

    final listenerDepthRatio =
        room.lengthMeters <= 0 ? 0.5 : listener.y / room.lengthMeters;
    final midpointRisk =
        (0.08 - (listenerDepthRatio - 0.5).abs()).clamp(0.0, 0.08) / 0.08;
    final midpointPenalty = midpointRisk * 0.1;

    final blockerPenalty = _blockerPenalty(state);

    return leftSidePenalty +
        rightSidePenalty +
        leftFrontPenalty +
        rightFrontPenalty +
        backWallPenalty +
        midpointPenalty +
        blockerPenalty;
  }

  double _blockerPenalty(RoomState state) {
    if (state.blockerZones.isEmpty) return 0.0;

    final points = <RoomPosition>[
      state.leftSpeaker.position,
      state.rightSpeaker.position,
      state.listeningPosition.position,
    ];

    var total = 0.0;
    for (final point in points) {
      var worst = 0.0;
      for (final blocker in state.blockerZones) {
        if (blocker.contains(point)) {
          return 0.35;
        }
        final d = _distanceToBlocker(point, blocker);
        final risk =
            ((blockerComfortDistanceMeters - d) / blockerComfortDistanceMeters)
                .clamp(0.0, 1.0)
                .toDouble();
        worst = math.max(worst, risk * 0.08);
      }
      total += worst;
    }

    return total;
  }

  double _distanceToBlocker(RoomPosition point, RoomBlockerZone blocker) {
    final dx = point.x < blocker.x
        ? blocker.x - point.x
        : (point.x > blocker.right ? point.x - blocker.right : 0.0);
    final dy = point.y < blocker.y
        ? blocker.y - point.y
        : (point.y > blocker.bottom ? point.y - blocker.bottom : 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  double _gapPenalty(double actualGap, double targetGap, double maxPenalty) {
    if (actualGap >= targetGap) return 0.0;
    final deficit =
        ((targetGap - actualGap) / targetGap).clamp(0.0, 1.0).toDouble();
    return deficit * maxPenalty;
  }

  bool _isNearSideWall(RoomState state) {
    final room = state.room;
    return state.leftSpeaker.position.x < minSpeakerSideWallMeters ||
        room.widthMeters - state.rightSpeaker.position.x <
            minSpeakerSideWallMeters;
  }

  bool _isNearFrontWall(RoomState state) {
    return state.leftSpeaker.position.y < minSpeakerFrontWallMeters ||
        state.rightSpeaker.position.y < minSpeakerFrontWallMeters;
  }

  bool _isListenerBackOrMidRisk(RoomState state) {
    final room = state.room;
    final backGap = room.lengthMeters - state.listeningPosition.position.y;
    final depthRatio = room.lengthMeters <= 0
        ? 0.5
        : state.listeningPosition.position.y / room.lengthMeters;
    return backGap < minListenerBackWallMeters ||
        (depthRatio - 0.5).abs() < 0.08;
  }

  bool _isNearBlocker(RoomState state) {
    if (state.blockerZones.isEmpty) return false;

    final points = <RoomPosition>[
      state.leftSpeaker.position,
      state.rightSpeaker.position,
      state.listeningPosition.position,
    ];

    for (final point in points) {
      for (final blocker in state.blockerZones) {
        if (blocker.contains(point)) return true;
        if (_distanceToBlocker(point, blocker) < blockerComfortDistanceMeters) {
          return true;
        }
      }
    }
    return false;
  }
}
