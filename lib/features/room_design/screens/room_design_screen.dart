import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/room_canvas.dart';
import '../widgets/room_setup_panel.dart';

class RoomDesignScreen extends ConsumerWidget {
  const RoomDesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.graphic_eq, color: AppTheme.highlight, size: 20),
            SizedBox(width: 8),
            Text('SWEETSPOT'),
            SizedBox(width: 8),
            Text(
              'Speaker Placement & Room Optimizer',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 18),
            color: AppTheme.textSecondary,
            onPressed: () => _showHelp(context),
            tooltip: 'Help',
          ),
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(context),
    );
  }

  Widget _buildWideLayout() {
    return const _ResizableSidebar();
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: RoomCanvas()),
        Container(height: 1, color: AppTheme.gridLine),
        const SizedBox(
          height: 320,
          child: SingleChildScrollView(child: RoomSetupPanel()),
        ),
      ],
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'How to Use Sweetspot',
          style: TextStyle(color: AppTheme.highlight),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                icon: Icons.drag_indicator,
                title: 'Drag Objects',
                description:
                    'Tap and drag the L (left speaker), R (right speaker), '
                    'or LP (listening position) markers to reposition them.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.change_history,
                title: 'Stereo Triangle',
                description: 'The dashed triangle shows the stereo geometry. '
                    'An equilateral triangle gives optimal stereo imaging.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.grain,
                title: 'Speaker Toe-in',
                description:
                    'Adjust speaker toe-in angles using the sliders in the right panel. '
                    'The direction arrow on each speaker shows its current pointing direction. '
                    'Changes update reflections in real-time.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.speaker,
                title: 'Speaker Specifications',
                description:
                    'Define speaker driver configuration in metric units (mm). '
                    'Choose from presets or customize specifications. '
                    'All sizes displayed in metric (millimeters, centimeters).',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.tune,
                title: 'Advanced Mode',
                description:
                    'Enable Advanced Mode to input amplifier power (watts), impedance (ohms), '
                    'sensitivity (dB), and customize woofer/tweeter specifications. '
                    'Calculated properties update dynamically.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.waves,
                title: 'Reflection Points',
                description: 'Orange markers show where early reflections '
                    'hit the walls. These update dynamically as you adjust '
                    'speaker toe-in and specifications. Place acoustic panels to control reflections.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.straighten,
                title: 'Distance Measurements',
                description:
                    'Shows distances from listening position and speakers to walls. '
                    'Click on a measurement label to input a specific value.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.grid_3x3,
                title: 'Grid & Scale',
                description:
                    'The room preview automatically scales to fit your screen. '
                    'Grid lines show 0.5m spacing for reference.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppTheme.highlight),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.highlight, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResizableSidebar extends StatefulWidget {
  const _ResizableSidebar();

  @override
  State<_ResizableSidebar> createState() => _ResizableSidebarState();
}

class _ResizableSidebarState extends State<_ResizableSidebar> {
  double _sidebarWidth = 260; // Default width
  final double _minWidth = 200; // Minimum width
  final double _maxWidth = 500; // Maximum width
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _sidebarWidth,
          child: const RoomSetupPanel(),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              setState(() => _isDragging = true);
            },
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sidebarWidth = (_sidebarWidth + details.delta.dx)
                    .clamp(_minWidth, _maxWidth);
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() => _isDragging = false);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 8,
                color: _isDragging
                    ? AppTheme.highlight.withAlpha(100)
                    : AppTheme.gridLine,
              ),
            ),
          ),
        ),
        const Expanded(
          child: RoomCanvas(),
        ),
      ],
    );
  }
}
