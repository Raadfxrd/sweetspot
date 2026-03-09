import 'dart:math' as math;

import '../../room_design/models/room.dart';
import '../../room_design/models/room_blocker_zone.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/room_state.dart';
import '../../room_design/models/speaker.dart';
import '../models/optimization_instruction.dart';

class OptimizationInstructionGenerator {
  const OptimizationInstructionGenerator();

  static const double movementThresholdMeters = 0.03;
  static const double speakerSideWallSafetyMeters = 0.35;

  List<OptimizationInstruction> generate({
    required RoomState current,
    required RoomState optimized,
  }) {
    final room = current.room;
    final ranked = <_ScoredInstruction>[];

    final leftMove = _speakerMoveInstruction(
      channel: SpeakerChannel.left,
      from: current.leftSpeaker.position,
      to: optimized.leftSpeaker.position,
      room: room,
    );
    if (leftMove != null) {
      ranked.add(
        _rankByPriority(
          current: current,
          optimized: optimized,
          text: leftMove,
          changedEntity: _ChangedEntity.leftSpeaker,
        ),
      );
    }

    final rightMove = _speakerMoveInstruction(
      channel: SpeakerChannel.right,
      from: current.rightSpeaker.position,
      to: optimized.rightSpeaker.position,
      room: room,
    );
    if (rightMove != null) {
      ranked.add(
        _rankByPriority(
          current: current,
          optimized: optimized,
          text: rightMove,
          changedEntity: _ChangedEntity.rightSpeaker,
        ),
      );
    }

    final listenerMove = _listeningPositionInstruction(
      from: current.listeningPosition.position,
      to: optimized.listeningPosition.position,
      room: room,
    );
    if (listenerMove != null) {
      ranked.add(
        _rankByPriority(
          current: current,
          optimized: optimized,
          text: listenerMove,
          changedEntity: _ChangedEntity.listener,
        ),
      );
    }

    ranked.sort((a, b) {
      final diff = b.impact - a.impact;
      if (diff.abs() > 1e-6) {
        return diff > 0 ? 1 : -1;
      }
      return a.tieBreaker.compareTo(b.tieBreaker);
    });

    return ranked.map((s) => OptimizationInstruction(s.text)).toList();
  }

  _ScoredInstruction _rankByPriority({
    required RoomState current,
    required RoomState optimized,
    required String text,
    required _ChangedEntity changedEntity,
  }) {
    final partial = switch (changedEntity) {
      _ChangedEntity.leftSpeaker => current.copyWith(
          leftSpeaker: current.leftSpeaker
              .copyWith(position: optimized.leftSpeaker.position),
        ),
      _ChangedEntity.rightSpeaker => current.copyWith(
          rightSpeaker: current.rightSpeaker
              .copyWith(position: optimized.rightSpeaker.position),
        ),
      _ChangedEntity.listener => current.copyWith(
          listeningPosition: current.listeningPosition
              .copyWith(position: optimized.listeningPosition.position),
        ),
    };

    final currentPenalty = _layoutPenalty(current);
    final improvedPenalty = _layoutPenalty(partial);
    final impact = currentPenalty - improvedPenalty;

    return _ScoredInstruction(
      text: text,
      impact: impact,
      tieBreaker: switch (changedEntity) {
        _ChangedEntity.leftSpeaker => 0,
        _ChangedEntity.rightSpeaker => 1,
        _ChangedEntity.listener => 2,
      },
    );
  }

  String? _speakerMoveInstruction({
    required SpeakerChannel channel,
    required RoomPosition from,
    required RoomPosition to,
    required Room room,
  }) {
    final label =
        channel == SpeakerChannel.left ? 'left speaker' : 'right speaker';
    final parts = <String>[];

    final lateral = _speakerLateralPart(
      channel: channel,
      from: from,
      to: to,
      roomWidth: room.widthMeters,
    );
    if (lateral != null) {
      parts.add(lateral);
    }

    final dy = to.y - from.y;
    if (dy.abs() >= movementThresholdMeters) {
      parts.add('${_toCm(dy.abs())} cm ${dy < 0 ? 'forward' : 'backward'}');
    }

    if (parts.isEmpty) return null;
    return 'Move the $label ${parts.join(' and ')}.';
  }

  String? _speakerLateralPart({
    required SpeakerChannel channel,
    required RoomPosition from,
    required RoomPosition to,
    required double roomWidth,
  }) {
    final dx = to.x - from.x;
    if (dx.abs() < movementThresholdMeters) return null;

    final isLeft = channel == SpeakerChannel.left;
    final wallName = isLeft ? 'left wall' : 'right wall';
    final movesAwayFromWall = isLeft ? dx > 0 : dx < 0;

    final targetGap = isLeft ? to.x : roomWidth - to.x;
    if (!movesAwayFromWall && targetGap < speakerSideWallSafetyMeters) {
      return null;
    }

    final movementCm = _toCm(dx.abs());
    final gapCm = _toCm(targetGap);
    final direction = movesAwayFromWall ? 'away from' : 'toward';

    return '$movementCm cm $direction the $wallName (final gap ${gapCm} cm)';
  }

