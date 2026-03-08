import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/room_design/models/editable_distance_target.dart';
import 'package:sweetspot/features/room_design/models/room.dart';
import 'package:sweetspot/features/room_design/models/room_position.dart';
import 'package:sweetspot/features/room_design/providers/room_provider.dart';

void main() {
  group('roomProvider toe-in defaults', () {
    test('starts both speakers at 0 degrees toe-in', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final roomState = container.read(roomProvider);

      expect(roomState.leftSpeaker.toeInDegrees, 0.0);
      expect(roomState.rightSpeaker.toeInDegrees, 0.0);
    });

    test('resetToDefaults restores 0 degree toe-in', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.updateLeftSpeakerToeIn(30);
      notifier.updateRightSpeakerToeIn(22);

      notifier.resetToDefaults();
      final roomState = container.read(roomProvider);

      expect(roomState.leftSpeaker.toeInDegrees, 0.0);
      expect(roomState.rightSpeaker.toeInDegrees, 0.0);
    });
  });

  group('setDistanceToWall', () {
    test('updates focus distance to left wall', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.setDistanceToWall(
        entity: MeasuredEntity.focus,
        wall: RoomWall.left,
        distanceMeters: 1.2,
      );

      final roomState = container.read(roomProvider);
      expect(roomState.listeningPosition.position.x, closeTo(1.2, 1e-9));
    });

    test('updates right speaker distance to front wall', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.setDistanceToWall(
        entity: MeasuredEntity.rightSpeaker,
        wall: RoomWall.front,
        distanceMeters: 2.1,
      );

      final roomState = container.read(roomProvider);
      expect(roomState.rightSpeaker.position.y, closeTo(2.1, 1e-9));
    });
  });

  group('recommended aiming point updates', () {
    test('recomputes after listening position wall measurement edit', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = container.read(recommendedAimingPointProvider);

      container.read(roomProvider.notifier).setDistanceToWall(
            entity: MeasuredEntity.focus,
            wall: RoomWall.back,
            distanceMeters: 1.0,
          );

      final after = container.read(recommendedAimingPointProvider);
      expect(after, isNot(equals(before)));
    });

    test('recomputes after room resize that clamps positions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.updateListeningPosition(const RoomPosition(4.8, 5.8));
      final before = container.read(recommendedAimingPointProvider);

      notifier.updateRoom(
        const Room(widthMeters: 3.2, lengthMeters: 4.0),
      );

      final after = container.read(recommendedAimingPointProvider);
      expect(after, isNot(equals(before)));
    });
  });
}
