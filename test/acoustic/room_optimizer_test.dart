import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/services/room_optimizer.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_blocker_zone.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/room_state.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';

void main() {
  group('RoomOptimizer', () {
    test('keeps optimized layout outside blocker zones', () {
      const state = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(1.6, 1.2),
          toeInDegrees: 0,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(3.4, 1.2),
          toeInDegrees: 0,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 3.5)),
        blockerZones: [
          RoomBlockerZone(
            id: 1,
            x: 2.1,
            y: 3.0,
            width: 0.8,
            height: 0.9,
          ),
        ],
      );

      const optimizer = RoomOptimizer();
      final result = optimizer.optimize(state);

      final zone = state.blockerZones.first;
      expect(
          zone.contains(result.optimizedState.leftSpeaker.position), isFalse);
      expect(
          zone.contains(result.optimizedState.rightSpeaker.position), isFalse);
      expect(
        zone.contains(result.optimizedState.listeningPosition.position),
        isFalse,
      );

      expect(result.optimizedState.leftSpeaker.position.x,
          greaterThanOrEqualTo(0.35));
      expect(
        result.optimizedState.rightSpeaker.position.x,
        lessThanOrEqualTo(state.room.widthMeters - 0.35),
      );
    });

    test('produces human-readable instructions for meaningful changes', () {
      const state = RoomState(
        room: Room(widthMeters: 5, lengthMeters: 6),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(1.0, 1.8),
          toeInDegrees: 0,
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(4.0, 1.8),
          toeInDegrees: 0,
        ),
        listeningPosition: ListeningPosition(position: RoomPosition(2.5, 5.0)),
      );

      const optimizer = RoomOptimizer();
      final result = optimizer.optimize(state);

      if (result.hasMeaningfulImprovement) {
        expect(result.instructions, isNotEmpty);
        expect(
          result.instructions
              .where((i) => i.text.toLowerCase().contains('toe-in')),
          isEmpty,
        );
      }
    });
  });
}
