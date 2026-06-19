import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum GestureType { none, tiltLeft, tiltRight }

class GestureDetectionService extends ChangeNotifier {
  FaceDetector? _faceDetector;

  GestureDetectionService() {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows && defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.macOS) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableContours: false,
          enableLandmarks: false,
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
    }
  }

  bool _isProcessing = false;
  bool _isNeutral = true;
  GestureType _currentGesture = GestureType.none;
  DateTime _lastGestureTime = DateTime.now();

  GestureType get currentGesture => _currentGesture;

  Future<void> processImage(InputImage inputImage, Function(GestureType) onGestureDetected) async {
    if (_isProcessing || kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS || _faceDetector == null) return;
    _isProcessing = true;

    try {
      final faces = await _faceDetector!.processImage(inputImage);
      
      if (faces.isNotEmpty) {
        final face = faces.first;
        // headEulerAngleZ is tilt angle.
        // Negative -> tilt left, Positive -> tilt right
        double tiltAngle = face.headEulerAngleZ ?? 0.0;

        // Require head to return to neutral (-10 to 10 degrees) before allowing next gesture
        if (tiltAngle > -10.0 && tiltAngle < 10.0) {
          _isNeutral = true;
        }

        GestureType detected = GestureType.none;
        // Increase threshold to 18.0 for more deliberate tilt
        if (tiltAngle < -18.0 && _isNeutral) {
          detected = GestureType.tiltLeft;
        } else if (tiltAngle > 18.0 && _isNeutral) {
          detected = GestureType.tiltRight;
        }

        if (detected != GestureType.none) {
          _isNeutral = false; // Lock gesture until head returns to neutral
          final now = DateTime.now();
          // Increase cooldown to 800ms to avoid accidental quick double-triggers
          if (now.difference(_lastGestureTime).inMilliseconds > 800) {
            _lastGestureTime = now;
            _currentGesture = detected;
            onGestureDetected(detected);
            notifyListeners();
            
            Future.delayed(const Duration(milliseconds: 800), () {
              _currentGesture = GestureType.none;
              notifyListeners();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting face: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void simulateGesture(GestureType gesture, Function(GestureType) onGestureDetected) {
    final now = DateTime.now();
    if (now.difference(_lastGestureTime).inMilliseconds > 500) {
      _lastGestureTime = now;
      _currentGesture = gesture;
      onGestureDetected(gesture);
      notifyListeners();
      
      Future.delayed(const Duration(milliseconds: 500), () {
        _currentGesture = GestureType.none;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _faceDetector?.close();
    super.dispose();
  }
}
