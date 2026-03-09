import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../acoustic/models/reflection_point.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../../room_design/models/editable_distance_target.dart';
import '../../room_design/models/room_state.dart';
import '../../room_design/models/speaker.dart';
import '../models/room_position.dart';

class MeasurementHitTarget {
  final Rect rect;
  final EditableDistanceTarget target;
  final double distanceMeters;

  const MeasurementHitTarget({
    required this.rect,
    required this.target,
    required this.distanceMeters,
  });
}

class _MeasurementLabelLayout {
  final String text;
  final Offset position;
  final TextStyle style;

  const _MeasurementLabelLayout({
    required this.text,
    required this.position,
    required this.style,
  });
}

class RoomPainter extends CustomPainter {
  final RoomState roomState;
  final SweetSpotResult sweetSpotResult;
  final List<ReflectionPoint> reflectionPoints;
  final RoomPosition recommendedAimingPoint;
  final double scale;
  final bool showGrid;
  final bool showReflections;
  final bool showTriangle;
  final bool showMeasurements;
  final int? hoveredBlockerId;

  const RoomPainter({
    required this.roomState,
    required this.sweetSpotResult,
    required this.reflectionPoints,
    required this.recommendedAimingPoint,
    required this.scale,
    this.showGrid = true,
    this.showReflections = true,
    this.showTriangle = true,
    this.showMeasurements = true,
    this.hoveredBlockerId,
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

    // 3. Draw blocked areas on top of the grid.
    _drawBlockedZones(canvas);

    // 4. Draw triangle
    if (showTriangle) {
      _drawStereoTriangle(canvas);
    }

    // 5. Draw reflection points
    if (showReflections) {
      _drawReflectionPoints(canvas);
    }

    // 6. Draw measurements (distances to walls)
    if (showMeasurements) {
      _drawMeasurements(canvas);
    }

    // 7. Draw speakers
    _drawSpeaker(canvas, roomState.leftSpeaker);
    _drawSpeaker(canvas, roomState.rightSpeaker);

    // 8. Draw listening position
    _drawListeningPosition(canvas);

    // 9. Draw recommended aiming position
    drawRecommendedAimingPoint(canvas, recommendedAimingPoint);

    // 10. Draw room border (on top for clean edges)
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
      'Focus→Left',
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
      'Focus→Right',
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
      'Focus→Front',
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
      'Focus→Back',
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

    final layout = _measurementLabelLayout(
      start,
      end,
      distanceM,
      label,
      _measurementLabelTextStyle(),
    );

    _drawText(
      canvas,
      layout.text,
      layout.position,
      layout.style,
      background: AppTheme.background.withAlpha(200),
    );
  }

  TextStyle _measurementLabelTextStyle() {
    return TextStyle(
      color: AppTheme.highlight.withAlpha(220),
      fontSize: 9,
      fontWeight: FontWeight.w600,
      fontFamily: 'monospace',
    );
  }

  _MeasurementLabelLayout _measurementLabelLayout(
    Offset start,
    Offset end,
    double distanceM,
    String label,
    TextStyle style,
  ) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    final distLabel = distanceM >= 1
        ? '${distanceM.toStringAsFixed(2)}m'
        : '${(distanceM * 100).toStringAsFixed(0)}cm';

    return _MeasurementLabelLayout(
      text: '$label: $distLabel',
      position: Offset(midX - 20, midY - 10),
      style: style,
    );
  }

  MeasurementHitTarget _buildMeasurementHitTarget({
    required Offset start,
    required Offset end,
    required double distanceM,
    required String label,
    required TextStyle style,
    required EditableDistanceTarget target,
  }) {
    final layout = _measurementLabelLayout(start, end, distanceM, label, style);
    final rect =
        _textBackgroundRect(layout.text, layout.position, layout.style);

    return MeasurementHitTarget(
      rect: rect,
      target: target,
      distanceMeters: distanceM,
    );
  }

