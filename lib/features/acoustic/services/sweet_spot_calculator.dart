import 'dart:math' as math;
import '../../room_design/models/room_position.dart';
import '../../room_design/models/speaker.dart';
import '../../room_design/models/listening_position.dart';
import '../models/sweet_spot_result.dart';

class SweetSpotCalculator {
  const SweetSpotCalculator();

  SweetSpotResult calculate({
    required Speaker leftSpeaker,
    required Speaker rightSpeaker,
    required ListeningPosition listeningPosition,
  }) {
    final lPos = leftSpeaker.position;
    final rPos = rightSpeaker.position;
    final lpPos = listeningPosition.position;

    final leftDist = lPos.distanceTo(lpPos);
    final rightDist = rPos.distanceTo(lpPos);
    final speakerSpacing = lPos.distanceTo(rPos);
    final listeningDist = (leftDist + rightDist) / 2;

    final triangleAccuracy = _calculateTriangleAccuracy(
      leftDist: leftDist,
      rightDist: rightDist,
      speakerSpacing: speakerSpacing,
    );

    final toeInLeft = _calculateToeIn(
      speaker: lPos,
      listener: lpPos,
      isLeft: true,
    );

    final toeInRight = _calculateToeIn(
      speaker: rPos,
      listener: lpPos,
      isLeft: false,
    );

    final isOptimal = triangleAccuracy >= 0.85 &&
        (leftDist - rightDist).abs() / math.max(leftDist, rightDist) < 0.1;

    final feedback = _generateFeedback(
      triangleAccuracy: triangleAccuracy,
      leftDist: leftDist,
      rightDist: rightDist,
      speakerSpacing: speakerSpacing,
    );

    return SweetSpotResult(
      leftDistance: leftDist,
      rightDistance: rightDist,
      speakerSpacing: speakerSpacing,
      listeningDistance: listeningDist,
      triangleAccuracy: triangleAccuracy,
      suggestedToeInLeft: toeInLeft,
      suggestedToeInRight: toeInRight,
      isOptimal: isOptimal,
      feedback: feedback,
    );
  }

  double _calculateTriangleAccuracy({
    required double leftDist,
    required double rightDist,
    required double speakerSpacing,
  }) {
    if (speakerSpacing <= 0 || leftDist <= 0 || rightDist <= 0) return 0;

    final avgListenDist = (leftDist + rightDist) / 2;
    final spacingRatio = speakerSpacing / avgListenDist;

    // Ideal ratio is 1.0 (equilateral triangle)
    final ratioDeviation = (spacingRatio - 1.0).abs();

    // Symmetry: left and right distances should be equal
    final maxDist = math.max(leftDist, rightDist);
    final distanceAsymmetry = (leftDist - rightDist).abs() / maxDist;

    final ratioScore = math.max(0.0, 1.0 - ratioDeviation * 2);
    final symmetryScore = math.max(0.0, 1.0 - distanceAsymmetry * 2);

    return (ratioScore * 0.6 + symmetryScore * 0.4).clamp(0.0, 1.0);
  }

  double _calculateToeIn({
    required RoomPosition speaker,
    required RoomPosition listener,
    required bool isLeft,
  }) {
    final dx = listener.x - speaker.x;
    final dy = listener.y - speaker.y;

    // Angle from speaker toward listener in degrees
    final angleToListener = math.atan2(dx, -dy) * 180 / math.pi;

    // For left speaker: positive toe-in = angled right (toward center)
    // For right speaker: positive toe-in = angled left (toward center)
    // Ideal is approximately 30 degrees inward for equilateral triangle
    final baseToeIn = isLeft ? angleToListener : -angleToListener;

    return baseToeIn.clamp(0.0, 60.0);
  }

  String _generateFeedback({
    required double triangleAccuracy,
    required double leftDist,
    required double rightDist,
    required double speakerSpacing,
  }) {
    final messages = <String>[];
    final avgListenDist = (leftDist + rightDist) / 2;

    if (speakerSpacing <= 0) {
      return 'Place speakers in the room to begin.';
    }

    if (triangleAccuracy >= 0.9) {
      messages.add('Excellent stereo triangle geometry.');
    } else if (triangleAccuracy >= 0.75) {
      messages.add('Good stereo geometry, minor adjustment recommended.');
    } else if (triangleAccuracy >= 0.5) {
      messages.add('Fair geometry. Move listening position or speakers.');
    } else {
      messages.add('Poor geometry. Significant repositioning needed.');
    }

    final spacingRatio = avgListenDist > 0 ? speakerSpacing / avgListenDist : 0;
    if (spacingRatio < 0.7) {
      messages.add('Speakers too close together or too far from listener.');
    } else if (spacingRatio > 1.4) {
      messages.add('Speakers too far apart relative to listening distance.');
    }

    final asymmetry = avgListenDist > 0
        ? (leftDist - rightDist).abs() / avgListenDist
        : 0.0;
    if (asymmetry > 0.1) {
      messages.add('Listening position is off-center.');
    }

    return messages.join(' ');
  }

  /// Returns the ideal listening position for an equilateral triangle.
  RoomPosition suggestListeningPosition(Speaker left, Speaker right) {
    final lPos = left.position;
    final rPos = right.position;
    final midX = (lPos.x + rPos.x) / 2;
    final midY = (lPos.y + rPos.y) / 2;
    final speakerSpacing = lPos.distanceTo(rPos);

    // Equilateral triangle height
    final height = speakerSpacing * (math.sqrt(3) / 2);

    // Direction from speaker line toward listener (behind the midpoint)
    final dx = rPos.x - lPos.x;
    final dy = rPos.y - lPos.y;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return RoomPosition(midX, midY);

    // Perpendicular direction (pointing "into" the room)
    final perpX = dy / len;
    final perpY = -dx / len;

    return RoomPosition(
      midX + perpX * height,
      midY + perpY * height,
    );
  }
}
