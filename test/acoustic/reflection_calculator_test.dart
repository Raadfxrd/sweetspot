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
    test('calculates reflections for speaker', () {
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

      expect(reflections, isNotEmpty);
      for (final r in reflections) {
        expect(r.position.x, greaterThanOrEqualTo(0));
        expect(r.position.x, lessThanOrEqualTo(room.widthMeters));
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

    test('returns multiple reflections', () {
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

    test('toe-in updates dispersion rays', () {
      final leftZero = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.5, 1.5),
        toeInDegrees: 0,
      );
      final rightZero = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.5, 1.5),
        toeInDegrees: 0,
      );
      final leftToeIn = leftZero.copyWith(toeInDegrees: 20);
      final rightToeIn = rightZero.copyWith(toeInDegrees: 20);
      final listener = const ListeningPosition(
        position: RoomPosition(3.0, 5.0),
      );

      final base = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftZero,
        rightSpeaker: rightZero,
        listeningPosition: listener,
      );
      final steered = calculator.calculateReflections(
        room: room,
        leftSpeaker: leftToeIn,
        rightSpeaker: rightToeIn,
        listeningPosition: listener,
      );

      expect(base, isNotEmpty);
      expect(steered, isNotEmpty);
      expect(base.length, equals(steered.length));

      bool anyDifferent = false;
      for (var i = 0; i < base.length && i < steered.length; i++) {
        if ((base[i].position.x - steered[i].position.x).abs() > 0.001 ||
            (base[i].position.y - steered[i].position.y).abs() > 0.001) {
          anyDifferent = true;
          break;
        }
      }
      expect(anyDifferent, isTrue,
          reason: 'Toe-in should change reflection positions');
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
