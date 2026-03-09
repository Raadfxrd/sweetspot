import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/services/optimization_instruction_generator.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/room_state.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';

void main() {
  group('OptimizationInstructionGenerator', () {
    test('uses wall-aware and uniform speaker movement wording', () {
      const current = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.6, 1.2),
          toeInDegrees: 2,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.4, 1.2),
          toeInDegrees: 2,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
      );

      const optimized = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.8, 1.0),
          toeInDegrees: 5,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.2, 1.0),
          toeInDegrees: 5,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
      );

      const generator = OptimizationInstructionGenerator();
      final instructions =
          generator.generate(current: current, optimized: optimized);

      expect(instructions.first.text, contains('Move the left speaker'));
      expect(instructions.first.text, contains('away from the left wall'));
      expect(instructions.first.text, contains('and 20 cm forward'));
      expect(
        instructions.where((i) => i.text.toLowerCase().contains('toe-in')),
        isEmpty,
      );
    });

    test('skips lateral suggestion when move pushes speaker too close to wall',
        () {
      const current = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.5, 1.0),
          toeInDegrees: 0,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.0, 1.0),
          toeInDegrees: 0,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
      );

      const optimized = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.3, 1.0),
          toeInDegrees: 0,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.0, 1.0),
          toeInDegrees: 0,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
      );

      const generator = OptimizationInstructionGenerator();
      final instructions =
          generator.generate(current: current, optimized: optimized);

      expect(
        instructions.where((i) => i.text.startsWith('Move the left speaker')),
        isEmpty,
      );
    });

    test('prioritizes critical side-wall fixes before other moves', () {
      const current = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.15, 1.3),
          toeInDegrees: 0,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.2, 1.3),
          toeInDegrees: 0,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
      );

      const optimized = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(0.55, 1.3),
          toeInDegrees: 8,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.2, 1.3),
          toeInDegrees: 8,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.1, 3.0)),
      );

      const generator = OptimizationInstructionGenerator();
      final instructions =
          generator.generate(current: current, optimized: optimized);

      expect(instructions, isNotEmpty);
      expect(instructions.first.text, contains('Move the left speaker'));
      expect(instructions.first.text, contains('away from the left wall'));
    });
  });
}
