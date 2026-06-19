import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/p2p_connection_service.dart';
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
      Provider.of<P2pConnectionService>(context, listen: false).startControllerMode();
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
        final bs = Provider.of<P2pConnectionService>(context, listen: false);
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
      if (!mounted) return;
      setState(() => _isCameraInitialized = true); // Tetap tampilkan UI walau error kamera
    }
  }

  InputImage? _toInputImage(CameraImage img, CameraDescription cam) {
    if (kIsWeb) return null;
    final rot = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
    if (rot == null) return null;

    Uint8List bytes;
    final formatRaw = img.format.raw;
    
    // On Android, if format is YUV_420_888 (35), we must convert it to NV21 (17) manually
    // because MLKit's fromBytes on Android only accepts NV21.
    if (defaultTargetPlatform == TargetPlatform.android && formatRaw == 35) {
      if (img.planes.length != 3) return null;
      bytes = _yuv420ToNv21(img);
    } else {
      final buf = WriteBuffer();
      for (final p in img.planes) buf.putUint8List(p.bytes);
      bytes = buf.done().buffer.asUint8List();
    }

    final fmt = defaultTargetPlatform == TargetPlatform.android ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    
    debugPrint('DEBUG_CAMERA_FORMAT: formatRaw=$formatRaw, planes=${img.planes.length}, fmt=$fmt, rawValue=${fmt.rawValue}, bytes_len=${bytes.length}, width=${img.width}, height=${img.height}');
    
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rot, 
        format: fmt, 
        bytesPerRow: defaultTargetPlatform == TargetPlatform.android && formatRaw == 35 ? img.width : img.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final numPixels = width * height;
    final nv21 = Uint8List(numPixels + (numPixels ~/ 2));

    // Copy Y channel
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        nv21[y * width + x] = yBuffer[y * yPlane.bytesPerRow + x];
      }
    }

    // Copy V and U channels (NV21 format is V, U interleaved)
    int idUV = numPixels;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final uvIndex = y * uvRowStride + x * uvPixelStride;
        nv21[idUV++] = vBuffer[uvIndex];
        nv21[idUV++] = uBuffer[uvIndex];
      }
    }
    return nv21;
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    Provider.of<P2pConnectionService>(context, listen: false).stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p2pState = context.watch<P2pConnectionService>().state;
    final gesture = context.watch<GestureDetectionService>().currentGesture;
    final connected = p2pState == P2pState.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengendali'),
        actions: [
          if (p2pState == P2pState.disconnected)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.warning),
              tooltip: 'Cari Ulang',
              onPressed: () {
                context.read<P2pConnectionService>().startControllerMode();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: StatusPill(
              label: connected ? 'Terhubung' : (p2pState == P2pState.discovering ? 'Mencari...' : 'Terputus'),
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
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).padding.bottom),
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
          // ── Tombol Simulasi Pengendali ──
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
                  final cmds = [GestureType.tiltLeft, GestureType.tiltRight];
                  final cmd = cmds[DateTime.now().millisecondsSinceEpoch % cmds.length];
                  
                  // Simulasi proses gestur
                  final bs = Provider.of<P2pConnectionService>(context, listen: false);
                  final gs = Provider.of<GestureDetectionService>(context, listen: false);
                  
                  gs.simulateGesture(cmd, (g) {
                    if (g == GestureType.tiltLeft) bs.sendCommand(AppConstants.cmdLeft);
                    if (g == GestureType.tiltRight) bs.sendCommand(AppConstants.cmdRight);
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simulasi Gestur: ${cmd == GestureType.tiltLeft ? 'KIRI' : 'KANAN'}'), 
                      duration: const Duration(seconds: 1)
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.science_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Simulasi Gestur & Kirim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
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
