import 'listening_position.dart';
import 'room.dart';
import 'room_blocker_zone.dart';
import 'speaker.dart';

class RoomState {
  final Room room;
  final Speaker leftSpeaker;
  final Speaker rightSpeaker;
  final ListeningPosition listeningPosition;
  final List<RoomBlockerZone> blockerZones;

  const RoomState({
    required this.room,
    required this.leftSpeaker,
    required this.rightSpeaker,
    required this.listeningPosition,
    this.blockerZones = const [],
  });

  RoomState copyWith({
    Room? room,
    Speaker? leftSpeaker,
    Speaker? rightSpeaker,
    ListeningPosition? listeningPosition,
    List<RoomBlockerZone>? blockerZones,
  }) {
    return RoomState(
      room: room ?? this.room,
      leftSpeaker: leftSpeaker ?? this.leftSpeaker,
      rightSpeaker: rightSpeaker ?? this.rightSpeaker,
      listeningPosition: listeningPosition ?? this.listeningPosition,
      blockerZones: blockerZones ?? this.blockerZones,
    );
  }
}
