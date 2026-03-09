import 'room_position.dart';

class RoomBlockerZone {
  final int id;
  final double x;
  final double y;
  final double width;
  final double height;

  const RoomBlockerZone({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double get right => x + width;

  double get bottom => y + height;

  bool contains(RoomPosition position) {
    return position.x >= x &&
        position.x <= right &&
        position.y >= y &&
        position.y <= bottom;
  }

  RoomBlockerZone copyWith({
    int? id,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return RoomBlockerZone(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
