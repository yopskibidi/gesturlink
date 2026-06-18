import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/permission_service.dart';
import '../../widgets/animated_mode_card.dart';
import '../controller/controller_screen.dart';
import '../receiver/receiver_screen.dart';

/// Layar pemilihan mode — desain tingkat enterprise.
class SelectorScreen extends StatefulWidget {
  const SelectorScreen({super.key});

  @override
  State<SelectorScreen> createState() => _SelectorScreenState();
}

class _SelectorScreenState extends State<SelectorScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
  }

  Future<void> _checkPermissions() async {
    final svc = Provider.of<PermissionService>(context, listen: false);
    final granted = await svc.requestAllPermissions();
    if (mounted) setState(() => _permissionsGranted = granted);
  }

  void _navigate(Widget screen) {
    if (_permissionsGranted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin Kamera & Bluetooth diperlukan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gesture, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GesturLink',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  // Versi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Text(
                      'v1.0',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Divider(),
            ),

            // ── Konten Utama ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Pilih Mode\nPerangkat',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tentukan peran perangkat ini untuk memulai sesi interaksi tanpa sentuhan.',
                      style: TextStyle(fontSize: 15, color: AppTheme.textSub, height: 1.5),
                    ),

                    // ── Peringatan Izin ──
                    if (!_permissionsGranted) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _checkPermissions,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(AppTheme.r10),
                            border: Border.all(color: AppTheme.warning.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18, color: AppTheme.warning),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Izin diperlukan — ketuk untuk mengaktifkan',
                                  style: TextStyle(color: AppTheme.warning, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.warning),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Label Seksi ──
                    Text(
                      'MODE TERSEDIA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Kartu Mode ──
                    AnimatedModeCard(
                      title: 'Pengendali Gestur',
                      subtitle: 'Deteksi gerakan kepala dan kirim perintah via BLE',
                      icon: Icons.videocam_outlined,
                      onTap: () => _navigate(const ControllerScreen()),
                    ),
                    const SizedBox(height: 10),
                    AnimatedModeCard(
                      title: 'Penerima Perintah',
                      subtitle: 'Terima dan tampilkan perintah masuk secara real-time',
                      icon: Icons.sensors_rounded,
                      onTap: () => _navigate(const ReceiverScreen()),
                    ),

                    const Spacer(),

                    // ── Footer ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          const Text(
                            'Mobile Computing Project',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
