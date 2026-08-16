import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:itfits/core/services/providers.dart';
import 'floor_plan_screen.dart';
import 'isometric_explorer_screen.dart';

class FloorPlanCombinedScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const FloorPlanCombinedScreen({super.key, required this.onComplete, this.onBack});

  @override
  ConsumerState<FloorPlanCombinedScreen> createState() => _FloorPlanCombinedScreenState();
}

class _FloorPlanCombinedScreenState extends ConsumerState<FloorPlanCombinedScreen> {
  bool _show3D = false;

  void _toggle() => setState(() => _show3D = !_show3D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final floorPlan = ref.watch(floorPlanDataProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(colorScheme, theme, floorPlan),
          Expanded(
            child: _show3D
                ? IsometricExplorerScreen(
                    onComplete: widget.onComplete,
                    onBack: () => setState(() => _show3D = false),
                  )
                : FloorPlanScreen(
                    onComplete: () => setState(() => _show3D = true),
                    onBack: widget.onBack,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, ThemeData theme, dynamic floorPlan) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),
            const SizedBox(width: 4),
            // Toggle between 2D and 3D
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ToggleChip(
                    label: '2D Plan',
                    icon: Icons.architecture_outlined,
                    isSelected: !_show3D,
                    onTap: () => setState(() => _show3D = false),
                    colorScheme: colorScheme,
                  ),
                  _ToggleChip(
                    label: '3D View',
                    icon: Icons.view_in_ar_outlined,
                    isSelected: _show3D,
                    onTap: () => setState(() => _show3D = true),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (floorPlan != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${floorPlan.roomWidth.toStringAsFixed(1)}\u00D7${floorPlan.roomDepth.toStringAsFixed(1)}m',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
