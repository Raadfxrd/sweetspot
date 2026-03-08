import 'listening_position.dart';
import 'room.dart';
import 'speaker.dart';

class RoomState {
  final Room room;
  final Speaker leftSpeaker;
  final Speaker rightSpeaker;
  final ListeningPosition listeningPosition;

  const RoomState({
    required this.room,
    required this.leftSpeaker,
    required this.rightSpeaker,
    required this.listeningPosition,
  });

  RoomState copyWith({
    Room? room,
    Speaker? leftSpeaker,
    Speaker? rightSpeaker,
    ListeningPosition? listeningPosition,
  }) {
    return RoomState(
      room: room ?? this.room,
      leftSpeaker: leftSpeaker ?? this.leftSpeaker,
      rightSpeaker: rightSpeaker ?? this.rightSpeaker,
      listeningPosition: listeningPosition ?? this.listeningPosition,
    );
  }
}
