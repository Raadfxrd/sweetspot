import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/room_provider.dart';
import '../models/room_position.dart';
import '../models/room_state.dart';
import '../painters/room_painter.dart';
import '../../../core/theme/app_theme.dart';

class RoomCanvas extends ConsumerStatefulWidget {
  const RoomCanvas({super.key});

  @override
  ConsumerState<RoomCanvas> createState() => _RoomCanvasState();
}

class _RoomCanvasState extends ConsumerState<RoomCanvas> {
  _DragTarget? _activeDrag;
  double _scale = 80.0; // pixels per meter (default)
  bool _showGrid = true;
  bool _showReflections = true;
  bool _showHeatmap = true;
  bool _showTriangle = true;

  static const double _hitRadius = 20.0; // px hit detection radius

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final sweetSpotResult = ref.watch(sweetSpotResultProvider);
    final reflections = ref.watch(reflectionPointsProvider);

    final room = roomState.room;
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
                  onPanStart: (details) =>
                      _onPanStart(details, roomState, canvasWidth, canvasHeight),
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
                        showHeatmap: _showHeatmap,
                        showTriangle: _showTriangle,
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
              icon: Icons.blur_on,
              label: 'Heatmap',
              active: _showHeatmap,
              onTap: () => setState(() => _showHeatmap = !_showHeatmap),
            ),
            const SizedBox(width: 8),
            _ToolbarButton(
              icon: Icons.waves,
              label: 'Reflections',
              active: _showReflections,
              onTap: () =>
                  setState(() => _showReflections = !_showReflections),
            ),
            const SizedBox(width: 16),
            const _Divider(),
            const SizedBox(width: 16),
            _ZoomButton(
              icon: Icons.zoom_in,
              onTap: () => setState(
                  () => _scale = (_scale * 1.2).clamp(30.0, 200.0)),
            ),
            const SizedBox(width: 4),
            _ZoomButton(
              icon: Icons.zoom_out,
              onTap: () => setState(
                  () => _scale = (_scale / 1.2).clamp(30.0, 200.0)),
            ),
            const SizedBox(width: 16),
            _ZoomButton(
              icon: Icons.center_focus_strong,
              onTap: () => ref.read(roomProvider.notifier).autoPlaceSpeakers(),
            ),
            const SizedBox(width: 4),
            _ZoomButton(
              icon: Icons.auto_awesome,
              onTap: () => ref
                  .read(roomProvider.notifier)
                  .suggestOptimalListeningPosition(),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(
    DragStartDetails details,
    RoomState roomState,
    double canvasWidth,
    double canvasHeight,
  ) {
    final localPos = details.localPosition;

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

    final localPos = details.localPosition;
    final roomPos = RoomPosition(
      localPos.dx / _scale,
      localPos.dy / _scale,
    );

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
          color: active
              ? AppTheme.highlight.withAlpha(30)
              : Colors.transparent,
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

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(80),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: AppTheme.textSecondary.withAlpha(80), width: 0.5),
        ),
        child: Icon(icon, size: 16, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppTheme.gridLine,
    );
  }
}
