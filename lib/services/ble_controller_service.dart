import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../core/constants.dart';

enum BleConnectionState { scanning, connected, disconnected }

class BleControllerService extends ChangeNotifier {
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState => _connectionState;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  Future<void> startScanning() async {
    if (_connectionState == BleConnectionState.connected) return;
    
    _connectionState = BleConnectionState.scanning;
    notifyListeners();

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      debugPrint('BLE Scan mocked on Web/Desktop');
      Future.delayed(const Duration(seconds: 2), () {
        _connectionState = BleConnectionState.connected;
        notifyListeners();
      });
      return;
    }

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(AppConstants.customServiceUuid)],
        timeout: const Duration(seconds: 15),
      );

      _scanSubscription = FlutterBluePlus.onScanResults.listen((results) async {
        if (results.isNotEmpty) {
          ScanResult result = results.first;
          await stopScanning();
          await connectToDevice(result.device);
        }
      });
    } catch (e) {
      debugPrint('Scan error: $e');
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> stopScanning() async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) return;
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    if (_connectionState == BleConnectionState.scanning) {
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await (device as dynamic).connect();
      _connectedDevice = device;
      
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == AppConstants.customServiceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == AppConstants.customCharacteristicUuid) {
              _commandCharacteristic = characteristic;
            }
          }
        }
      }

      _connectionState = BleConnectionState.connected;
      notifyListeners();

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionState = BleConnectionState.disconnected;
          _connectedDevice = null;
          _commandCharacteristic = null;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Connection error: $e');
      _connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> sendCommand(String command) async {
    if (_commandCharacteristic != null && _connectionState == BleConnectionState.connected) {
      try {
        await _commandCharacteristic!.write(utf8.encode(command), withoutResponse: true);
      } catch (e) {
        debugPrint('Write error: $e');
      }
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectionState = BleConnectionState.disconnected;
    _connectedDevice = null;
    _commandCharacteristic = null;
    notifyListeners();
  }
}
