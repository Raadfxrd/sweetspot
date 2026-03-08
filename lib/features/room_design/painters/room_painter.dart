import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../acoustic/models/reflection_point.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../../room_design/models/room_state.dart';
import '../../room_design/models/speaker.dart';

class RoomPainter extends CustomPainter {
  final RoomState roomState;
  final SweetSpotResult sweetSpotResult;
  final List<ReflectionPoint> reflectionPoints;
  final double scale;
  final bool showGrid;
  final bool showReflections;
  final bool showTriangle;
  final bool showMeasurements;

  const RoomPainter({
    required this.roomState,
    required this.sweetSpotResult,
    required this.reflectionPoints,
    required this.scale,
    this.showGrid = true,
    this.showReflections = true,
    this.showTriangle = true,
    this.showMeasurements = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final room = roomState.room;
    final roomW = room.widthMeters * scale;
    final roomH = room.lengthMeters * scale;

    // 1. Draw room background
    _drawRoomBackground(canvas, roomW, roomH);

    // 2. Draw grid
    if (showGrid) {
      _drawGrid(canvas, room.widthMeters, room.lengthMeters, roomW, roomH);
    }

    // 3. Draw triangle
    if (showTriangle) {
      _drawStereoTriangle(canvas);
    }

    // 4. Draw reflection points
    if (showReflections) {
      _drawReflectionPoints(canvas);
    }

    // 5. Draw measurements (distances to walls)
    if (showMeasurements) {
      _drawMeasurements(canvas);
    }

    // 6. Draw speakers
    _drawSpeaker(canvas, roomState.leftSpeaker);
    _drawSpeaker(canvas, roomState.rightSpeaker);

    // 7. Draw listening position
    _drawListeningPosition(canvas);

    // 8. Draw room border (on top for clean edges)
    _drawRoomBorder(canvas, roomW, roomH);
  }

  void _drawRoomBackground(Canvas canvas, double roomW, double roomH) {
    final paint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, roomW, roomH), paint);
  }

  void _drawRoomBorder(Canvas canvas, double roomW, double roomH) {
    final paint = Paint()
      ..color = AppTheme.roomBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, roomW, roomH), paint);
  }

  void _drawGrid(
    Canvas canvas,
    double roomWidthM,
    double roomLengthM,
    double roomW,
    double roomH,
  ) {
    const gridSpacingM = 0.5; // 0.5m grid
    final gridPaint = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 0.5;

    final majorPaint = Paint()
      ..color = AppTheme.gridLine.withAlpha(120)
      ..strokeWidth = 1.0;

    // Vertical lines
    var x = 0.0;
    var xM = 0.0;
    while (xM <= roomWidthM) {
      final isMajor = (xM % 1.0).abs() < 0.01;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, roomH),
        isMajor ? majorPaint : gridPaint,
      );
      xM += gridSpacingM;
      x = xM * scale;
    }

    // Horizontal lines
    var y = 0.0;
    var yM = 0.0;
    while (yM <= roomLengthM) {
      final isMajor = (yM % 1.0).abs() < 0.01;
      canvas.drawLine(
        Offset(0, y),
        Offset(roomW, y),
        isMajor ? majorPaint : gridPaint,
      );
      yM += gridSpacingM;
      y = yM * scale;
    }

    // Draw dimension labels at 1m intervals
    _drawGridLabels(canvas, roomWidthM, roomLengthM, roomW, roomH);
  }

  void _drawGridLabels(
    Canvas canvas,
    double roomWidthM,
    double roomLengthM,
    double roomW,
    double roomH,
  ) {
    final textStyle = TextStyle(
      color: AppTheme.textSecondary.withAlpha(150),
      fontSize: 9,
      fontFamily: 'monospace',
    );

    for (var i = 1; i <= roomWidthM.floor(); i++) {
      _drawText(canvas, '${i}m', Offset(i * scale - 8, roomH + 4), textStyle);
    }

    for (var i = 1; i <= roomLengthM.floor(); i++) {
      _drawText(canvas, '${i}m', Offset(-20, i * scale - 6), textStyle);
    }
  }

  void _drawMeasurements(Canvas canvas) {
    final room = roomState.room;
    final lpPos = roomState.listeningPosition.position;
    final lSpeakerPos = roomState.leftSpeaker.position;
    final rSpeakerPos = roomState.rightSpeaker.position;

    final measurementPaint = Paint()
      ..color = AppTheme.highlight.withAlpha(100)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = AppTheme.highlight.withAlpha(80)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Listening position to walls
    final lpOffset = Offset(lpPos.x * scale, lpPos.y * scale);

    // Distance to left wall (x=0)
    final distToLeftWall = lpPos.x;
    _drawMeasurementLine(
      canvas,
      lpOffset,
      Offset(0, lpPos.y * scale),
      distToLeftWall,
      measurementPaint,
      dashPaint,
      'LP→Left',
    );

    // Distance to right wall (x=width)
    final distToRightWall = room.widthMeters - lpPos.x;
    _drawMeasurementLine(
      canvas,
      lpOffset,
      Offset(room.widthMeters * scale, lpPos.y * scale),
      distToRightWall,
      measurementPaint,
      dashPaint,
      'LP→Right',
    );

    // Distance to front wall (y=0)
    final distToFrontWall = lpPos.y;
    _drawMeasurementLine(
      canvas,
      lpOffset,
      Offset(lpPos.x * scale, 0),
      distToFrontWall,
      measurementPaint,
      dashPaint,
      'LP→Front',
    );

    // Distance to back wall (y=length)
    final distToBackWall = room.lengthMeters - lpPos.y;
    _drawMeasurementLine(
      canvas,
      lpOffset,
      Offset(lpPos.x * scale, room.lengthMeters * scale),
      distToBackWall,
      measurementPaint,
      dashPaint,
      'LP→Back',
    );

    // Left speaker to walls
    final lSpeakerOffset = Offset(lSpeakerPos.x * scale, lSpeakerPos.y * scale);

    // Left speaker to left wall
    final lSpeakerToLeftWall = lSpeakerPos.x;
    _drawMeasurementLine(
      canvas,
      lSpeakerOffset,
      Offset(0, lSpeakerPos.y * scale),
      lSpeakerToLeftWall,
      measurementPaint,
      dashPaint,
      'L→Left',
    );

    // Left speaker to front wall
    final lSpeakerToFrontWall = lSpeakerPos.y;
    _drawMeasurementLine(
      canvas,
      lSpeakerOffset,
      Offset(lSpeakerPos.x * scale, 0),
      lSpeakerToFrontWall,
      measurementPaint,
      dashPaint,
      'L→Front',
    );

    // Right speaker to walls
    final rSpeakerOffset = Offset(rSpeakerPos.x * scale, rSpeakerPos.y * scale);

    // Right speaker to right wall
    final rSpeakerToRightWall = room.widthMeters - rSpeakerPos.x;
    _drawMeasurementLine(
      canvas,
      rSpeakerOffset,
      Offset(room.widthMeters * scale, rSpeakerPos.y * scale),
      rSpeakerToRightWall,
      measurementPaint,
      dashPaint,
      'R→Right',
    );

    // Right speaker to front wall
    final rSpeakerToFrontWall = rSpeakerPos.y;
    _drawMeasurementLine(
      canvas,
      rSpeakerOffset,
      Offset(rSpeakerPos.x * scale, 0),
      rSpeakerToFrontWall,
      measurementPaint,
      dashPaint,
      'R→Front',
    );
  }

  void _drawMeasurementLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double distanceM,
    Paint linePaint,
    Paint dashPaint,
    String label,
  ) {
    // Draw dashed line
    _drawDashedLine(canvas, start, end, dashPaint);

    // Draw distance label
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    final distLabel = distanceM >= 1
        ? '${distanceM.toStringAsFixed(2)}m'
        : '${(distanceM * 100).toStringAsFixed(0)}cm';

    _drawText(
      canvas,
      '$label: $distLabel',
      Offset(midX - 20, midY - 10),
      TextStyle(
        color: AppTheme.highlight.withAlpha(220),
        fontSize: 9,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
      background: AppTheme.background.withAlpha(200),
    );
  }

  void _drawStereoTriangle(Canvas canvas) {
    final lPos = roomState.leftSpeaker.position;
    final rPos = roomState.rightSpeaker.position;
    final lpPos = roomState.listeningPosition.position;

    final lOffset = Offset(lPos.x * scale, lPos.y * scale);
    final rOffset = Offset(rPos.x * scale, rPos.y * scale);
    final lpOffset = Offset(lpPos.x * scale, lpPos.y * scale);

    final linePaint = Paint()
      ..color = AppTheme.triangleLine.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashed triangle lines
    _drawDashedLine(canvas, lOffset, rOffset, linePaint);
    _drawDashedLine(canvas, lOffset, lpOffset, linePaint);
    _drawDashedLine(canvas, rOffset, lpOffset, linePaint);

    // Draw distance labels on lines
    _drawDistanceLabel(
      canvas,
      lOffset,
      lpOffset,
      sweetSpotResult.leftDistance,
      AppTheme.leftSpeaker,
    );
    _drawDistanceLabel(
      canvas,
      rOffset,
      lpOffset,
      sweetSpotResult.rightDistance,
      AppTheme.rightSpeaker,
    );
    _drawDistanceLabel(
      canvas,
      lOffset,
      rOffset,
      sweetSpotResult.speakerSpacing,
      AppTheme.textSecondary,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;

    final ux = dx / length;
    final uy = dy / length;

    var traveled = 0.0;
    var drawing = true;

    while (traveled < length) {
      final segLen = drawing ? dashLength : gapLength;
      final nextTraveled = math.min(traveled + segLen, length);

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * traveled, start.dy + uy * traveled),
          Offset(start.dx + ux * nextTraveled, start.dy + uy * nextTraveled),
          paint,
        );
      }

      traveled = nextTraveled;
      drawing = !drawing;
    }
  }

  void _drawDistanceLabel(
    Canvas canvas,
    Offset start,
    Offset end,
    double distanceM,
    Color color,
  ) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    final label = distanceM >= 1
        ? '${distanceM.toStringAsFixed(2)}m'
        : '${(distanceM * 100).toStringAsFixed(0)}cm';

    _drawText(
      canvas,
      label,
      Offset(midX - 14, midY - 7),
      TextStyle(
        color: color.withAlpha(200),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
      background: AppTheme.background.withAlpha(180),
    );
  }

  void _drawReflectionPoints(Canvas canvas) {
    final paint = Paint()
      ..color = AppTheme.reflectionPoint
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = AppTheme.reflectionPoint.withAlpha(60)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Group by wall to avoid too many lines; draw one reflection per wall per speaker
    final drawn = <String>{};

    for (final rp in reflectionPoints) {
      final pt = Offset(rp.position.x * scale, rp.position.y * scale);
      final speakerPt = Offset(
        rp.speakerPosition.x * scale,
        rp.speakerPosition.y * scale,
      );
      final listenerPt = Offset(
        rp.listenerPosition.x * scale,
        rp.listenerPosition.y * scale,
      );

      final key =
          '${rp.wall.name}_${rp.speakerPosition.x.toStringAsFixed(2)}_${rp.speakerPosition.y.toStringAsFixed(2)}';
      if (drawn.contains(key)) continue;
      drawn.add(key);

      // Draw reflection path: speaker -> reflection point -> listener
      canvas.drawLine(speakerPt, pt, linePaint);
      canvas.drawLine(pt, listenerPt, linePaint);

      // Draw reflection point marker
      canvas.drawCircle(pt, 4, paint);

      // Draw a small X mark
      final crossPaint = Paint()
        ..color = AppTheme.reflectionPoint
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(pt.dx - 4, pt.dy - 4),
        Offset(pt.dx + 4, pt.dy + 4),
        crossPaint,
      );
      canvas.drawLine(
        Offset(pt.dx + 4, pt.dy - 4),
        Offset(pt.dx - 4, pt.dy + 4),
        crossPaint,
      );
    }
  }

  void _drawSpeaker(Canvas canvas, Speaker speaker) {
    final pos = speaker.position;
    final offset = Offset(pos.x * scale, pos.y * scale);
    final isLeft = speaker.channel == SpeakerChannel.left;
    final color = isLeft ? AppTheme.leftSpeaker : AppTheme.rightSpeaker;

    // Speaker glow
    final glowPaint = Paint()
      ..color = color.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(offset, 18, glowPaint);

    // Speaker body
    final bodyPaint = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 12, bodyPaint);

    // Speaker border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(offset, 12, borderPaint);

    // Speaker label
    _drawText(
      canvas,
      speaker.label,
      Offset(offset.dx - 5, offset.dy - 7),
      const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );

    // Position label below speaker
    final posLabel =
        '(${pos.x.toStringAsFixed(1)}, ${pos.y.toStringAsFixed(1)})';
    _drawText(
      canvas,
      posLabel,
      Offset(offset.dx - 22, offset.dy + 16),
      TextStyle(
        color: color.withAlpha(180),
        fontSize: 9,
        fontFamily: 'monospace',
      ),
    );
  }

  void _drawListeningPosition(Canvas canvas) {
    final pos = roomState.listeningPosition.position;
    final offset = Offset(pos.x * scale, pos.y * scale);
    const color = AppTheme.listeningPos;

    // Glow
    final glowPaint = Paint()
      ..color = color.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(offset, 20, glowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(offset, 18, ringPaint);

    // Body
    final bodyPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.fill;

    // Chair/ear icon (triangle pointing up)
    final path = Path();
    path.moveTo(offset.dx, offset.dy - 10);
    path.lineTo(offset.dx - 8, offset.dy + 6);
    path.lineTo(offset.dx + 8, offset.dy + 6);
    path.close();
    canvas.drawPath(path, bodyPaint);

    // LP label
    _drawText(
      canvas,
      'LP',
      Offset(offset.dx - 8, offset.dy + 10),
      const TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    Color? background,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    if (background != null) {
      final bgPaint = Paint()..color = background;
      canvas.drawRect(
        Rect.fromLTWH(
          position.dx - 2,
          position.dy - 1,
          textPainter.width + 4,
          textPainter.height + 2,
        ),
        bgPaint,
      );
    }

    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(RoomPainter oldDelegate) {
    return oldDelegate.roomState != roomState ||
        oldDelegate.scale != scale ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showReflections != showReflections ||
        oldDelegate.showTriangle != showTriangle ||
        oldDelegate.showMeasurements != showMeasurements;
  }
}
