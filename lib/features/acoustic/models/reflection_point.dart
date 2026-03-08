import '../../room_design/models/room_position.dart';

enum ReflectionWall { left, right, front, back }

class ReflectionPoint {
  final ReflectionWall wall;
  final RoomPosition position;
  final RoomPosition speakerPosition;
  final RoomPosition listenerPosition;
  final double strength;
  final double highFrequencyStrength;
  final double lowFrequencyStrength;

  const ReflectionPoint({
    required this.wall,
    required this.position,
    required this.speakerPosition,
    required this.listenerPosition,
    this.strength = 1.0,
    this.highFrequencyStrength = 1.0,
    this.lowFrequencyStrength = 1.0,
  });

  String get wallLabel {
    switch (wall) {
      case ReflectionWall.left:
        return 'Left Wall';
      case ReflectionWall.right:
        return 'Right Wall';
      case ReflectionWall.front:
        return 'Front Wall';
      case ReflectionWall.back:
        return 'Back Wall';
    }
  }

  @override
  String toString() =>
      'ReflectionPoint($wallLabel @ $position, strength: ${strength.toStringAsFixed(2)})';
}