  String? _listeningPositionInstruction({
    required RoomPosition from,
    required RoomPosition to,
    required Room room,
  }) {
    final parts = <String>[];
    final dx = to.x - from.x;
    final dy = to.y - from.y;

    if (dx.abs() >= movementThresholdMeters) {
      parts.add('${_toCm(dx.abs())} cm ${dx < 0 ? 'left' : 'right'}');
    }

    if (dy.abs() >= movementThresholdMeters) {
      parts.add('${_toCm(dy.abs())} cm ${dy < 0 ? 'forward' : 'backward'}');
    }

    if (parts.isEmpty) return null;

    final normalizedY = room.lengthMeters <= 0 ? 0 : to.y / room.lengthMeters;
    if ((normalizedY - 0.5).abs() < 0.05) {
      parts.add('(avoid exact room midpoint)');
    }

    return 'Move the listening position ${parts.join(' and ')}.';
  }

  // Weighted penalty from the requested priority list.
  double _layoutPenalty(RoomState state) {
    final room = state.room;
    final left = state.leftSpeaker.position;
    final right = state.rightSpeaker.position;
    final listener = state.listeningPosition.position;

    final leftDist = left.distanceTo(listener);
    final rightDist = right.distanceTo(listener);
    final avgListenDist = (leftDist + rightDist) / 2;
    final spacing = left.distanceTo(right);

    final listenerDepthRatio =
        room.lengthMeters == 0 ? 0 : listener.y / room.lengthMeters;
    final listenerBackWall = room.lengthMeters - listener.y;

    final penaltyListenerBackOrMid = 90 *
            _square(((0.5 - (listenerDepthRatio - 0.5).abs()) / 0.5)
                .clamp(0.0, 1.0)) +
        120 * _square(((0.9 - listenerBackWall) / 0.9).clamp(0.0, 1.0));

    final penaltyFrontWall =
        70 * _square(((0.7 - left.y) / 0.7).clamp(0.0, 1.0)) +
            70 * _square(((0.7 - right.y) / 0.7).clamp(0.0, 1.0));

    final symmetryDen = math.max(leftDist, rightDist).toDouble();
    final symmetryRatio =
        symmetryDen == 0 ? 0.0 : (leftDist - rightDist).abs() / symmetryDen;
    final penaltyEqualDistance = 120.0 * _square(symmetryRatio);

    final ratio = avgListenDist <= 0 ? 0.0 : spacing / avgListenDist;
    final penaltyTriangle = 110.0 * _square((ratio - 1.0).abs());

    final leftGap = left.x;
    final rightGap = room.widthMeters - right.x;
    final penaltySideWalls = 100.0 *
            _square(((0.6 - leftGap) / 0.6).clamp(0.0, 1.0).toDouble()) +
        100.0 * _square(((0.6 - rightGap) / 0.6).clamp(0.0, 1.0).toDouble());

    final centerX = (left.x + right.x) / 2;
    final listenerOffCenter = room.widthMeters == 0
        ? 0.0
        : ((listener.x - centerX).abs() / room.widthMeters).toDouble();
    final sideAsymmetry = room.widthMeters == 0
        ? 0.0
        : (((left.x) - (room.widthMeters - right.x)).abs() / room.widthMeters)
            .toDouble();
    final penaltySymmetry =
        80.0 * _square(listenerOffCenter) + 70.0 * _square(sideAsymmetry);

    final penaltyListeningDistance = 70.0 *
        _square(((avgListenDist - 2.2).abs() / 2.2).clamp(0.0, 1.0).toDouble());

    final blockerPenalty = _blockerProximityPenalty(
      listener: listener,
      left: left,
      right: right,
      blockers: state.blockerZones,
    );

    return penaltyListenerBackOrMid +
        penaltyFrontWall +
        penaltyEqualDistance +
        penaltyTriangle +
        penaltySideWalls +
        penaltySymmetry +
        penaltyListeningDistance +
        blockerPenalty;
  }

  double _blockerProximityPenalty({
    required RoomPosition listener,
    required RoomPosition left,
    required RoomPosition right,
    required List<RoomBlockerZone> blockers,
  }) {
    if (blockers.isEmpty) return 0;

    double perPointPenalty(RoomPosition point) {
      var worst = 0.0;
      for (final zone in blockers) {
        if (zone.contains(point)) {
          return 200;
        }
        final dist = _distanceToZone(point, zone);
        final risk = ((0.35 - dist) / 0.35).clamp(0.0, 1.0);
        worst = math.max(worst, 60 * _square(risk));
      }
      return worst;
    }

    return perPointPenalty(left) +
        perPointPenalty(right) +
        perPointPenalty(listener);
  }

  double _distanceToZone(RoomPosition p, RoomBlockerZone z) {
    final dx = p.x < z.x ? z.x - p.x : (p.x > z.right ? p.x - z.right : 0.0);
    final dy = p.y < z.y ? z.y - p.y : (p.y > z.bottom ? p.y - z.bottom : 0.0);
    return math.sqrt(dx * dx + dy * dy);
  }

  double _square(double value) => value * value;

  int _toCm(double meters) => (meters * 100).round();
}

enum _ChangedEntity { leftSpeaker, rightSpeaker, listener }

class _ScoredInstruction {
  final String text;
  final double impact;
  final int tieBreaker;

  const _ScoredInstruction({
    required this.text,
    required this.impact,
    required this.tieBreaker,
  });
}
