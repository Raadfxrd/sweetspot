import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/models/sweet_spot_result.dart';
import 'package:sweetspot/features/acoustic/services/sweet_spot_calculator.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';

void main() {
  const calculator = SweetSpotCalculator();

  group('SweetSpotCalculator', () {
    test('returns perfect accuracy for equilateral triangle', () {
      // Equilateral triangle: spacing == listening distance
      const spacing = 2.0;
      final height = spacing * (math.sqrt(3) / 2);

      final left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(0.0, 0.0),
      );
      final right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(spacing, 0.0),
      );
      final listener = ListeningPosition(
        position: RoomPosition(spacing / 2, height),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.speakerSpacing, closeTo(spacing, 0.001));
      expect(result.leftDistance, closeTo(spacing, 0.001));
      expect(result.rightDistance, closeTo(spacing, 0.001));
      expect(result.triangleAccuracy, closeTo(1.0, 0.05));
      expect(result.isOptimal, isTrue);
    });

    test('detects asymmetric listener position', () {
      final left = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.0, 0.0),
      );
      final right = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(3.0, 0.0),
      );
      // Listener far to the left
      final listener = const ListeningPosition(
        position: RoomPosition(0.5, 2.0),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.leftDistance, lessThan(result.rightDistance));
      expect(result.triangleAccuracy, lessThan(0.9));
    });

    test('calculates correct speaker spacing', () {
      final left = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.0, 1.0),
      );
      final right = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.0, 1.0),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(2.5, 3.5),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.speakerSpacing, closeTo(3.0, 0.001));
    });

    test('accuracy is zero when speakers overlap', () {
      final pos = const RoomPosition(2.5, 1.0);
      final left = Speaker(channel: SpeakerChannel.left, position: pos);
      final right = Speaker(channel: SpeakerChannel.right, position: pos);
      final listener = const ListeningPosition(
        position: RoomPosition(2.5, 3.5),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.speakerSpacing, closeTo(0.0, 0.001));
      expect(result.triangleAccuracy, equals(0.0));
    });

    test('symmetry ratio is 1.0 for symmetric placement', () {
      final left = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(1.0, 1.0),
      );
      final right = Speaker(
        channel: SpeakerChannel.right,
        position: const RoomPosition(4.0, 1.0),
      );
      final listener = const ListeningPosition(
        position: RoomPosition(2.5, 3.0),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.leftDistance, closeTo(result.rightDistance, 0.001));
      expect(result.symmetryRatio, closeTo(1.0, 0.01));
    });

    test('suggestListeningPosition returns equilateral apex', () {
      const spacing = 2.0;
      final left = Speaker(
        channel: SpeakerChannel.left,
        position: const RoomPosition(0.0, 0.0),
      );
      final right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(spacing, 0.0),
      );

      final suggested = calculator.suggestListeningPosition(left, right);
      final expectedY = spacing * (math.sqrt(3) / 2);

      expect(suggested.x, closeTo(spacing / 2, 0.001));
      expect(suggested.y, greaterThan(0));
      expect(suggested.y, closeTo(expectedY, 0.001));
    });

    test('manual toe-in does not affect triangle geometry metrics', () {
      const leftA = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(0.0, 0.0),
        toeInDegrees: 0,
      );
      const rightA = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(2.0, 0.0),
        toeInDegrees: 0,
      );
      final leftB = leftA.copyWith(toeInDegrees: 35);
      final rightB = rightA.copyWith(toeInDegrees: 35);
      const listener = ListeningPosition(
        position: RoomPosition(1.0, 1.732),
      );

      final a = calculator.calculate(
        leftSpeaker: leftA,
        rightSpeaker: rightA,
        listeningPosition: listener,
      );
      final b = calculator.calculate(
        leftSpeaker: leftB,
        rightSpeaker: rightB,
        listeningPosition: listener,
      );

      expect(a.triangleAccuracy, closeTo(b.triangleAccuracy, 0.0001));
      expect(a.speakerSpacing, closeTo(b.speakerSpacing, 0.0001));
      expect(a.leftDistance, closeTo(b.leftDistance, 0.0001));
      expect(a.rightDistance, closeTo(b.rightDistance, 0.0001));
    });

    test('feedback contains meaningful text', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(1.0, 1.0),
      );
      const right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(4.0, 1.0),
      );
      const listener = ListeningPosition(
        position: RoomPosition(2.5, 3.5),
      );

      final result = calculator.calculate(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(result.feedback, isNotEmpty);
    });
  });

  group('SweetSpotResult', () {
    test('averageListeningDistance is mean of left and right', () {
      const result = SweetSpotResult(
        leftDistance: 2.0,
        rightDistance: 3.0,
        speakerSpacing: 2.5,
        listeningDistance: 2.5,
        triangleAccuracy: 0.7,
        isOptimal: false,
        feedback: 'Test',
      );

      expect(result.averageListeningDistance, closeTo(2.5, 0.001));
    });
  });
}
