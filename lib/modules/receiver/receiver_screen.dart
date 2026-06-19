import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/ble_receiver_service.dart';
import '../../widgets/status_pill.dart';

/// Layar Penerima — dashboard profesional dengan log timeline.
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BleReceiverService>(context, listen: false).startAdvertising();
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BleReceiverService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penerima'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusPill(
              label: svc.isAdvertising ? 'Siaran Aktif' : 'Nonaktif',
              active: svc.isAdvertising,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),

          // ── Panel Statistik ──
          Container(
            color: AppTheme.bgElevated,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _statItem('Status', svc.isAdvertising ? 'Aktif' : 'Nonaktif',
                    svc.isAdvertising ? AppTheme.success : AppTheme.textMuted),
                _dividerVertical(),
                _statItem('Perintah', '${svc.actionLogs.length}', AppTheme.text),
                _dividerVertical(),
                _statItem('Mode', 'Peripheral', AppTheme.textSub),
              ],
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
                  Provider.of<BleReceiverService>(context, listen: false).onCommandReceived(cmd);
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

  Widget _statItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value,
            style: TextStyle(fontSize: 16, color: valueColor, fontWeight: FontWeight.w700)),
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
}
