import 'room_position.dart';

class ListeningPosition {
  final RoomPosition position;

  const ListeningPosition({required this.position});

  ListeningPosition copyWith({RoomPosition? position}) {
    return ListeningPosition(position: position ?? this.position);
  }

  @override
  String toString() => 'ListeningPosition($position)';
}
