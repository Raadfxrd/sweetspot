import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Header
            _buildQuickStats(sweetSpot, room),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.gridLine, height: 1),
            const SizedBox(height: 16),

            // Collapsible Sections
            _buildCollapsibleSection(
              title: 'Room Setup',
              expanded: _expandRoom,
              onToggle: () => setState(() => _expandRoom = !_expandRoom),
              icon: Icons.room_preferences,
              child: _buildDimensionFields(room),
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              title: 'Analysis',
              expanded: _expandAnalysis,
              onToggle: () =>
                  setState(() => _expandAnalysis = !_expandAnalysis),
              icon: Icons.analytics,
              child: _buildSweetSpotPanel(sweetSpot, roomState),
            ),
            const SizedBox(height: 12),
            _buildCollapsibleSection(
              title: 'Tuning',
              expanded: _expandToeIn,
              onToggle: () => setState(() => _expandToeIn = !_expandToeIn),
              icon: Icons.tune,
              child: _buildSpeakerToeIn(roomState),
            ),
            const SizedBox(height: 12),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(SweetSpotResult result, Room room) {
    final accuracyPercent = (result.triangleAccuracy * 100).toInt();
    final accuracyColor = result.isOptimal
        ? AppTheme.sweetSpotGreen
        : result.triangleAccuracy >= 0.6
            ? AppTheme.sweetSpotYellow
            : AppTheme.sweetSpotRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${room.widthMeters.toStringAsFixed(1)}m × ${room.lengthMeters.toStringAsFixed(1)}m',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accuracyColor.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accuracyColor, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    '$accuracyPercent%',
                    style: TextStyle(
                      color: accuracyColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Quality',
                    style: TextStyle(
                      color: accuracyColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gridLine, width: 0.5),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.highlight),
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
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            Container(
              height: 1,
              color: AppTheme.gridLine,
            ),
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
        const SizedBox(height: 8),
        _buildInfoRow('Area', '${room.area.toStringAsFixed(1)} m²'),
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
        fontFamily: 'monospace',
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

  Widget _buildSweetSpotPanel(SweetSpotResult result, RoomState roomState) {
    final accuracyPercent = (result.triangleAccuracy * 100).toInt();
    final accuracyColor = result.isOptimal
        ? AppTheme.sweetSpotGreen
        : result.triangleAccuracy >= 0.6
            ? AppTheme.sweetSpotYellow
            : AppTheme.sweetSpotRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccuracyBar(accuracyPercent, accuracyColor),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Triangle Accuracy',
          '$accuracyPercent%',
          valueColor: accuracyColor,
        ),
        _buildInfoRow(
          'Speaker Spacing',
          '${result.speakerSpacing.toStringAsFixed(2)}m',
        ),
        _buildInfoRow(
          'Left Distance',
          '${result.leftDistance.toStringAsFixed(2)}m',
          valueColor: AppTheme.leftSpeaker,
        ),
        _buildInfoRow(
          'Right Distance',
          '${result.rightDistance.toStringAsFixed(2)}m',
          valueColor: AppTheme.rightSpeaker,
        ),
        _buildInfoRow(
          'Listening Dist',
          '${result.listeningDistance.toStringAsFixed(2)}m',
        ),
        _buildInfoRow(
          'L Toe-in (Manual)',
          '${roomState.leftSpeaker.toeInDegrees.toStringAsFixed(1)}°',
          valueColor: AppTheme.leftSpeaker,
        ),
        _buildInfoRow(
          'R Toe-in (Manual)',
          '${roomState.rightSpeaker.toeInDegrees.toStringAsFixed(1)}°',
          valueColor: AppTheme.rightSpeaker,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accuracyColor.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accuracyColor.withAlpha(60), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                result.isOptimal
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 14,
                color: accuracyColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result.feedback,
                  style: TextStyle(
                    color: accuracyColor,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyBar(int percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Setup Quality',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: AppTheme.primary,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
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

  Widget _buildSpeakerToeIn(RoomState roomState) {
    final recommendedLeftToeIn = ref.watch(recommendedLeftToeInProvider);
    final recommendedRightToeIn = ref.watch(recommendedRightToeInProvider);
    final aimingPoint = ref.watch(recommendedAimingPointProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended Aiming Info
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.highlight.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.highlight.withAlpha(60),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 14,
                    color: AppTheme.highlight,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Recommended Aiming Point',
                    style: TextStyle(
                      color: AppTheme.highlight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'W: ${aimingPoint.x.toStringAsFixed(2)}m  D: ${aimingPoint.y.toStringAsFixed(2)}m',
                style: TextStyle(
                  color: AppTheme.highlight.withAlpha(220),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Point speakers 0.3m behind listening position for optimal imaging.',
                style: TextStyle(
                  color: AppTheme.highlight.withAlpha(200),
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildToeInSlider(
          label: 'Left Speaker',
          currentToeIn: roomState.leftSpeaker.toeInDegrees,
          recommendedToeIn: recommendedLeftToeIn,
          onChanged: (value) {
            ref.read(roomProvider.notifier).updateLeftSpeakerToeIn(value);
          },
          color: AppTheme.leftSpeaker,
        ),
        const SizedBox(height: 16),
        _buildToeInSlider(
          label: 'Right Speaker',
          currentToeIn: roomState.rightSpeaker.toeInDegrees,
          recommendedToeIn: recommendedRightToeIn,
          onChanged: (value) {
            ref.read(roomProvider.notifier).updateRightSpeakerToeIn(value);
          },
          color: AppTheme.rightSpeaker,
        ),
        const SizedBox(height: 12),
        // Apply Recommended Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref
                  .read(roomProvider.notifier)
                  .updateLeftSpeakerToeIn(recommendedLeftToeIn);
              ref
                  .read(roomProvider.notifier)
                  .updateRightSpeakerToeIn(recommendedRightToeIn);
            },
            icon: const Icon(
              Icons.auto_fix_high,
              size: 14,
              color: AppTheme.highlight,
            ),
            label: const Text(
              'Apply Recommended Toe-In',
              style: TextStyle(fontSize: 11, color: AppTheme.highlight),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.highlight, width: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.highlight.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.highlight.withAlpha(60),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: AppTheme.highlight,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Adjust toe-in to control speaker direction and optimize reflections.',
                  style: TextStyle(
                    color: AppTheme.highlight.withAlpha(220),
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
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
    final diff = (currentToeIn - recommendedToeIn).abs();
    final isNearRecommended = diff < 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(40),
                    border: Border.all(color: color, width: 1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                if (isNearRecommended) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppTheme.sweetSpotGreen.withAlpha(200),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Recommended: ${recommendedToeIn.toStringAsFixed(1)}°',
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(150),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentToeIn.clamp(0.0, 45.0),
          min: 0.0,
          max: 45.0,
          divisions: 45,
          onChanged: onChanged,
          activeColor: color,
          inactiveColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => ref.read(roomProvider.notifier).resetToDefaults(),
          icon: const Icon(
            Icons.refresh,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          label: const Text(
            'Reset All',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.textSecondary, width: 0.5),
          ),
        ),
      ],
    );
  }
}
