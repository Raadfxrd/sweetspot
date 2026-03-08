import 'dart:math' as math;
import 'dart:ui';

class RoomPosition {
  final double x;
  final double y;

  const RoomPosition(this.x, this.y);

  RoomPosition copyWith({double? x, double? y}) {
    return RoomPosition(x ?? this.x, y ?? this.y);
  }

  RoomPosition operator +(RoomPosition other) {
    return RoomPosition(x + other.x, y + other.y);
  }

  RoomPosition operator -(RoomPosition other) {
    return RoomPosition(x - other.x, y - other.y);
  }

  double distanceTo(RoomPosition other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Offset toOffset() => Offset(x, y);

  static RoomPosition fromOffset(Offset offset) {
    return RoomPosition(offset.dx, offset.dy);
  }

  @override
  String toString() => 'RoomPosition($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is RoomPosition && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}
