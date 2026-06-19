import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

import '../core/constants.dart';

enum P2pRole { none, controller, receiver }
enum P2pState { disconnected, advertising, discovering, connecting, connected }

class P2pConnectionService extends ChangeNotifier {
  final String _userName = '${AppConstants.appName}_${Random().nextInt(1000)}';
  final Strategy _strategy = Strategy.P2P_STAR; // 1-to-N or 1-to-1

  P2pRole _role = P2pRole.none;
  P2pState _state = P2pState.disconnected;
  String? _connectedEndpointId;
  String? _errorMessage;

  P2pRole get role => _role;
  P2pState get state => _state;
  String? get connectedEndpointId => _connectedEndpointId;
  String? get errorMessage => _errorMessage;

  // Receiver Logs
  final List<ActionLog> _actionLogs = [];
  List<ActionLog> get actionLogs => _actionLogs;

  // Controller stats
  int _commandsSent = 0;
  int get commandsSent => _commandsSent;

  /// Starts the Receiver mode (Advertiser)
  Future<void> startReceiverMode() async {
    _role = P2pRole.receiver;
    _state = P2pState.advertising;
    _errorMessage = null;
    notifyListeners();

    try {
      bool a = await Nearby().startAdvertising(
        _userName,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            _connectedEndpointId = id;
            _state = P2pState.connected;
            Nearby().stopAdvertising();
            notifyListeners();
          } else {
            _state = P2pState.disconnected;
            _errorMessage = "Gagal terhubung.";
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          _connectedEndpointId = null;
          _state = P2pState.disconnected;
          notifyListeners();
        },
        serviceId: "com.example.gesturlink",
      );

      if (!a) {
        _errorMessage = "Gagal memulai siaran (Advertising).";
        _state = P2pState.disconnected;
        notifyListeners();
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('8001')) {
        // 8001 = STATUS_ALREADY_ADVERTISING
        _state = P2pState.advertising;
      } else {
        _errorMessage = errorStr;
        _state = P2pState.disconnected;
      }
      notifyListeners();
    }
  }

  /// Starts the Controller mode (Discoverer)
  Future<void> startControllerMode() async {
    _role = P2pRole.controller;
    _state = P2pState.discovering;
    _errorMessage = null;
    notifyListeners();

    try {
      bool a = await Nearby().startDiscovery(
        _userName,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          // Otomatis request connection jika ketemu
          Nearby().requestConnection(
            _userName,
            id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: (id, status) {
              if (status == Status.CONNECTED) {
                _connectedEndpointId = id;
                _state = P2pState.connected;
                Nearby().stopDiscovery();
                notifyListeners();
              } else {
                _state = P2pState.disconnected;
                _errorMessage = "Gagal terhubung.";
                notifyListeners();
              }
            },
            onDisconnected: (id) {
              _connectedEndpointId = null;
              _state = P2pState.disconnected;
              notifyListeners();
            },
          );
        },
        onEndpointLost: (id) {},
        serviceId: "com.example.gesturlink",
      );

      if (!a) {
        _errorMessage = "Gagal memulai pemindaian (Discovery).";
        _state = P2pState.disconnected;
        notifyListeners();
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('8002')) {
        // 8002 = STATUS_ALREADY_DISCOVERING
        _state = P2pState.discovering;
      } else {
        _errorMessage = errorStr;
        _state = P2pState.disconnected;
      }
      notifyListeners();
    }
  }

  /// Connection Initiated Handler (Auto-Accept)
  void _onConnectionInitiated(String id, ConnectionInfo info) {
    _state = P2pState.connecting;
    notifyListeners();
    
    // Otomatis accept koneksi tanpa pin
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          String command = utf8.decode(payload.bytes!);
          _onCommandReceived(command);
        }
      },
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
    );
  }

  void _onCommandReceived(String command) {
    if (_role == P2pRole.receiver) {
      _actionLogs.insert(0, ActionLog(command: command, timestamp: DateTime.now()));
      if (_actionLogs.length > 50) {
        _actionLogs.removeLast();
      }
      notifyListeners();
    }
  }

  /// Simulasi perintah untuk pengetesan tanpa device kedua
  void simulateCommand(String command) {
    _actionLogs.insert(0, ActionLog(command: command, timestamp: DateTime.now()));
    if (_actionLogs.length > 50) {
      _actionLogs.removeLast();
    }
    notifyListeners();
  }

  Future<void> sendCommand(String command) async {
    if (_role == P2pRole.controller && _connectedEndpointId != null) {
      try {
        await Nearby().sendBytesPayload(_connectedEndpointId!, Uint8List.fromList(utf8.encode(command)));
        _commandsSent++;
        notifyListeners();
      } catch (e) {
        debugPrint("Error sending command: $e");
      }
    }
  }

  Future<void> stopAll() async {
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    await Nearby().stopAllEndpoints();
    _role = P2pRole.none;
    _state = P2pState.disconnected;
    _connectedEndpointId = null;
    notifyListeners();
  }
}

class ActionLog {
  final String command;
  final DateTime timestamp;

  ActionLog({required this.command, required this.timestamp});
}
