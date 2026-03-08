import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/models/reflection_point.dart';
import 'package:sweetspot/features/acoustic/services/reflection_calculator.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';

void main() {
  const calculator = ReflectionCalculator();
  const room = Room(widthMeters: 6.0, lengthMeters: 8.0);

  group('ReflectionCalculator', () {
    test('calculates left wall reflection for left speaker', () {
      final leftSpeaker = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
      );
      final rightSpeaker = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final reflections = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker,
        listeningPosition: listener,
      );

      final leftWallReflections = reflections
          .where((r) => r.wall == ReflectionWall.left)
          .toList();

      expect(leftWallReflections, isNotEmpty);
      for (final r in leftWallReflections) {
        expect(r.position.x, closeTo(0.0, 0.001));
        expect(r.position.y, greaterThanOrEqualTo(0));
        expect(r.position.y, lessThanOrEqualTo(room.lengthMeters));
      }
    });

    test('calculates right wall reflection for right speaker', () {
      final leftSpeaker = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
      );
      final rightSpeaker = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final reflections = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker,
        listeningPosition: listener,
      );

      final rightWallReflections = reflections
          .where((r) => r.wall == ReflectionWall.right)
          .toList();

      expect(rightWallReflections, isNotEmpty);
      for (final r in rightWallReflections) {
        expect(r.position.x, closeTo(room.widthMeters, 0.001));
        expect(r.position.y, greaterThanOrEqualTo(0));
        expect(r.position.y, lessThanOrEqualTo(room.lengthMeters));
      }
    });

    test('reflection point is on the correct wall', () {
      final leftSpeaker = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
      );
      final rightSpeaker = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final reflections = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker,
        listeningPosition: listener,
      );

      for (final rp in reflections) {
        switch (rp.wall) {
          case ReflectionWall.left:
            expect(rp.position.x, closeTo(0.0, 0.001));
            break;
          case ReflectionWall.right:
            expect(rp.position.x, closeTo(room.widthMeters, 0.001));
            break;
          case ReflectionWall.front:
            expect(rp.position.y, closeTo(0.0, 0.001));
            break;
          case ReflectionWall.back:
            expect(rp.position.y, closeTo(room.lengthMeters, 0.001));
            break;
        }
      }
    });

    test('does not return reflections outside room bounds', () {
      final leftSpeaker = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
      );
      final rightSpeaker = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final reflections = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker,
        listeningPosition: listener,
      );

      for (final rp in reflections) {
        expect(rp.position.x, greaterThanOrEqualTo(0));
        expect(rp.position.x, lessThanOrEqualTo(room.widthMeters));
        expect(rp.position.y, greaterThanOrEqualTo(0));
        expect(rp.position.y, lessThanOrEqualTo(room.lengthMeters));
      }
    });

    test('returns multiple reflections (both speakers have reflections)', () {
      final leftSpeaker = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
      );
      final rightSpeaker = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final reflections = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftSpeaker,
        rightSpeaker: rightSpeaker,
        listeningPosition: listener,
      );

      expect(reflections.length, greaterThan(2));
    });
  });

  group('ReflectionPoint', () {
    test('wallLabel returns correct string', () {
      final rp = ReflectionPoint(
        wall: ReflectionWall.left,
        position: const RoomPosition(0, 3),
        speakerPosition: const RoomPosition(1.5, 1.5),
        listenerPosition: const RoomPosition(3.0, 5.0),
      );
      expect(rp.wallLabel, equals('Left Wall'));
    });
  });
}
