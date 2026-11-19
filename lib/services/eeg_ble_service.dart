import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/eeg_packet.dart';
import 'muse_decoder.dart';

class EegBleService {
  // Muse 2 UUID Constants
  static const String museServiceUuid = "0000fe8d-0000-1000-8000-00805f9b34fb";
  static const String controlCharUuid = "273e0001-4c4d-454d-96be-f03bac821358";
  static const String tp9CharUuid = "273e0003-4c4d-454d-96be-f03bac821358";
  static const String af7CharUuid = "273e0004-4c4d-454d-96be-f03bac821358";
  static const String af8CharUuid = "273e0005-4c4d-454d-96be-f03bac821358";
  static const String tp10CharUuid = "273e0006-4c4d-454d-96be-f03bac821358";
  static const String auxCharUuid = "273e0007-4c4d-454d-96be-f03bac821358";

  BluetoothDevice? _connectedDevice;
  final List<StreamSubscription> _subscriptions = [];

  final StreamController<EegSample> _sampleStreamController =
      StreamController<EegSample>.broadcast();

  Stream<EegSample> get sampleStream => _sampleStreamController.stream;

  // Cached latest channel values for reconstruction
  double _lastTp9 = 0.0;
  double _lastAf7 = 0.0;
  double _lastAf8 = 0.0;
  double _lastTp10 = 0.0;
  double _lastAux = 0.0;

  bool get isConnected => _connectedDevice != null;

  /// Check and request necessary Bluetooth and Location permissions.
  Future<bool> checkAndRequestPermissions() async {
    if (kIsWeb) return true;

    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final locationStatus = await Permission.locationWhenInUse.request();

    return (scanStatus.isGranted || scanStatus.isLimited) &&
        (connectStatus.isGranted || connectStatus.isLimited) &&
        (locationStatus.isGranted || locationStatus.isLimited);
  }

  /// Scan for nearby Muse headband devices.
  Future<BluetoothDevice?> findMuseDevice({Duration timeout = const Duration(seconds: 8)}) async {
    final hasPerms = await checkAndRequestPermissions();
    if (!hasPerms) {
      throw Exception("Bluetooth permissions were denied");
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception("Bluetooth is powered off. Please enable Bluetooth.");
    }

    BluetoothDevice? foundDevice;
    final completer = Completer<BluetoothDevice?>();

    StreamSubscription? scanSub;
    scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName.toLowerCase();
        final advName = r.advertisementData.advName.toLowerCase();

        if (name.contains("muse") || advName.contains("muse")) {
          foundDevice = r.device;
          FlutterBluePlus.stopScan();
          if (!completer.isCompleted) {
            completer.complete(foundDevice);
          }
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: [Guid(museServiceUuid)],
    );

    Future.delayed(timeout, () {
      if (!completer.isCompleted) {
        FlutterBluePlus.stopScan();
        completer.complete(foundDevice);
      }
    });

    final result = await completer.future;
    await scanSub.cancel();
    return result;
  }

  /// Connect to the specified Muse headband and subscribe to EEG channels.
  Future<void> connect(BluetoothDevice device) async {
    await disconnect();

    _connectedDevice = device;
    await device.connect(autoConnect: false, timeout: const Duration(seconds: 12));

    try {
      // Discover services
      final services = await device.discoverServices();
      BluetoothCharacteristic? controlChar;

      for (final service in services) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();

          if (uuid.contains("273e0001")) {
            controlChar = char;
          } else if (uuid.contains("273e0003")) {
            await _subscribeChannel(char, (v) => _lastTp9 = v);
          } else if (uuid.contains("273e0004")) {
            await _subscribeChannel(char, (v) => _lastAf7 = v);
          } else if (uuid.contains("273e0005")) {
            await _subscribeChannel(char, (v) => _lastAf8 = v);
          } else if (uuid.contains("273e0006")) {
            await _subscribeChannel(char, (v) => _lastTp10 = v);
          } else if (uuid.contains("273e0007")) {
            await _subscribeChannel(char, (v) => _lastAux = v);
          }
        }
      }

      // Start streaming by writing command 's\n' to control characteristic
      if (controlChar != null) {
        // [0x02, 0x64, 0x0a] -> 'd\n' (handshake) then 's\n' (start)
        try {
          await controlChar.write([0x02, 0x64, 0x0a], withoutResponse: false);
          await Future.delayed(const Duration(milliseconds: 100));
          await controlChar.write([0x02, 0x73, 0x0a], withoutResponse: false);
        } catch (e) {
          debugPrint("Note: Control write response: $e");
        }
      }
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  Future<void> _subscribeChannel(
    BluetoothCharacteristic characteristic,
    Function(double) onValue,
  ) async {
    await characteristic.setNotifyValue(true);
    final sub = characteristic.onValueReceived.listen((data) {
      final samples = MusePacketDecoder.decodeChannelPacket(data);
      if (samples.isNotEmpty) {
        for (final s in samples) {
          onValue(s);
        }
        // Emit combined 5-channel EEG sample
        _sampleStreamController.add(
          EegSample(
            timestamp: DateTime.now(),
            tp9: _lastTp9,
            af7: _lastAf7,
            af8: _lastAf8,
            tp10: _lastTp10,
            aux: _lastAux,
          ),
        );
      }
    });
    _subscriptions.add(sub);
  }

  /// Disconnect and release resources.
  Future<void> disconnect() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
  }

  void dispose() {
    disconnect();
    _sampleStreamController.close();
  }
}
