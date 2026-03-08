import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/models/sweet_spot_result.dart';
import 'package:sweetspot/features/room_design/models/listening_position.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/models/room_state.dart';
import 'package:sweetspot/features/room_design/models/speaker.dart';
import 'package:sweetspot/features/room_design/painters/room_painter.dart';

void main() {
  group('RoomPainter shouldRepaint', () {
    test('repaints when recommended aiming point changes', () {
      const roomState = RoomState(
        room: Room(widthMeters: 5.0, lengthMeters: 6.0),
        leftSpeaker: Speaker(
          channel: SpeakerChannel.left,
          position: RoomPosition(1.7, 1.2),
        ),
        rightSpeaker: Speaker(
          channel: SpeakerChannel.right,
          position: RoomPosition(3.3, 1.2),
        ),
        listeningPosition: ListeningPosition(
          position: RoomPosition(2.5, 3.6),
        ),
      );

      const sweetSpotResult = SweetSpotResult(
        leftDistance: 2.6,
        rightDistance: 2.6,
        speakerSpacing: 1.6,
        listeningDistance: 2.6,
        triangleAccuracy: 1.0,
        isOptimal: true,
        feedback: 'ok',
      );

      const oldPainter = RoomPainter(
        roomState: roomState,
        sweetSpotResult: sweetSpotResult,
        reflectionPoints: [],
        recommendedAimingPoint: RoomPosition(2.5, 3.9),
        scale: 100,
      );

      const newPainter = RoomPainter(
        roomState: roomState,
        sweetSpotResult: sweetSpotResult,
        reflectionPoints: [],
        recommendedAimingPoint: RoomPosition(2.7, 4.0),
        scale: 100,
      );

      expect(newPainter.shouldRepaint(oldPainter), isTrue);
    });
  });
}
