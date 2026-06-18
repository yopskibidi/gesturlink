import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/permission_service.dart';
import 'selector_screen.dart';

/// Loading Screen — inisialisasi sistem sebelum masuk ke aplikasi.
///
/// Menampilkan daftar tugas inisialisasi (izin, kamera, bluetooth)
/// dengan status progres visual per item.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

/// Model untuk setiap langkah inisialisasi.
class _InitStep {
  final String label;
  final IconData icon;
  _StepStatus status;

  _InitStep({
    required this.label,
    required this.icon,
    this.status = _StepStatus.pending,
  });
}

enum _StepStatus { pending, loading, done, failed }

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  final List<_InitStep> _steps = [
    _InitStep(label: 'Memeriksa sistem perangkat', icon: Icons.devices_rounded),
    _InitStep(label: 'Meminta izin akses', icon: Icons.shield_outlined),
    _InitStep(label: 'Menyiapkan modul kamera', icon: Icons.videocam_outlined),
    _InitStep(label: 'Menginisialisasi Bluetooth', icon: Icons.bluetooth_rounded),
    _InitStep(label: 'Memuat antarmuka', icon: Icons.dashboard_outlined),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _runInit());
  }

  Future<void> _runInit() async {
    // Langkah 1: Periksa sistem
    await _executeStep(0, () async {
      await Future.delayed(const Duration(milliseconds: 600));
    });

    // Langkah 2: Minta izin
    await _executeStep(1, () async {
      final svc = Provider.of<PermissionService>(context, listen: false);
      await svc.requestAllPermissions();
    });

    // Langkah 3: Modul kamera
    await _executeStep(2, () async {
      await Future.delayed(const Duration(milliseconds: 500));
    });

    // Langkah 4: Bluetooth
    await _executeStep(3, () async {
      await Future.delayed(const Duration(milliseconds: 500));
    });

    // Langkah 5: Antarmuka
    await _executeStep(4, () async {
      await Future.delayed(const Duration(milliseconds: 400));
    });

    // Jeda singkat lalu navigasi
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SelectorScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }
  }

  /// Menjalankan satu langkah dan memperbarui statusnya.
  Future<void> _executeStep(int index, Future<void> Function() task) async {
    if (!mounted) return;
    setState(() => _steps[index].status = _StepStatus.loading);

    try {
      await task();
      if (mounted) setState(() => _steps[index].status = _StepStatus.done);
    } catch (_) {
      if (mounted) setState(() => _steps[index].status = _StepStatus.failed);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _steps.where((s) => s.status == _StepStatus.done).length;
    final progress = doneCount / _steps.length;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppTheme.bg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // ── Header ──
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.gesture, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'GesturLink',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // ── Judul ──
                  const Text(
                    'Menyiapkan\naplikasi...',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Proses ini hanya berlangsung beberapa detik.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // ── Progress Bar Global ──
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Persentase ──
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Daftar Langkah ──
                  ...List.generate(_steps.length, (i) {
                    return _buildStepRow(_steps[i], i);
                  }),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(_InitStep step, int index) {
    final Color iconColor;
    final Widget trailing;

    switch (step.status) {
      case _StepStatus.pending:
        iconColor = AppTheme.textMuted.withOpacity(0.4);
        trailing = const SizedBox.shrink();
        break;
      case _StepStatus.loading:
        iconColor = AppTheme.accent;
        trailing = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppTheme.accent,
          ),
        );
        break;
      case _StepStatus.done:
        iconColor = AppTheme.success;
        trailing = const Icon(Icons.check_rounded, size: 16, color: AppTheme.success);
        break;
      case _StepStatus.failed:
        iconColor = AppTheme.danger;
        trailing = const Icon(Icons.close_rounded, size: 16, color: AppTheme.danger);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(step.icon, size: 18, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 14,
                color: step.status == _StepStatus.pending
                    ? AppTheme.textMuted.withOpacity(0.5)
                    : (step.status == _StepStatus.loading
                        ? AppTheme.text
                        : AppTheme.textSub),
                fontWeight: step.status == _StepStatus.loading
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// AnimatedFractionallySizedBox — FractionallySizedBox dengan animasi.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  final double widthFactor;
  final Widget child;

  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
    super.curve = Curves.linear,
  });

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}
