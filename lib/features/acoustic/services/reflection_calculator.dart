import '../../room_design/models/room.dart';
import '../../room_design/models/room_position.dart';
import '../../room_design/models/speaker.dart';
import '../../room_design/models/listening_position.dart';
import '../models/reflection_point.dart';

class ReflectionCalculator {
  const ReflectionCalculator();

  /// Calculates first reflection points on all four walls for both speakers.
  List<ReflectionPoint> calculateReflections({
    required Room room,
    required Speaker leftSpeaker,
    required Speaker rightSpeaker,
    required ListeningPosition listeningPosition,
  }) {
    final reflections = <ReflectionPoint>[];

    for (final speaker in [leftSpeaker, rightSpeaker]) {
      final wallReflections = _reflectionsForSpeaker(
        room: room,
        speaker: speaker.position,
        listener: listeningPosition.position,
      );
      reflections.addAll(wallReflections);
    }

    return reflections;
  }

  List<ReflectionPoint> _reflectionsForSpeaker({
    required Room room,
    required RoomPosition speaker,
    required RoomPosition listener,
  }) {
    final results = <ReflectionPoint>[];

    // Left wall (x = 0)
    final leftRefl = _reflectOffVerticalWall(
      wallX: 0,
      speaker: speaker,
      listener: listener,
      roomLength: room.lengthMeters,
    );
    if (leftRefl != null) {
      results.add(ReflectionPoint(
        wall: ReflectionWall.left,
        position: leftRefl,
        speakerPosition: speaker,
        listenerPosition: listener,
      ));
    }

    // Right wall (x = roomWidth)
    final rightRefl = _reflectOffVerticalWall(
      wallX: room.widthMeters,
      speaker: speaker,
      listener: listener,
      roomLength: room.lengthMeters,
    );
    if (rightRefl != null) {
      results.add(ReflectionPoint(
        wall: ReflectionWall.right,
        position: rightRefl,
        speakerPosition: speaker,
        listenerPosition: listener,
      ));
    }

    // Front wall (y = 0)
    final frontRefl = _reflectOffHorizontalWall(
      wallY: 0,
      speaker: speaker,
      listener: listener,
      roomWidth: room.widthMeters,
    );
    if (frontRefl != null) {
      results.add(ReflectionPoint(
        wall: ReflectionWall.front,
        position: frontRefl,
        speakerPosition: speaker,
        listenerPosition: listener,
      ));
    }

    // Back wall (y = roomLength)
    final backRefl = _reflectOffHorizontalWall(
      wallY: room.lengthMeters,
      speaker: speaker,
      listener: listener,
      roomWidth: room.widthMeters,
    );
    if (backRefl != null) {
      results.add(ReflectionPoint(
        wall: ReflectionWall.back,
        position: backRefl,
        speakerPosition: speaker,
        listenerPosition: listener,
      ));
    }

    return results;
  }

  /// Reflects off a vertical wall at x = wallX using the mirror image method.
  RoomPosition? _reflectOffVerticalWall({
    required double wallX,
    required RoomPosition speaker,
    required RoomPosition listener,
    required double roomLength,
  }) {
    // Mirror the speaker across the wall
    final mirroredX = 2 * wallX - speaker.x;

    // Line from mirrored speaker to listener
    final dx = listener.x - mirroredX;
    if (dx.abs() < 1e-9) return null; // Parallel to wall

    final t = (wallX - mirroredX) / dx;
    if (t < 0 || t > 1) return null; // Intersection not between source and listener

    final y = speaker.y + t * (listener.y - speaker.y);

    // Ensure the point is within the wall bounds
    if (y < 0 || y > roomLength) return null;

    return RoomPosition(wallX, y);
  }

  /// Reflects off a horizontal wall at y = wallY using the mirror image method.
  RoomPosition? _reflectOffHorizontalWall({
    required double wallY,
    required RoomPosition speaker,
    required RoomPosition listener,
    required double roomWidth,
  }) {
    // Mirror the speaker across the wall
    final mirroredY = 2 * wallY - speaker.y;

    // Line from mirrored speaker to listener
    final dy = listener.y - mirroredY;
    if (dy.abs() < 1e-9) return null; // Parallel to wall

    final t = (wallY - mirroredY) / dy;
    if (t < 0 || t > 1) return null; // Intersection not on path

    final x = speaker.x + t * (listener.x - speaker.x);

    // Ensure the point is within the wall bounds
    if (x < 0 || x > roomWidth) return null;

    return RoomPosition(x, wallY);
  }
}
