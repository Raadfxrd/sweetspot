import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/room_position.dart';
import '../models/room_state.dart';
import '../painters/room_painter.dart';
import '../providers/room_provider.dart';

class RoomCanvas extends ConsumerStatefulWidget {
  const RoomCanvas({super.key});

  @override
  ConsumerState<RoomCanvas> createState() => _RoomCanvasState();
}

class _RoomCanvasState extends ConsumerState<RoomCanvas> {
  _DragTarget? _activeDrag;
  bool _showGrid = true;
  bool _showReflections = true;
  bool _showTriangle = true;
  bool _showMeasurements = true;

  static const double _hitRadius = 20.0; // px hit detection radius

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final sweetSpotResult = ref.watch(sweetSpotResultProvider);
    final reflections = ref.watch(reflectionPointsProvider);

    final room = roomState.room;

    // Auto-scale based on available space
    final _scale = _calculateAutoScale(context, room);

    final canvasWidth = room.widthMeters * _scale;
    final canvasHeight = room.lengthMeters * _scale;

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            color: AppTheme.background,
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.3,
              maxScale: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onPanStart: (details) => _onPanStart(
                    details,
                    roomState,
                    canvasWidth,
                    canvasHeight,
                  ),
                  onPanUpdate: (details) =>
                      _onPanUpdate(details, canvasWidth, canvasHeight),
                  onPanEnd: (_) => _onPanEnd(),
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: CustomPaint(
                      painter: RoomPainter(
                        roomState: roomState,
                        sweetSpotResult: sweetSpotResult,
                        reflectionPoints: reflections,
                        scale: _scale,
                        showGrid: _showGrid,
                        showReflections: _showReflections,
                        showTriangle: _showTriangle,
                        showMeasurements: _showMeasurements,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceVariant,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarButton(
              icon: Icons.grid_3x3,
              label: 'Grid',
              active: _showGrid,
              onTap: () => setState(() => _showGrid = !_showGrid),
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.change_history,
              label: 'Triangle',
              active: _showTriangle,
              onTap: () => setState(() => _showTriangle = !_showTriangle),
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.waves,
              label: 'Reflections',
              active: _showReflections,
              onTap: () => setState(() => _showReflections = !_showReflections),
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.straighten,
              label: 'Measurements',
              active: _showMeasurements,
              onTap: () =>
                  setState(() => _showMeasurements = !_showMeasurements),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAutoScale(BuildContext context, room) {
    // Calculate available space for the canvas
    final mediaQuery = MediaQuery.of(context);
    final availableWidth = mediaQuery.size.width > 800
        ? mediaQuery.size.width -
            260 -
            48 // Wide layout: subtract panel width and padding
        : mediaQuery.size.width - 48; // Narrow layout: just padding
    final availableHeight =
        mediaQuery.size.height - 200; // Subtract app bar and toolbar

    // Calculate scale to fit the room in available space
    final scaleX = availableWidth / room.widthMeters;
    final scaleY = availableHeight / room.lengthMeters;

    // Use the smaller scale to ensure room fits, with min/max constraints
    return math.min(scaleX, scaleY).clamp(40.0, 150.0);
  }

  void _onPanStart(
    DragStartDetails details,
    RoomState roomState,
    double canvasWidth,
    double canvasHeight,
  ) {
    final localPos = details.localPosition;
    final _scale = canvasWidth / roomState.room.widthMeters;

    final lPos = roomState.leftSpeaker.position;
    final rPos = roomState.rightSpeaker.position;
    final lpPos = roomState.listeningPosition.position;

    final lOffset = Offset(lPos.x * _scale, lPos.y * _scale);
    final rOffset = Offset(rPos.x * _scale, rPos.y * _scale);
    final lpOffset = Offset(lpPos.x * _scale, lpPos.y * _scale);

    if (_distancePx(localPos, lOffset) <= _hitRadius) {
      _activeDrag = _DragTarget.leftSpeaker;
    } else if (_distancePx(localPos, rOffset) <= _hitRadius) {
      _activeDrag = _DragTarget.rightSpeaker;
    } else if (_distancePx(localPos, lpOffset) <= _hitRadius) {
      _activeDrag = _DragTarget.listeningPosition;
    }
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (_activeDrag == null) return;

    final roomState = ref.read(roomProvider);
    final _scale = canvasWidth / roomState.room.widthMeters;

    final localPos = details.localPosition;
    final roomPos = RoomPosition(localPos.dx / _scale, localPos.dy / _scale);

    final notifier = ref.read(roomProvider.notifier);

    switch (_activeDrag!) {
      case _DragTarget.leftSpeaker:
        notifier.updateLeftSpeakerPosition(roomPos);
        break;
      case _DragTarget.rightSpeaker:
        notifier.updateRightSpeakerPosition(roomPos);
        break;
      case _DragTarget.listeningPosition:
        notifier.updateListeningPosition(roomPos);
        break;
    }
  }

  void _onPanEnd() {
    _activeDrag = null;
  }

  double _distancePx(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}

enum _DragTarget { leftSpeaker, rightSpeaker, listeningPosition }

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppTheme.highlight.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? AppTheme.highlight : AppTheme.textSecondary,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? AppTheme.highlight : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.highlight : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
