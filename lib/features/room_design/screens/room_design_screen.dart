import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/room_canvas.dart';
import '../widgets/room_setup_panel.dart';

class RoomDesignScreen extends ConsumerWidget {
  const RoomDesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Text(
              'Sweetspot',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(width: 10),
            _AppBarChip(label: 'Room Optimizer'),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 18),
            color: AppTheme.textSecondary,
            onPressed: () => _showHelp(context),
            tooltip: 'Help',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isWide ? const _WideLayout() : const _NarrowLayout(),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border, width: 0.5),
        ),
        title: const Text(
          'How to Use',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpItem(
                icon: Icons.drag_indicator_rounded,
                title: 'Drag markers',
                description:
                    'Drag L, R (speakers) or the Focus marker to reposition them in the room.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.change_history_rounded,
                title: 'Stereo triangle',
                description:
                    'The dashed triangle shows your stereo geometry. Equilateral is optimal.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.tune_rounded,
                title: 'Toe-in',
                description:
                    'Use the Tuning panel to adjust speaker toe-in. Apply the recommended value for best imaging.',
              ),
              SizedBox(height: 12),
              _HelpItem(
                icon: Icons.straighten_rounded,
                title: 'Measurements',
                description:
                    'Tap any measurement label to enter an exact distance. Works for speakers and listening position.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip in the app bar ───────────────────────────────────────────────────────

class _AppBarChip extends StatelessWidget {
  final String label;
  const _AppBarChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Wide layout (sidebar + canvas) ───────────────────────────────────────────

class _WideLayout extends StatefulWidget {
  const _WideLayout();

  @override
  State<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<_WideLayout> {
  double _sidebarWidth = 260;
  static const double _minWidth = 200;
  static const double _maxWidth = 480;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sidebar
        SizedBox(
          width: _sidebarWidth,
          child: const RoomSetupPanel(),
        ),
        // Resize handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (d) => setState(() {
              _sidebarWidth =
                  (_sidebarWidth + d.delta.dx).clamp(_minWidth, _maxWidth);
            }),
            onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
            child: Container(
              width: 1,
              color: _isDragging ? AppTheme.accent : AppTheme.border,
            ),
          ),
        ),
        // Canvas fills everything else
        const Expanded(child: RoomCanvas()),
      ],
    );
  }
}

// ── Narrow (mobile) layout ────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // Canvas gets the top 55 % of available height
        Expanded(
          flex: 55,
          child: RoomCanvas(),
        ),
        Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
        // Panel scrolls in the bottom 45 %
        Expanded(
          flex: 45,
          child: SingleChildScrollView(child: RoomSetupPanel()),
        ),
      ],
    );
  }
}

// ── Help dialog items ─────────────────────────────────────────────────────────

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
        Icon(icon, color: AppTheme.accent, size: 16),
        const SizedBox(width: 10),
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
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
