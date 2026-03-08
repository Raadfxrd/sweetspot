import 'room_position.dart';

enum SpeakerChannel { left, right }

class Speaker {
  final SpeakerChannel channel;
  final RoomPosition position;
  final double toeInDegrees;

  const Speaker({
    required this.channel,
    required this.position,
    this.toeInDegrees = 0,
  });

  Speaker copyWith({
    SpeakerChannel? channel,
    RoomPosition? position,
    double? toeInDegrees,
  }) {
    return Speaker(
      channel: channel ?? this.channel,
      position: position ?? this.position,
      toeInDegrees: toeInDegrees ?? this.toeInDegrees,
    );
  }

  String get label => channel == SpeakerChannel.left ? 'L' : 'R';

  @override
  String toString() => 'Speaker($label @ $position, toe-in: ${toeInDegrees}°)';
}
