class Room {
  final double widthMeters;
  final double lengthMeters;

  const Room({
    required this.widthMeters,
    required this.lengthMeters,
  });

  Room copyWith({
    double? widthMeters,
    double? lengthMeters,
  }) {
    return Room(
      widthMeters: widthMeters ?? this.widthMeters,
      lengthMeters: lengthMeters ?? this.lengthMeters,
    );
  }

  double get area => widthMeters * lengthMeters;

  @override
  String toString() => 'Room(${widthMeters}m x ${lengthMeters}m)';
}
