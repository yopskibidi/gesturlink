import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestAllPermissions() async {
    if (kIsWeb) return true; // Bypass on Web for UI testing

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
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }
}
