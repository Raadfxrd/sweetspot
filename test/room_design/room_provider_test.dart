import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweetspot/features/acoustic/services/optimization_instruction_generator.dart';
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

  group('blocker zones', () {
    test('clamps blocker zone dimensions to room bounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.addBlockedZone(
        x: 4.8,
        y: 5.8,
        width: 1.2,
        height: 1.4,
      );

      final roomState = container.read(roomProvider);
      expect(roomState.blockerZones, hasLength(1));
      final zone = roomState.blockerZones.first;
      expect(zone.x, closeTo(4.8, 1e-9));
      expect(zone.y, closeTo(5.8, 1e-9));
      expect(zone.width, closeTo(0.2, 1e-9));
      expect(zone.height, closeTo(0.2, 1e-9));
    });

    test('prevents placing listening position inside a blocker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(roomProvider.notifier);
      notifier.addBlockedZone(x: 2.3, y: 3.4, width: 0.6, height: 0.6);

      final before = container.read(roomProvider).listeningPosition.position;
      notifier.updateListeningPosition(const RoomPosition(2.5, 3.6));

      final after = container.read(roomProvider).listeningPosition.position;
      expect(after, equals(before));
    });
  });

  group('instruction thresholds', () {
    test('ignores tiny optimization deltas', () {
      const generator = OptimizationInstructionGenerator();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final current = container.read(roomProvider);
      final optimized = current.copyWith(
        leftSpeaker: current.leftSpeaker.copyWith(
          position: const RoomPosition(1.68, 1.22),
          toeInDegrees: 0.6,
        ),
      );

      final instructions =
          generator.generate(current: current, optimized: optimized);

      expect(instructions, isEmpty);
    });
  });

  group('context-aware quality score', () {
    test('adding a nearby blocker reduces quality score', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = container.read(sweetSpotResultProvider).triangleAccuracy;

      container.read(roomProvider.notifier).addBlockedZone(
            x: 2.2,
            y: 3.3,
            width: 0.7,
            height: 0.7,
          );

      final after = container.read(sweetSpotResultProvider).triangleAccuracy;
      expect(after, lessThan(before));
    });

    test('speaker too close to side wall lowers quality score', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = container.read(sweetSpotResultProvider).triangleAccuracy;

      container
          .read(roomProvider.notifier)
          .updateLeftSpeakerPosition(const RoomPosition(0.12, 1.2));

      final after = container.read(sweetSpotResultProvider).triangleAccuracy;
      expect(after, lessThan(before));
    });
  });
}
