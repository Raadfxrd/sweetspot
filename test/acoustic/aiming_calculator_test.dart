import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/services/aiming_calculator.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';

void main() {
  const calculator = AimingCalculator();

  group('AimingCalculator', () {
    test('recommended aiming point is 1.5m behind listening position', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(1.0, 1.0),
      );
      const right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(3.0, 1.0),
      );
      const listener = ListeningPosition(
        position: RoomPosition(2.0, 3.0),
      );

      final aimingPoint = calculator.calculateRecommendedAimingPoint(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(aimingPoint.x, closeTo(2.0, 0.01));
      expect(aimingPoint.y, closeTo(4.5, 0.01));
    });

    test('calculates required toe-in for left speaker', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(1.0, 1.0),
      );
      const targetPoint = RoomPosition(2.0, 3.0);

      final toeIn = calculator.calculateRequiredToeIn(
        speaker: left,
        targetPoint: targetPoint,
      );

      final expected = math.atan2(1, 2) * 180 / math.pi;
      expect(toeIn, closeTo(expected, 0.1));
    });

    test('calculates required toe-in for right speaker', () {
      const right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(3.0, 1.0),
      );
      const targetPoint = RoomPosition(2.0, 3.0);

      final toeIn = calculator.calculateRequiredToeIn(
        speaker: right,
        targetPoint: targetPoint,
      );

      final expected = math.atan2(-1, 2) * 180 / math.pi;
      expect(toeIn, closeTo(-expected, 0.1));
    });

    test('clamps toe-in to 0-45 degree range', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(2.0, 5.0),
      );
      const targetPoint = RoomPosition(5.0, 4.0);

      final toeIn = calculator.calculateRequiredToeIn(
        speaker: left,
        targetPoint: targetPoint,
      );

      expect(toeIn, greaterThanOrEqualTo(0.0));
      expect(toeIn, lessThanOrEqualTo(45.0));
    });

    test('returns zero toe-in when target directly in front', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(1.0, 1.0),
      );
      const targetPoint = RoomPosition(1.0, 5.0);

      final toeIn = calculator.calculateRequiredToeIn(
        speaker: left,
        targetPoint: targetPoint,
      );

      expect(toeIn, closeTo(0.0, 0.1));
    });

    test('handles asymmetric speaker placement', () {
      const left = Speaker(
        channel: SpeakerChannel.left,
        position: RoomPosition(0.5, 1.0),
      );
      const right = Speaker(
        channel: SpeakerChannel.right,
        position: RoomPosition(4.5, 1.0),
      );
      const listener = ListeningPosition(
        position: RoomPosition(2.5, 4.0),
      );

      final aimingPoint = calculator.calculateRecommendedAimingPoint(
        leftSpeaker: left,
        rightSpeaker: right,
        listeningPosition: listener,
      );

      expect(aimingPoint.x, closeTo(2.5, 0.01));
      expect(aimingPoint.y, closeTo(5.5, 0.01));
    });
  });
}
