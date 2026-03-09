import 'dart:math' as math;

import '../../room_design/models/listening_position.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/speaker.dart';

class AimingCalculator {
  const AimingCalculator();

  static const double recommendedBehindDistanceMeters = 1.5;

  RoomPosition calculateRecommendedAimingPoint({
    required Speaker leftSpeaker,
    required Speaker rightSpeaker,
    required ListeningPosition listeningPosition,
  }) {
    final lpPos = listeningPosition.position;
    final lPos = leftSpeaker.position;
    final rPos = rightSpeaker.position;

    final speakerMidX = (lPos.x + rPos.x) / 2;
    final speakerMidY = (lPos.y + rPos.y) / 2;

    final dx = lpPos.x - speakerMidX;
    final dy = lpPos.y - speakerMidY;
    final distToListener = math.sqrt(dx * dx + dy * dy);

    if (distToListener < 0.01) {
      return lpPos;
    }

    final ndx = dx / distToListener;
    final ndy = dy / distToListener;

    return RoomPosition(
      lpPos.x + ndx * recommendedBehindDistanceMeters,
      lpPos.y + ndy * recommendedBehindDistanceMeters,
    );
  }

  double calculateRequiredToeIn({
    required Speaker speaker,
    required RoomPosition targetPoint,
  }) {
    final speakerPos = speaker.position;

    final dx = targetPoint.x - speakerPos.x;
    final dy = targetPoint.y - speakerPos.y;

    if (dx.abs() < 1e-9 && dy.abs() < 1e-9) {
      return 0.0;
    }

    final angleToTarget = math.atan2(dx, dy);

    final isLeft = speaker.channel == SpeakerChannel.left;

    final toeInRadians = isLeft ? angleToTarget : -angleToTarget;
    final toeInDegrees = toeInRadians * 180 / math.pi;

    return toeInDegrees.clamp(0.0, 45.0);
  }

  RoomPosition calculateCurrentAimingPoint({
    required Speaker speaker,
    double? rayLength,
  }) {
    final speakerPos = speaker.position;
    final forward = _speakerForwardAxis(speaker);
    final length = rayLength ?? 10.0;

    return RoomPosition(
      speakerPos.x + forward.$1 * length,
      speakerPos.y + forward.$2 * length,
    );
  }

  (double, double) _speakerForwardAxis(Speaker speaker) {
    final toeInRad = speaker.toeInDegrees * math.pi / 180;
    final xSign = speaker.channel == SpeakerChannel.left ? 1.0 : -1.0;
    final fx = math.sin(toeInRad) * xSign;
    final fy = math.cos(toeInRad);
    final len = math.sqrt(fx * fx + fy * fy);
    if (len < 1e-9) return (0.0, 1.0);
    return (fx / len, fy / len);
  }
}
