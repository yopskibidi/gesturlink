import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Kartu pemilihan mode — desain bersih ala Linear/Notion.
/// Layout horizontal, ikon kiri, teks tengah, panah kanan.
class AnimatedModeCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const AnimatedModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<AnimatedModeCard> createState() => _AnimatedModeCardState();
}

class _AnimatedModeCardState extends State<AnimatedModeCard> {
  bool _pressing = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressing = true),
        onTapUp: (_) {
          setState(() => _pressing = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressing = false),
        child: AnimatedScale(
          scale: _pressing ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _hovering ? AppTheme.bgHover : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(
                color: _hovering ? AppTheme.border.withOpacity(0.8) : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppTheme.r10),
                  ),
                  child: Icon(widget.icon, size: 22, color: AppTheme.accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: _hovering ? 0.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: _hovering ? AppTheme.textSub : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
