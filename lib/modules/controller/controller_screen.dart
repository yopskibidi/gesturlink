import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/ble_controller_service.dart';
import '../../services/gesture_detection_service.dart';
import '../../widgets/status_pill.dart';

/// Layar Pengendali — kamera + deteksi gestur + kirim perintah BLE.
class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
      Provider.of<BleControllerService>(context, listen: false).startScanning();
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        front, ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null
            : (defaultTargetPlatform == TargetPlatform.android
                ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888),
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);

      _cameraController!.startImageStream((image) {
        if (!mounted) return;
        final gs = Provider.of<GestureDetectionService>(context, listen: false);
        final bs = Provider.of<BleControllerService>(context, listen: false);
        final input = _toInputImage(image, front);
        if (input != null) {
          gs.processImage(input, (g) {
            if (g == GestureType.tiltLeft) bs.sendCommand(AppConstants.cmdLeft);
            if (g == GestureType.tiltRight) bs.sendCommand(AppConstants.cmdRight);
          });
        }
      });
    } catch (e) {
      debugPrint('Kamera error: $e');
    }
  }

  InputImage? _toInputImage(CameraImage img, CameraDescription cam) {
    if (kIsWeb) return null;
    final buf = WriteBuffer();
    for (final p in img.planes) buf.putUint8List(p.bytes);
    final bytes = buf.done().buffer.asUint8List();
    final rot = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
    final fmt = InputImageFormatValue.fromRawValue(img.format.raw);
    if (rot == null || fmt == null) return null;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rot, format: fmt, bytesPerRow: img.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleControllerService>().connectionState;
    final gesture = context.watch<GestureDetectionService>().currentGesture;
    final connected = ble == BleConnectionState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengendali'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: StatusPill(
              label: connected ? 'Terhubung' : 'Mencari...',
              active: connected,
              activeColor: connected ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),

          // ── Kamera ──
          Expanded(
            child: Container(
              color: AppTheme.bgElevated,
              child: _isCameraInitialized
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        // Kamera
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 480),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.r16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.r16 - 1),
                                child: CameraPreview(_cameraController!),
                              ),
                            ),
                          ),
                        ),
                        // Indikator Gestur Kiri
                        if (gesture == GestureType.tiltLeft)
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.r12),
                                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.west_rounded, size: 32, color: AppTheme.accent),
                              ),
                            ),
                          ),
                        // Indikator Gestur Kanan
                        if (gesture == GestureType.tiltRight)
                          Positioned(
                            right: 0, top: 0, bottom: 0,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.r12),
                                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.east_rounded, size: 32, color: AppTheme.accent),
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.textMuted)),
                          SizedBox(height: 12),
                          Text('Memuat kamera...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
            ),
          ),

          // ── Bar Bawah — Info Gestur ──
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.bg,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _gestureBox('KIRI', Icons.west_rounded, gesture == GestureType.tiltLeft),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(AppTheme.r8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          gesture == GestureType.none ? Icons.face_outlined : Icons.face,
                          color: gesture == GestureType.none ? AppTheme.textMuted : AppTheme.accent,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gesture == GestureType.none ? 'Menunggu...' : 'Terdeteksi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: gesture == GestureType.none ? AppTheme.textMuted : AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _gestureBox('KANAN', Icons.east_rounded, gesture == GestureType.tiltRight),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gestureBox(String label, IconData icon, bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.accent.withOpacity(0.1) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.r8),
          border: Border.all(color: active ? AppTheme.accent.withOpacity(0.4) : AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: active ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                color: active ? AppTheme.accent : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
