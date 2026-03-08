enum MeasuredEntity { focus, leftSpeaker, rightSpeaker }

enum RoomWall { left, right, front, back }

class EditableDistanceTarget {
  final MeasuredEntity entity;
  final RoomWall wall;

  const EditableDistanceTarget({
    required this.entity,
    required this.wall,
  });
}
