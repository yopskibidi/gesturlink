import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import '../core/constants.dart';

class ActionLog {
  final String command;
  final DateTime timestamp;
  ActionLog(this.command, this.timestamp);
}

class BleReceiverService extends ChangeNotifier {
  final FlutterBlePeripheral _blePeripheral = FlutterBlePeripheral();
  
  bool _isAdvertising = false;
  bool get isAdvertising => _isAdvertising;

  List<ActionLog> _actionLogs = [];
  List<ActionLog> get actionLogs => _actionLogs;

  Future<void> startAdvertising() async {
    if (kIsWeb) {
      debugPrint('BLE Peripheral mocked on Web');
      _isAdvertising = true;
      notifyListeners();
      return;
    }

    try {
      bool isSupported = await _blePeripheral.isSupported;
      if (!isSupported) {
        debugPrint('BLE Peripheral not supported on this device');
        return;
      }

      final AdvertiseData advertiseData = AdvertiseData(
        serviceUuid: AppConstants.customServiceUuid,
        localName: AppConstants.appName,
      );

      await _blePeripheral.start(advertiseData: advertiseData);
      _isAdvertising = true;
      notifyListeners();
      
      // Since flutter_ble_peripheral primarily handles advertising rather than full GATT characteristic writes natively in dart without a customized platform channel, we are exposing a method that can receive commands if integrated with another GATT library or a simulated receiver.
    } catch (e) {
      debugPrint('Advertise error: $e');
    }
  }

  Future<void> stopAdvertising() async {
    if (kIsWeb) {
      _isAdvertising = false;
      notifyListeners();
      return;
    }
    await _blePeripheral.stop();
    _isAdvertising = false;
    notifyListeners();
  }
  
  void onCommandReceived(String command) {
    _actionLogs.insert(0, ActionLog(command, DateTime.now()));
    notifyListeners();
  }
}
