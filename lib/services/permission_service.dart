import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestAllPermissions() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) return true; // Bypass on Web & Desktop for UI testing

    List<Permission> permissions = [
      Permission.camera,
      Permission.location,
    ];

    if (defaultTargetPlatform == TargetPlatform.android) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ]);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      permissions.add(Permission.bluetooth);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = true;
    bool hasPermanentlyDenied = false;

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
      if (status.isPermanentlyDenied) {
        hasPermanentlyDenied = true;
      }
    });

    if (hasPermanentlyDenied) {
      await openAppSettings();
    }

    return allGranted;
  }
}