  Rect _textBackgroundRect(String text, Offset position, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return Rect.fromLTWH(
      position.dx - 2,
      position.dy - 1,
      textPainter.width + 4,
      textPainter.height + 2,
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
    // Draw aiming ray for each speaker
    _drawSpeakerAimingRay(canvas, roomState.leftSpeaker, AppTheme.leftSpeaker);
    _drawSpeakerAimingRay(
        canvas, roomState.rightSpeaker, AppTheme.rightSpeaker);
  }

  void _drawSpeakerAimingRay(Canvas canvas, Speaker speaker, Color color) {
    final speakerPt = Offset(
      speaker.position.x * scale,
      speaker.position.y * scale,
    );

    // Get forward direction based on toe-in
    final forward = _speakerForwardAxis(speaker);

    final rayEndMeters = _computeRayEndpointOnRoomBounds(
      speaker.position.x,
      speaker.position.y,
      forward.$1,
      forward.$2,
    );

    final rayEndPt = Offset(
      rayEndMeters.$1 * scale,
      rayEndMeters.$2 * scale,
    );

    // Draw smooth ray line
    final rayPaint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawLine(speakerPt, rayEndPt, rayPaint);

    // Draw direction indicator at ray end
    const arrowSize = 6.0;
    final arrowPaint = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Calculate perpendicular direction for arrow
    final perpX = -forward.$2;
    final perpY = forward.$1;

    final arrowPoint1 = Offset(
      rayEndPt.dx - forward.$1 * arrowSize - perpX * arrowSize * 0.5,
      rayEndPt.dy - forward.$2 * arrowSize - perpY * arrowSize * 0.5,
    );
    final arrowPoint2 = Offset(
      rayEndPt.dx - forward.$1 * arrowSize + perpX * arrowSize * 0.5,
      rayEndPt.dy - forward.$2 * arrowSize + perpY * arrowSize * 0.5,
    );

    canvas.drawCircle(rayEndPt, 3.0, arrowPaint);
    canvas.drawLine(arrowPoint1, rayEndPt, rayPaint);
    canvas.drawLine(arrowPoint2, rayEndPt, rayPaint);
  }

  (double, double) _computeRayEndpointOnRoomBounds(
    double startX,
    double startY,
    double dirX,
    double dirY,
  ) {
    final roomW = roomState.room.widthMeters;
    final roomH = roomState.room.lengthMeters;

    const eps = 1e-9;
    var bestT = double.infinity;
    var bestX = startX;
    var bestY = startY;

    void tryHit(double t) {
      if (t < 0 || !t.isFinite) return;

      final hitX = startX + dirX * t;
      final hitY = startY + dirY * t;

      final insideX = hitX >= -eps && hitX <= roomW + eps;
      final insideY = hitY >= -eps && hitY <= roomH + eps;
      if (!insideX || !insideY) return;

      if (t < bestT) {
        bestT = t;
        bestX = hitX.clamp(0.0, roomW).toDouble();
        bestY = hitY.clamp(0.0, roomH).toDouble();
      }
    }

    if (dirX.abs() > eps) {
      tryHit((0.0 - startX) / dirX);
      tryHit((roomW - startX) / dirX);
    }

    if (dirY.abs() > eps) {
      tryHit((0.0 - startY) / dirY);
      tryHit((roomH - startY) / dirY);
    }

    return (bestX, bestY);
  }

  (double, double) _speakerForwardAxis(Speaker speaker) {
    final toeInRad = speaker.toeInDegrees * math.pi / 180;
    final xSign = speaker.channel == SpeakerChannel.left ? 1.0 : -1.0;
    final fx = math.sin(toeInRad) * xSign;
    final fy = math.cos(toeInRad);
    final len = math.sqrt(fx * fx + fy * fy);
    if (len < 1e-9) return (0.0, 1.0);
    return (fx / len, fy / len);
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

    // Draw toe-in direction indicator
    final toeInRadians = (speaker.toeInDegrees * math.pi / 180);
    final isLeftSpeaker = speaker.channel == SpeakerChannel.left;
    final directionAngle = isLeftSpeaker ? toeInRadians : -toeInRadians;
    const arrowLength = 16.0;
    final arrowEndX = offset.dx + arrowLength * math.sin(directionAngle);
    final arrowEndY = offset.dy + arrowLength * math.cos(directionAngle);

    final arrowPaint = Paint()
      ..color = color.withAlpha(220)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(offset, Offset(arrowEndX, arrowEndY), arrowPaint);

    // Draw arrowhead
    const arrowSize = 3.0;
    final angle1 = directionAngle + (math.pi * 0.3);
    final angle2 = directionAngle - (math.pi * 0.3);
    final arrowTip1 = Offset(
      arrowEndX - arrowSize * math.sin(angle1),
      arrowEndY - arrowSize * math.cos(angle1),
    );
    final arrowTip2 = Offset(
      arrowEndX - arrowSize * math.sin(angle2),
      arrowEndY - arrowSize * math.cos(angle2),
    );

    canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowTip1, arrowPaint);
    canvas.drawLine(Offset(arrowEndX, arrowEndY), arrowTip2, arrowPaint);

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

    // Position and toe-in label below speaker
    final posLabel =
        '(${pos.x.toStringAsFixed(1)}, ${pos.y.toStringAsFixed(1)}) • ${speaker.toeInDegrees.toStringAsFixed(0)}°';
    _drawText(
      canvas,
      posLabel,
      Offset(offset.dx - 28, offset.dy + 16),
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

    final glowPaint = Paint()
      ..color = color.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(offset, 20, glowPaint);

    final ringPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(offset, 18, ringPaint);

    final bodyPaint = Paint()
      ..color = color.withAlpha(180)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(offset.dx, offset.dy - 10);
    path.lineTo(offset.dx - 8, offset.dy + 6);
    path.lineTo(offset.dx + 8, offset.dy + 6);
    path.close();
    canvas.drawPath(path, bodyPaint);

    _drawText(
      canvas,
      'Focus',
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

  void drawRecommendedAimingPoint(Canvas canvas, RoomPosition aimingPoint) {
    final offset = Offset(aimingPoint.x * scale, aimingPoint.y * scale);
    const color = AppTheme.highlight;

    // Outer glow ring
    final glowPaint = Paint()
      ..color = color.withAlpha(30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(offset, 14, glowPaint);

    // Crosshair marker
    final crosshairPaint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const crosshairSize = 10.0;
    // Horizontal line
    canvas.drawLine(
      Offset(offset.dx - crosshairSize, offset.dy),
      Offset(offset.dx + crosshairSize, offset.dy),
      crosshairPaint,
    );
    // Vertical line
    canvas.drawLine(
      Offset(offset.dx, offset.dy - crosshairSize),
      Offset(offset.dx, offset.dy + crosshairSize),
      crosshairPaint,
    );

    // Center dot
    final centerPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 3, centerPaint);

    // Label
    _drawText(
      canvas,
      'Aim',
      Offset(offset.dx - 10, offset.dy + 12),
      TextStyle(
        color: color.withAlpha(220),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
      ),
      background: AppTheme.background.withAlpha(200),
    );
  }

  void _drawBlockedZones(Canvas canvas) {
    if (roomState.blockerZones.isEmpty) return;

    final fillPaint = Paint()
      ..color = AppTheme.sweetSpotRed.withAlpha(50)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppTheme.sweetSpotRed.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final hatchPaint = Paint()
      ..color = AppTheme.sweetSpotRed.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final blocker in roomState.blockerZones) {
      final isHovered = blocker.id == hoveredBlockerId;
      final rect = Rect.fromLTWH(
        blocker.x * scale,
        blocker.y * scale,
        blocker.width * scale,
        blocker.height * scale,
      );

      canvas.drawRect(rect, fillPaint);

      canvas.save();
      canvas.clipRect(rect);
      const spacing = 12.0;
      var x = rect.left - rect.height;
      while (x < rect.right) {
        canvas.drawLine(
          Offset(x, rect.top),
          Offset(x + rect.height, rect.bottom),
          hatchPaint,
        );
        x += spacing;
      }
      canvas.restore();

      canvas.drawRect(
        rect,
        isHovered
            ? (Paint()
              ..color = AppTheme.accent.withAlpha(220)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0)
            : borderPaint,
      );

      if (isHovered) {
        _drawText(
          canvas,
          'B${blocker.id}',
          Offset(rect.left + 4, rect.top + 3),
          const TextStyle(
            color: AppTheme.accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
          background: AppTheme.background.withAlpha(190),
        );
      }
    }
  }

  @override
  bool shouldRepaint(RoomPainter oldDelegate) {
    return oldDelegate.roomState != roomState ||
        oldDelegate.sweetSpotResult != sweetSpotResult ||
        oldDelegate.reflectionPoints != reflectionPoints ||
        oldDelegate.recommendedAimingPoint != recommendedAimingPoint ||
        oldDelegate.scale != scale ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showReflections != showReflections ||
        oldDelegate.showTriangle != showTriangle ||
        oldDelegate.showMeasurements != showMeasurements ||
        oldDelegate.hoveredBlockerId != hoveredBlockerId;
  }

  List<MeasurementHitTarget> measurementHitTargets() {
    if (!showMeasurements) return const [];

    final room = roomState.room;
    final lpPos = roomState.listeningPosition.position;
    final lSpeakerPos = roomState.leftSpeaker.position;
    final rSpeakerPos = roomState.rightSpeaker.position;
    final textStyle = _measurementLabelTextStyle();

    return [
      _buildMeasurementHitTarget(
        start: Offset(lpPos.x * scale, lpPos.y * scale),
        end: Offset(0, lpPos.y * scale),
        distanceM: lpPos.x,
        label: 'Focus→Left',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.focus,
          wall: RoomWall.left,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(lpPos.x * scale, lpPos.y * scale),
        end: Offset(room.widthMeters * scale, lpPos.y * scale),
        distanceM: room.widthMeters - lpPos.x,
        label: 'Focus→Right',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.focus,
          wall: RoomWall.right,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(lpPos.x * scale, lpPos.y * scale),
        end: Offset(lpPos.x * scale, 0),
        distanceM: lpPos.y,
        label: 'Focus→Front',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.focus,
          wall: RoomWall.front,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(lpPos.x * scale, lpPos.y * scale),
        end: Offset(lpPos.x * scale, room.lengthMeters * scale),
        distanceM: room.lengthMeters - lpPos.y,
        label: 'Focus→Back',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.focus,
          wall: RoomWall.back,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(lSpeakerPos.x * scale, lSpeakerPos.y * scale),
        end: Offset(0, lSpeakerPos.y * scale),
        distanceM: lSpeakerPos.x,
        label: 'L→Left',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.leftSpeaker,
          wall: RoomWall.left,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(lSpeakerPos.x * scale, lSpeakerPos.y * scale),
        end: Offset(lSpeakerPos.x * scale, 0),
        distanceM: lSpeakerPos.y,
        label: 'L→Front',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.leftSpeaker,
          wall: RoomWall.front,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(rSpeakerPos.x * scale, rSpeakerPos.y * scale),
        end: Offset(room.widthMeters * scale, rSpeakerPos.y * scale),
        distanceM: room.widthMeters - rSpeakerPos.x,
        label: 'R→Right',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.rightSpeaker,
          wall: RoomWall.right,
        ),
      ),
      _buildMeasurementHitTarget(
        start: Offset(rSpeakerPos.x * scale, rSpeakerPos.y * scale),
        end: Offset(rSpeakerPos.x * scale, 0),
        distanceM: rSpeakerPos.y,
        label: 'R→Front',
        style: textStyle,
        target: const EditableDistanceTarget(
          entity: MeasuredEntity.rightSpeaker,
          wall: RoomWall.front,
        ),
      ),
    ];
  }
}
