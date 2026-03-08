import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/room_canvas.dart';
import '../widgets/room_setup_panel.dart';
import '../../../core/theme/app_theme.dart';

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
      body: isWide
          ? _buildWideLayout()
          : _buildNarrowLayout(context),
    );
  }

  Widget _buildWideLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 260,
          child: RoomSetupPanel(),
        ),
        VerticalDivider(width: 1, color: AppTheme.gridLine),
        Expanded(child: RoomCanvas()),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: RoomCanvas()),
        Container(
          height: 1,
          color: AppTheme.gridLine,
        ),
        SizedBox(
          height: 320,
          child: SingleChildScrollView(
            child: const RoomSetupPanel(),
          ),
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
                description:
                    'The dashed triangle shows the stereo geometry. '
                    'An equilateral triangle gives optimal stereo imaging.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.blur_on,
                title: 'Sweet Spot Heatmap',
                description:
                    'Green = optimal stereo imaging zone, '
                    'Yellow = acceptable, Red = poor imaging.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.waves,
                title: 'Reflection Points',
                description:
                    'Orange markers show where early reflections '
                    'hit the walls. Place acoustic panels here.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.auto_awesome,
                title: 'Auto Suggest',
                description:
                    'Use "Suggest Sweet Spot" to automatically calculate '
                    'the optimal listening position for the equilateral triangle.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it', style: TextStyle(color: AppTheme.highlight)),
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
