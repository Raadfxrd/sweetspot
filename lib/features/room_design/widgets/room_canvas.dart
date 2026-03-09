import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/editable_distance_target.dart';
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
  bool _drawBlockersMode = false;

  Offset? _blockerStartPx;
  Offset? _blockerCurrentPx;
  int? _activeBlockerDragId;
  Offset? _activeBlockerDragStartPx;
  RoomPosition? _activeBlockerOriginalTopLeft;

  static const double _hitRadius = 20.0;
  static const double _measurementHitPadding = 6.0;

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final sweetSpotResult = ref.watch(sweetSpotResultProvider);
    final reflections = ref.watch(reflectionPointsProvider);
    final recommendedAimingPoint = ref.watch(recommendedAimingPointProvider);
    final hoveredBlockerId = ref.watch(hoveredBlockerIdProvider);

    final room = roomState.room;

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Fill the available box, leaving a uniform padding inset.
              const padding = 24.0;
              final availableWidth = constraints.maxWidth - padding * 2;
              final availableHeight = constraints.maxHeight - padding * 2;

              final scaleX = availableWidth / room.widthMeters;
              final scaleY = availableHeight / room.lengthMeters;
              final scale = math.min(scaleX, scaleY);

              final canvasWidth = room.widthMeters * scale;
              final canvasHeight = room.lengthMeters * scale;

              final roomPainter = RoomPainter(
                roomState: roomState,
                sweetSpotResult: sweetSpotResult,
                reflectionPoints: reflections,
                recommendedAimingPoint: recommendedAimingPoint,
                scale: scale,
                showGrid: _showGrid,
                showReflections: _showReflections,
                showTriangle: _showTriangle,
                showMeasurements: _showMeasurements,
                hoveredBlockerId: hoveredBlockerId,
              );

              return Container(
                color: AppTheme.background,
                child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Padding(
                    padding: const EdgeInsets.all(padding),
                    child: Center(
                      child: MouseRegion(
                        onHover: (event) => _onCanvasHover(
                          event.localPosition,
                          roomState,
                          canvasWidth,
                        ),
                        onExit: (_) {
                          if (_activeBlockerDragId == null) {
                            ref.read(hoveredBlockerIdProvider.notifier).state =
                                null;
                          }
                        },
                        child: GestureDetector(
                          onTapUp: (details) =>
                              _onTapUp(details, roomState, roomPainter),
                          onPanStart: (details) {
                            if (_drawBlockersMode) {
                              _onBlockerPanStart(
                                details,
                                roomState,
                                canvasWidth,
                                canvasHeight,
                              );
                              return;
                            }
                            _onPanStart(
                              details,
                              roomState,
                              canvasWidth,
                              canvasHeight,
                            );
                          },
                          onPanUpdate: (details) {
                            if (_drawBlockersMode) {
                              _onBlockerPanUpdate(
                                details,
                                roomState,
                                canvasWidth,
                                canvasHeight,
                              );
                              return;
                            }
                            _onPanUpdate(details, canvasWidth, canvasHeight);
                          },
                          onPanEnd: (_) {
                            if (_drawBlockersMode) {
                              _onBlockerPanEnd(
                                  roomState, canvasWidth, canvasHeight);
                              return;
                            }
                            _onPanEnd();
                          },
                          child: SizedBox(
                            width: canvasWidth,
                            height: canvasHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                    child: CustomPaint(painter: roomPainter)),
                                if (_blockerPreviewRect != null)
                                  Positioned.fromRect(
                                    rect: _blockerPreviewRect!,
                                    child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.sweetSpotRed
                                              .withAlpha(45),
                                          border: Border.all(
                                            color: AppTheme.sweetSpotRed
                                                .withAlpha(170),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Rect? get _blockerPreviewRect {
    if (_activeBlockerDragId != null) return null;
    if (_blockerStartPx == null || _blockerCurrentPx == null) return null;
    return Rect.fromPoints(_blockerStartPx!, _blockerCurrentPx!);
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarToggle(
              icon: Icons.grid_4x4_rounded,
              label: 'Grid',
              active: _showGrid,
              onTap: () => setState(() => _showGrid = !_showGrid),
            ),
            const SizedBox(width: 4),
            _ToolbarToggle(
              icon: Icons.change_history_rounded,
              label: 'Triangle',
              active: _showTriangle,
              onTap: () => setState(() => _showTriangle = !_showTriangle),
            ),
            const SizedBox(width: 4),
            _ToolbarToggle(
              icon: Icons.spoke_rounded,
              label: 'Rays',
              active: _showReflections,
              onTap: () => setState(() => _showReflections = !_showReflections),
            ),
            const SizedBox(width: 4),
            _ToolbarToggle(
              icon: Icons.straighten_rounded,
              label: 'Measures',
              active: _showMeasurements,
              onTap: () =>
                  setState(() => _showMeasurements = !_showMeasurements),
            ),
            const SizedBox(width: 4),
            _ToolbarToggle(
              icon: Icons.block_rounded,
              label: 'Blockers',
              active: _drawBlockersMode,
              onTap: () => setState(() {
                _drawBlockersMode = !_drawBlockersMode;
                if (!_drawBlockersMode) {
                  _blockerStartPx = null;
                  _blockerCurrentPx = null;
                }
              }),
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
    final scale = canvasWidth / roomState.room.widthMeters;

    final lPos = roomState.leftSpeaker.position;
    final rPos = roomState.rightSpeaker.position;
    final lpPos = roomState.listeningPosition.position;

    final lOffset = Offset(lPos.x * scale, lPos.y * scale);
    final rOffset = Offset(rPos.x * scale, rPos.y * scale);
    final lpOffset = Offset(lpPos.x * scale, lpPos.y * scale);

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
    final scale = canvasWidth / roomState.room.widthMeters;

    final localPos = details.localPosition;
    final roomPos = RoomPosition(localPos.dx / scale, localPos.dy / scale);

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

  void _onTapUp(
    TapUpDetails details,
    RoomState roomState,
    RoomPainter painter,
  ) {
    if (!_showMeasurements) return;

    final tapPos = details.localPosition;
    final hit = painter
        .measurementHitTargets()
        .where((target) =>
            target.rect.inflate(_measurementHitPadding).contains(tapPos))
        .fold<MeasurementHitTarget?>(
      null,
      (best, current) {
        if (best == null) return current;
        final bestDist = _distanceToRectCenter(tapPos, best.rect);
        final currentDist = _distanceToRectCenter(tapPos, current.rect);
        return currentDist < bestDist ? current : best;
      },
    );

    if (hit == null) return;
    _showMeasurementInputDialog(roomState, hit);
  }

  Future<void> _showMeasurementInputDialog(
    RoomState roomState,
    MeasurementHitTarget hit,
  ) async {
    final maxDistance = _maxDistanceForWall(roomState, hit.target.wall);
    final label = _distanceLabel(hit.target);
    final controller =
        TextEditingController(text: hit.distanceMeters.toStringAsFixed(2));

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set $label distance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Enter distance in meters (0.00 - ${maxDistance.toStringAsFixed(2)}).'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Distance (m)',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: (_) {
                  final parsed = double.tryParse(controller.text.trim());
                  Navigator.of(context).pop(parsed);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    if (value.isNaN || value.isInfinite || value < 0 || value > maxDistance) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Distance must be between 0 and ${maxDistance.toStringAsFixed(2)} m.',
          ),
        ),
      );
      return;
    }

    ref.read(roomProvider.notifier).setDistanceToWall(
          entity: hit.target.entity,
          wall: hit.target.wall,
          distanceMeters: value,
        );
  }

  String _distanceLabel(EditableDistanceTarget target) {
    final entity = switch (target.entity) {
      MeasuredEntity.focus => 'Focus',
      MeasuredEntity.leftSpeaker => 'Left speaker',
      MeasuredEntity.rightSpeaker => 'Right speaker',
    };

    final wall = switch (target.wall) {
      RoomWall.left => 'left wall',
      RoomWall.right => 'right wall',
      RoomWall.front => 'front wall',
      RoomWall.back => 'back wall',
    };

    return '$entity to $wall';
  }

  double _maxDistanceForWall(RoomState roomState, RoomWall wall) {
    switch (wall) {
      case RoomWall.left:
      case RoomWall.right:
        return roomState.room.widthMeters;
      case RoomWall.front:
      case RoomWall.back:
        return roomState.room.lengthMeters;
    }
  }

  double _distanceToRectCenter(Offset point, Rect rect) {
    return _distancePx(point, rect.center);
  }

  double _distancePx(Offset a, Offset b) {
    final dx = a.dx - b.dx;
    final dy = a.dy - b.dy;
    return math.sqrt(dx * dx + dy * dy);
  }

  void _onBlockerPanStart(
    DragStartDetails details,
    RoomState roomState,
    double canvasWidth,
    double canvasHeight,
  ) {
    final clamped =
        _clampToCanvas(details.localPosition, canvasWidth, canvasHeight);
    final scale = canvasWidth / roomState.room.widthMeters;
    final hitId = _blockerIdAt(clamped, roomState, scale);

    if (hitId != null) {
      final zone = roomState.blockerZones.firstWhere((z) => z.id == hitId);
      _activeBlockerDragId = hitId;
      _activeBlockerDragStartPx = clamped;
      _activeBlockerOriginalTopLeft = RoomPosition(zone.x, zone.y);
      ref.read(hoveredBlockerIdProvider.notifier).state = hitId;
      return;
    }

    setState(() {
      _blockerStartPx = clamped;
      _blockerCurrentPx = _blockerStartPx;
      _activeBlockerDragId = null;
      _activeBlockerDragStartPx = null;
      _activeBlockerOriginalTopLeft = null;
    });
  }

  void _onBlockerPanUpdate(
    DragUpdateDetails details,
    RoomState roomState,
    double canvasWidth,
    double canvasHeight,
  ) {
    final clamped =
        _clampToCanvas(details.localPosition, canvasWidth, canvasHeight);

    if (_activeBlockerDragId != null &&
        _activeBlockerDragStartPx != null &&
        _activeBlockerOriginalTopLeft != null) {
      final scale = canvasWidth / roomState.room.widthMeters;
      final dxMeters = (clamped.dx - _activeBlockerDragStartPx!.dx) / scale;
      final dyMeters = (clamped.dy - _activeBlockerDragStartPx!.dy) / scale;
      ref.read(roomProvider.notifier).moveBlockedZone(
            zoneId: _activeBlockerDragId!,
            topLeft: RoomPosition(
              _activeBlockerOriginalTopLeft!.x + dxMeters,
              _activeBlockerOriginalTopLeft!.y + dyMeters,
            ),
          );
      return;
    }

    if (_blockerStartPx == null) return;
    setState(() {
      _blockerCurrentPx = clamped;
    });
  }

  void _onBlockerPanEnd(
    RoomState roomState,
    double canvasWidth,
    double canvasHeight,
  ) {
    if (_activeBlockerDragId != null) {
      _activeBlockerDragId = null;
      _activeBlockerDragStartPx = null;
      _activeBlockerOriginalTopLeft = null;
      return;
    }

    final start = _blockerStartPx;
    final end = _blockerCurrentPx;

    if (start != null && end != null) {
      final scale = canvasWidth / roomState.room.widthMeters;
      ref.read(roomProvider.notifier).addBlockedZoneFromPoints(
            RoomPosition(start.dx / scale, start.dy / scale),
            RoomPosition(end.dx / scale, end.dy / scale),
          );
    }

    setState(() {
      _blockerStartPx = null;
      _blockerCurrentPx = null;
    });
  }

  void _onCanvasHover(
    Offset localPosition,
    RoomState roomState,
    double canvasWidth,
  ) {
    final scale = canvasWidth / roomState.room.widthMeters;
    final id = _blockerIdAt(localPosition, roomState, scale);
    if (ref.read(hoveredBlockerIdProvider) != id) {
      ref.read(hoveredBlockerIdProvider.notifier).state = id;
    }
  }

  int? _blockerIdAt(Offset localPosition, RoomState roomState, double scale) {
    final roomPos =
        RoomPosition(localPosition.dx / scale, localPosition.dy / scale);
    for (final zone in roomState.blockerZones.reversed) {
      if (zone.contains(roomPos)) {
        return zone.id;
      }
    }
    return null;
  }

  Offset _clampToCanvas(Offset pos, double canvasWidth, double canvasHeight) {
    return Offset(
      pos.dx.clamp(0.0, canvasWidth).toDouble(),
      pos.dy.clamp(0.0, canvasHeight).toDouble(),
    );
  }
}

enum _DragTarget { leftSpeaker, rightSpeaker, listeningPosition }

class _ToolbarToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? AppTheme.accent : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
