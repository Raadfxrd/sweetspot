import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';

void main() {
  group('RoomPosition', () {
    test('distanceTo calculates Euclidean distance', () {
      const a = RoomPosition(0, 0);
      const b = RoomPosition(3, 4);
      expect(a.distanceTo(b), closeTo(5.0, 0.001));
    });

    test('distanceTo is zero for same position', () {
      const a = RoomPosition(2.5, 3.5);
      expect(a.distanceTo(a), closeTo(0.0, 0.001));
    });

    test('copyWith updates x and y', () {
      const pos = RoomPosition(1.0, 2.0);
      final updated = pos.copyWith(x: 5.0);
      expect(updated.x, equals(5.0));
      expect(updated.y, equals(2.0));
    });

    test('operator + adds positions', () {
      const a = RoomPosition(1.0, 2.0);
      const b = RoomPosition(3.0, 4.0);
      final result = a + b;
      expect(result.x, equals(4.0));
      expect(result.y, equals(6.0));
    });

    test('operator - subtracts positions', () {
      const a = RoomPosition(5.0, 8.0);
      const b = RoomPosition(2.0, 3.0);
      final result = a - b;
      expect(result.x, equals(3.0));
      expect(result.y, equals(5.0));
    });

    test('equality works correctly', () {
      const a = RoomPosition(1.5, 2.5);
      const b = RoomPosition(1.5, 2.5);
      const c = RoomPosition(1.0, 2.5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('Room', () {
    test('area calculates width * length', () {
      const room = Room(widthMeters: 4.0, lengthMeters: 5.0);
      expect(room.area, equals(20.0));
    });

    test('copyWith updates dimensions', () {
      const room = Room(widthMeters: 4.0, lengthMeters: 5.0);
      final updated = room.copyWith(widthMeters: 6.0);
      expect(updated.widthMeters, equals(6.0));
      expect(updated.lengthMeters, equals(5.0));
    });
  });
}
