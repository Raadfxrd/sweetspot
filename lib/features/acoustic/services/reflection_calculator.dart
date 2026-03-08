import 'dart:math' as math;

import '../../room_design/models/listening_position.dart';
import '../../room_design/models/room.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/speaker.dart';
import '../models/reflection_point.dart';

class ReflectionCalculator {
  const ReflectionCalculator();

  List<ReflectionPoint> calculateReflections({
    required Room room,
    required Speaker leftSpeaker,
    required Speaker rightSpeaker,
    required ListeningPosition listeningPosition,
  }) {
    final reflections = <ReflectionPoint>[];

    // Create an aiming line for each speaker showing where it points
    reflections.add(_createAimingLine(leftSpeaker, listeningPosition, room));
    reflections.add(_createAimingLine(rightSpeaker, listeningPosition, room));

    return reflections;
  }

  ReflectionPoint _createAimingLine(
    Speaker speaker,
    ListeningPosition listener,
    Room room,
  ) {
    final source = speaker.position;
    final forward = _speakerForwardAxis(speaker);

    // Extend the forward axis to room edge for visualization
    const rayLength = 20.0;
    final endPoint = RoomPosition(
      (source.x + forward.$1 * rayLength).clamp(0.0, room.widthMeters),
      (source.y + forward.$2 * rayLength).clamp(0.0, room.lengthMeters),
    );

    return ReflectionPoint(
      wall: ReflectionWall.front,
      position: endPoint,
      speakerPosition: source,
      listenerPosition: listener.position,
      strength: 1.0,
      highFrequencyStrength: 1.0,
      lowFrequencyStrength: 1.0,
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
