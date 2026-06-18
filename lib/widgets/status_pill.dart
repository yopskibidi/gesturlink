import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Widget _StatusPill — indikator status kecil dan elegan.
/// Digunakan di AppBar dan dashboard.
class StatusPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color? activeColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.active,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? (active ? AppTheme.success : AppTheme.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
