class Room {
  final double widthMeters;
  final double lengthMeters;
  final double heightMeters;

  const Room({
    required this.widthMeters,
    required this.lengthMeters,
    this.heightMeters = 2.4,
  });

  Room copyWith({
    double? widthMeters,
    double? lengthMeters,
    double? heightMeters,
  }) {
    return Room(
      widthMeters: widthMeters ?? this.widthMeters,
      lengthMeters: lengthMeters ?? this.lengthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
    );
  }

  double get area => widthMeters * lengthMeters;
  double get volume => widthMeters * lengthMeters * heightMeters;

  @override
  String toString() =>
      'Room(${widthMeters}m x ${lengthMeters}m x ${heightMeters}m)';
}
