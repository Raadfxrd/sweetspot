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
  final _heightController = TextEditingController();
  bool _initialized = false;
  Room? _lastSeenRoom;

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _syncControllersFromRoom(Room room) {
    _widthController.text = room.widthMeters.toStringAsFixed(1);
    _lengthController.text = room.lengthMeters.toStringAsFixed(1);
    _heightController.text = room.heightMeters.toStringAsFixed(1);
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
            _lastSeenRoom!.lengthMeters != room.lengthMeters ||
            _lastSeenRoom!.heightMeters != room.heightMeters) &&
        _widthController.text ==
            _lastSeenRoom!.widthMeters.toStringAsFixed(1) &&
        _lengthController.text ==
            _lastSeenRoom!.lengthMeters.toStringAsFixed(1) &&
        _heightController.text ==
            _lastSeenRoom!.heightMeters.toStringAsFixed(1)) {
      // Room changed externally (e.g., reset), update controllers
      _syncControllersFromRoom(room);
    }

    return Container(
      color: AppTheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('ROOM DIMENSIONS'),
            const SizedBox(height: 12),
            _buildDimensionFields(room),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.gridLine),
            const SizedBox(height: 16),
            _buildSectionHeader('SWEET SPOT ANALYSIS'),
            const SizedBox(height: 12),
            _buildSweetSpotPanel(sweetSpot),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.gridLine),
            const SizedBox(height: 16),
            _buildSectionHeader('SPEAKER POSITIONS'),
            const SizedBox(height: 12),
            _buildSpeakerPositions(roomState),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.gridLine),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.highlight,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        fontFamily: 'monospace',
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
        _buildTextField(
          controller: _heightController,
          label: 'Height (m)',
          onChanged: (_) => _applyRoomDimensions(room),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Area', '${room.area.toStringAsFixed(1)} m²'),
        _buildInfoRow('Volume', '${room.volume.toStringAsFixed(1)} m³'),
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
    final height = double.tryParse(_heightController.text);

    if (width != null &&
        width > 0 &&
        length != null &&
        length > 0 &&
        height != null &&
        height > 0) {
      ref
          .read(roomProvider.notifier)
          .updateRoom(
            currentRoom.copyWith(
              widthMeters: width.clamp(1.0, 30.0),
              lengthMeters: length.clamp(1.0, 30.0),
              heightMeters: height.clamp(1.5, 10.0),
            ),
          );
    }
  }

  Widget _buildSweetSpotPanel(SweetSpotResult result) {
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
          'L Toe-in',
          '${result.suggestedToeInLeft.toStringAsFixed(1)}°',
          valueColor: AppTheme.leftSpeaker,
        ),
        _buildInfoRow(
          'R Toe-in',
          '${result.suggestedToeInRight.toStringAsFixed(1)}°',
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

  Widget _buildSpeakerPositions(RoomState roomState) {
    final lPos = roomState.leftSpeaker.position;
    final rPos = roomState.rightSpeaker.position;
    final lpPos = roomState.listeningPosition.position;

    return Column(
      children: [
        _buildSpeakerRow('L', lPos.x, lPos.y, AppTheme.leftSpeaker),
        const SizedBox(height: 4),
        _buildSpeakerRow('R', rPos.x, rPos.y, AppTheme.rightSpeaker),
        const SizedBox(height: 4),
        _buildSpeakerRow('LP', lpPos.x, lpPos.y, AppTheme.listeningPos),
      ],
    );
  }

  Widget _buildSpeakerRow(String label, double x, double y, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(40),
            border: Border.all(color: color, width: 1),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'x: ${x.toStringAsFixed(2)}m  y: ${y.toStringAsFixed(2)}m',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
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

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('ACTIONS'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () =>
              ref.read(roomProvider.notifier).suggestOptimalListeningPosition(),
          icon: const Icon(Icons.auto_awesome, size: 14),
          label: const Text(
            'Suggest Sweet Spot',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => ref.read(roomProvider.notifier).autoPlaceSpeakers(),
          icon: const Icon(Icons.speaker, size: 14),
          label: const Text(
            'Auto Place Speakers',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => ref.read(roomProvider.notifier).resetToDefaults(),
          icon: const Icon(
            Icons.refresh,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          label: const Text(
            'Reset',
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
