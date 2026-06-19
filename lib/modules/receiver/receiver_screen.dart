import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/p2p_connection_service.dart';
import '../../widgets/status_pill.dart';

/// Layar Penerima — dashboard profesional dengan log timeline.
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final PageController _pageController = PageController();
  DateTime? _lastProcessedLogTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<P2pConnectionService>(context, listen: false).startReceiverMode();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    Provider.of<P2pConnectionService>(context, listen: false).stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<P2pConnectionService>();

    // Proses perintah terbaru untuk mengubah slide
    if (svc.actionLogs.isNotEmpty) {
      final latestLog = svc.actionLogs.first;
      if (_lastProcessedLogTime != latestLog.timestamp) {
        _lastProcessedLogTime = latestLog.timestamp;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (latestLog.command == 'LEFT' || latestLog.command == 'cmd_left') {
            _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
          } else if (latestLog.command == 'RIGHT' || latestLog.command == 'cmd_right') {
            _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerima'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusPill(
              label: svc.state == P2pState.connected ? 'Terhubung' : (svc.state == P2pState.advertising ? 'Siaran Aktif' : 'Nonaktif'),
              active: svc.state == P2pState.connected || svc.state == P2pState.advertising,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),

          // ── Area Demo Slide (Mini Project UAS) ──
          Container(
            height: 220,
            color: AppTheme.bgCard,
            child: PageView(
              controller: _pageController,
              children: [
                _buildSlide(
                  title: 'GesturLink',
                  content: 'Touchless Presentation Controller\nvia P2P & Machine Learning\n\nMini Project UAS',
                  icon: Icons.gesture,
                  color: AppTheme.accent,
                ),
                _buildSlide(
                  title: 'Latar Belakang',
                  content: 'Banyak presentator harus terpaku pada laptop saat menjelaskan. GesturLink hadir untuk memberikan kontrol hands-free menggunakan gestur kemiringan kepala.',
                  icon: Icons.lightbulb_outline,
                  color: AppTheme.warning,
                ),
                _buildSlide(
                  title: 'Arsitektur Sistem',
                  content: '1. ML Kit: Deteksi rotasi wajah (Euler Z) real-time.\n2. Nearby API: Komunikasi P2P offline tanpa latensi.\n3. Flutter: Antarmuka & State Management lintas perangkat.',
                  icon: Icons.architecture,
                  color: AppTheme.accentSoft,
                ),
                _buildSlide(
                  title: 'Hasil Evaluasi',
                  content: 'Penyampaian perintah berjalan sangat responsif. Penguncian gestur (Neutral Lock) terbukti mengurangi false-positive dan double-triggering.',
                  icon: Icons.analytics_outlined,
                  color: AppTheme.success,
                ),
                _buildSlide(
                  title: 'Sesi Selesai',
                  content: 'Terima kasih atas perhatiannya!\nMari kita mulai sesi diskusi dan tanya jawab.\n\n(Gunakan gestur KIRI/KANAN untuk memindahkan slide)',
                  icon: Icons.forum_outlined,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (svc.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.warning.withOpacity(0.1),
              child: Text(
                'Error: ${svc.errorMessage}',
                style: const TextStyle(color: AppTheme.warning, fontSize: 12),
              ),
            ),
          const Divider(height: 1),

          // ── Header Log ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Log Perintah',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.text),
                ),
                const Spacer(),
                Text(
                  '${svc.actionLogs.length} entri',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // ── Daftar Log ──
          Expanded(
            child: svc.actionLogs.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: svc.actionLogs.length,
                    itemBuilder: (_, i) => _logRow(svc.actionLogs[i], i == 0),
                  ),
          ),

          // ── Tombol Simulasi ──
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.bgCard,
                  foregroundColor: AppTheme.textSub,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.r8),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
                onPressed: () {
                  final cmds = ['LEFT', 'RIGHT'];
                  final cmd = cmds[DateTime.now().millisecondsSinceEpoch % cmds.length];
                  Provider.of<P2pConnectionService>(context, listen: false).simulateCommand(cmd);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Simulasi diterima: Gestur $cmd'), duration: const Duration(seconds: 1)),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.science_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Simulasi Perintah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerVertical() {
    return Container(width: 1, height: 36, color: AppTheme.border);
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(AppTheme.r12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.inbox_outlined, size: 24, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada perintah', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSub)),
          const SizedBox(height: 4),
          const Text('Perintah dari pengendali akan muncul di sini.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _logRow(ActionLog log, bool latest) {
    final isLeft = log.command == 'LEFT';
    final isRight = log.command == 'RIGHT';
    final label = isLeft ? 'Gestur Kiri' : (isRight ? 'Gestur Kanan' : log.command);
    final icon = isLeft ? Icons.west_rounded : (isRight ? Icons.east_rounded : Icons.bolt_rounded);
    final time =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: latest ? AppTheme.accent.withOpacity(0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.r8),
        border: Border.all(color: latest ? AppTheme.accent.withOpacity(0.15) : AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: latest ? AppTheme.accent.withOpacity(0.1) : AppTheme.bgCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: latest ? AppTheme.accent : AppTheme.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: latest ? AppTheme.text : AppTheme.textSub,
                )),
                Text(time, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
          if (latest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Terbaru',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accent, letterSpacing: 0.3)),
            ),
        ],
      ),
    );
  }

  Widget _buildSlide({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.r16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: color
                  )
                ),
                const SizedBox(height: 8),
                Text(content, 
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSub, height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
