import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../acoustic/models/optimization_result.dart';
import '../../acoustic/models/sweet_spot_result.dart';
import '../models/room.dart';
import '../models/room_state.dart';
import '../providers/room_provider.dart';

class RoomSetupPanel extends ConsumerStatefulWidget {
  const RoomSetupPanel({super.key});

  @override
  ConsumerState<RoomSetupPanel> createState() => _RoomSetupPanelState();
}

class _RoomSetupPanelState extends ConsumerState<RoomSetupPanel> {
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  bool _initialized = false;
  Room? _lastSeenRoom;

  bool _expandRoom = true;
  bool _expandBlockers = true;
  bool _expandAnalysis = true;
  bool _expandToeIn = false;

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  void _syncControllersFromRoom(Room room) {
    _widthController.text = room.widthMeters.toStringAsFixed(1);
    _lengthController.text = room.lengthMeters.toStringAsFixed(1);
    _lastSeenRoom = room;
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    final sweetSpot = ref.watch(sweetSpotResultProvider);
    final optimization = ref.watch(optimizationResultProvider);
    final room = roomState.room;

    if (!_initialized) {
      _syncControllersFromRoom(room);
      _initialized = true;
    } else if (_lastSeenRoom != null &&
        (_lastSeenRoom!.widthMeters != room.widthMeters ||
            _lastSeenRoom!.lengthMeters != room.lengthMeters) &&
        _widthController.text ==
            _lastSeenRoom!.widthMeters.toStringAsFixed(1) &&
        _lengthController.text ==
            _lastSeenRoom!.lengthMeters.toStringAsFixed(1)) {
      _syncControllersFromRoom(room);
    }

    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          _buildHeader(sweetSpot, room),
          const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                _buildSection(
                  title: 'Room',
                  icon: Icons.crop_square_rounded,
                  expanded: _expandRoom,
                  onToggle: () => setState(() => _expandRoom = !_expandRoom),
                  child: _buildDimensionFields(room),
                ),
                const SizedBox(height: 8),
                _buildSection(
                  title: 'Blockers',
                  icon: Icons.block_rounded,
                  expanded: _expandBlockers,
                  onToggle: () =>
                      setState(() => _expandBlockers = !_expandBlockers),
                  child: _buildBlockersPanel(roomState),
                ),
                const SizedBox(height: 8),
                _buildSection(
                  title: 'Analysis',
                  icon: Icons.bar_chart_rounded,
                  expanded: _expandAnalysis,
                  onToggle: () =>
                      setState(() => _expandAnalysis = !_expandAnalysis),
                  child:
                      _buildSweetSpotPanel(sweetSpot, roomState, optimization),
                ),
                const SizedBox(height: 8),
                _buildSection(
                  title: 'Tuning',
                  icon: Icons.tune_rounded,
                  expanded: _expandToeIn,
                  onToggle: () => setState(() => _expandToeIn = !_expandToeIn),
                  child: _buildSpeakerToeIn(roomState),
                ),
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(SweetSpotResult result, Room room) {
    final accuracyPercent = (result.triangleAccuracy * 100).toInt();
    final accuracyColor = result.isOptimal
        ? AppTheme.sweetSpotGreen
        : result.triangleAccuracy >= 0.6
            ? AppTheme.sweetSpotYellow
            : AppTheme.sweetSpotRed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${room.widthMeters.toStringAsFixed(1)} × ${room.lengthMeters.toStringAsFixed(1)} m',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Area ${room.area.toStringAsFixed(1)} m²',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Quality badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accuracyColor.withAlpha(18),
              borderRadius: BorderRadius.circular(7),
              border:
                  Border.all(color: accuracyColor.withAlpha(80), width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  '$accuracyPercent%',
                  style: TextStyle(
                    color: accuracyColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Quality',
                  style: TextStyle(
                    color: accuracyColor.withAlpha(180),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(9),
              bottom: expanded ? Radius.zero : const Radius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDimensionFields(Room room) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _widthController,
                label: 'Width (m)',
                onChanged: (_) => _applyRoomDimensions(room),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField(
                controller: _lengthController,
                label: 'Length (m)',
                onChanged: (_) => _applyRoomDimensions(room),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required void Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  void _applyRoomDimensions(Room currentRoom) {
    final width = double.tryParse(_widthController.text);
    final length = double.tryParse(_lengthController.text);
    if (width != null && width > 0 && length != null && length > 0) {
      ref.read(roomProvider.notifier).updateRoom(
            currentRoom.copyWith(
              widthMeters: width.clamp(1.0, 30.0),
              lengthMeters: length.clamp(1.0, 30.0),
            ),
          );
    }
  }

  Widget _buildSweetSpotPanel(
    SweetSpotResult result,
    RoomState roomState,
    OptimizationResult optimization,
  ) {
    final accuracyPercent = (result.triangleAccuracy * 100).toInt();
    final accuracyColor = result.isOptimal
        ? AppTheme.sweetSpotGreen
        : result.triangleAccuracy >= 0.6
            ? AppTheme.sweetSpotYellow
            : AppTheme.sweetSpotRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQualityBar(accuracyPercent, accuracyColor),
        const SizedBox(height: 10),
        _buildInfoRow('Triangle accuracy', '$accuracyPercent%',
            valueColor: accuracyColor),
        _buildInfoRow(
            'Speaker spacing', '${result.speakerSpacing.toStringAsFixed(2)} m'),
        _buildInfoRow(
            'L distance', '${result.leftDistance.toStringAsFixed(2)} m',
            valueColor: AppTheme.leftSpeaker),
        _buildInfoRow(
            'R distance', '${result.rightDistance.toStringAsFixed(2)} m',
            valueColor: AppTheme.rightSpeaker),
        _buildInfoRow('Listening distance',
            '${result.listeningDistance.toStringAsFixed(2)} m'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: accuracyColor.withAlpha(12),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: accuracyColor.withAlpha(50), width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result.isOptimal
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 13,
                color: accuracyColor,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  result.feedback,
                  style: TextStyle(
                      color: accuracyColor, fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildOptimizationSummary(optimization),
      ],
    );
  }

  Widget _buildOptimizationSummary(OptimizationResult optimization) {
    final currentPercent =
        (optimization.currentScore.triangleAccuracy * 100).toStringAsFixed(0);
    final optimizedPercent =
        (optimization.optimizedScore.triangleAccuracy * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Optimizer guidance',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildInfoRow('Current score', '$currentPercent%'),
          _buildInfoRow('Optimized score', '$optimizedPercent%',
              valueColor: AppTheme.accent),
          const SizedBox(height: 6),
          if (!optimization.hasMeaningfulImprovement)
            const Text(
              'Current setup is already close to optimal for this room and blocker map.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            )
          else if (optimization.instructions.isEmpty)
            const Text(
              'A better score was found, but suggested changes are below the practical threshold.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            )
          else
            ...optimization.instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        size: 14,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        instruction.text,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockersPanel(RoomState roomState) {
    final blockers = roomState.blockerZones;
    final hoveredId = ref.watch(hoveredBlockerIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Use the map toolbar and drag in Blockers mode to add unavailable areas.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (blockers.isEmpty)
          const Text(
            'No blocked zones yet.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          )
        else
          ...blockers.map(
            (zone) {
              final isHovered = zone.id == hoveredId;
              return MouseRegion(
                onEnter: (_) =>
                    ref.read(hoveredBlockerIdProvider.notifier).state = zone.id,
                onExit: (_) {
                  if (ref.read(hoveredBlockerIdProvider) == zone.id) {
                    ref.read(hoveredBlockerIdProvider.notifier).state = null;
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? AppTheme.accent.withAlpha(18)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isHovered ? AppTheme.accent : AppTheme.border,
                      width: isHovered ? 0.9 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'B${zone.id}  x:${zone.x.toStringAsFixed(2)}  y:${zone.y.toStringAsFixed(2)}  '
                          'w:${zone.width.toStringAsFixed(2)}  h:${zone.height.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isHovered
                                ? AppTheme.accent
                                : AppTheme.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight:
                                isHovered ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 14),
                        color: AppTheme.textSecondary,
                        tooltip: 'Remove blocker',
                        onPressed: () => ref
                            .read(roomProvider.notifier)
                            .removeBlockedZone(zone.id),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minHeight: 24, minWidth: 24),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (blockers.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(roomProvider.notifier).clearBlockedZones(),
              icon: const Icon(Icons.delete_outline_rounded, size: 14),
              label: const Text('Clear all'),
            ),
          ),
      ],
    );
  }

  Widget _buildQualityBar(int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Setup quality',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            Text(
              '$percent%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: AppTheme.primary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerToeIn(RoomState roomState) {
    final recommendedLeftToeIn = ref.watch(recommendedLeftToeInProvider);
    final recommendedRightToeIn = ref.watch(recommendedRightToeInProvider);
    final aimingPoint = ref.watch(recommendedAimingPointProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aiming point info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended aiming point',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'W: ${aimingPoint.x.toStringAsFixed(2)} m  ·  D: ${aimingPoint.y.toStringAsFixed(2)} m',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildToeInSlider(
          label: 'Left',
          currentToeIn: roomState.leftSpeaker.toeInDegrees,
          recommendedToeIn: recommendedLeftToeIn,
          onChanged: (v) =>
              ref.read(roomProvider.notifier).updateLeftSpeakerToeIn(v),
          color: AppTheme.leftSpeaker,
        ),
        const SizedBox(height: 14),
        _buildToeInSlider(
          label: 'Right',
          currentToeIn: roomState.rightSpeaker.toeInDegrees,
          recommendedToeIn: recommendedRightToeIn,
          onChanged: (v) =>
              ref.read(roomProvider.notifier).updateRightSpeakerToeIn(v),
          color: AppTheme.rightSpeaker,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () {
              ref
                  .read(roomProvider.notifier)
                  .updateLeftSpeakerToeIn(recommendedLeftToeIn);
              ref
                  .read(roomProvider.notifier)
                  .updateRightSpeakerToeIn(recommendedRightToeIn);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent.withAlpha(20),
              foregroundColor: AppTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            child: const Text('Apply recommended toe-in'),
          ),
        ),
      ],
    );
  }

  Widget _buildToeInSlider({
    required String label,
    required double currentToeIn,
    required double recommendedToeIn,
    required void Function(double) onChanged,
    required Color color,
  }) {
    final isNear = (currentToeIn - recommendedToeIn).abs() < 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  '$label speaker',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${currentToeIn.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isNear) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_circle_rounded,
                      size: 11, color: AppTheme.sweetSpotGreen),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Recommended  ${recommendedToeIn.toStringAsFixed(1)}°',
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace'),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: Colors.white,
            inactiveTrackColor: AppTheme.primary,
            overlayColor: color.withAlpha(30),
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
          ),
          child: Slider(
            value: currentToeIn.clamp(0.0, 45.0),
            min: 0.0,
            max: 45.0,
            divisions: 90,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11))),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(roomProvider.notifier).resetToDefaults(),
        child: const Text('Reset to defaults'),
      ),
    );
  }
}
