import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:developer';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class SerialQueueB64 {
  late final void Function(dynamic) onDecode;
  Uint8List _byteQueue = Uint8List(0);
  String _decodedString = "";

  SerialQueueB64(this.onDecode) {}

  /// push the byte sequences into the queue
  void push(Uint8List byteArr) {
    _byteQueue.addAll(byteArr.reversed);
  }

  /// static for decoding the b64 formatted float 
  /// only recept the 6-letter of ascii that is float, and has been b64 encoded.
  /// e.g : 
  static double base64DecodeFloat(String b64Floatter) {
    if (b64Floatter.length != 6) {
      throw Exception("base64DecodeFloat : param b64Floatter must be the length 6.");
    }

    b64Floatter = "${b64Floatter}AA";
    final b64Uint8List = ascii.encode(b64Floatter).reversed.toList();
    final b64ByteData = ByteData.sublistView(Uint8List.fromList(b64Uint8List), 2);

    return b64ByteData.getFloat32(0);

  }

  /// encode the double variable to the 8-digit ascii form.
  /// more precisely, it gets the 32bit float number, then gets the 
  /// 4 byte of data from it. then, convert them into the hex representation.
  static String floatDecodeToHex(double number) {
    final byteData = ByteData(4);
    byteData.setFloat32(0, number, Endian.little);
    var bytes = byteData.buffer.asUint8List();
    final toRadix = bytes.map((element) => element.toRadixString(16));

    String reversedRadix = "";
    toRadix.forEach((element) {
      reversedRadix = element + reversedRadix;
    });
    
    return reversedRadix;
  }

  /// interpret the last 3 byte then delete them from the queue.
  /// if possible, then call the purify function then return the result.
  void pop3() {
    if (_byteQueue.length < 3) {
      return;
    }

    final targetByte = _byteQueue.sublist(_byteQueue.length - 3);
    _byteQueue = _byteQueue.sublist(0, _byteQueue.length - 3);

    String interpreted = base64.encode(targetByte);
    _decodedString = _decodedString + interpreted.split('').reversed.join();

    final purifiedResult = purify();
    if (purifiedResult != null) {
      onDecode(purifiedResult);
    }
  }

  /// if decoded_string has the single reply, make that to the python list then return.
  /// if this list are actually representing float list, then convert it to the float.
  /// None if there are no reply at all.
  List<dynamic>? purify() {
    // find and remove the heading reply
    int firstSlashed = _decodedString.indexOf("//");
    if (firstSlashed == -1) {
      return null;
    }

    final exceptFirstString = _decodedString.substring(firstSlashed + 2);
    int secondSlashed = exceptFirstString.indexOf("//");
    if (secondSlashed == -1) {
      return null;
    }

    secondSlashed += firstSlashed + 2;
    final replySection = _decodedString.substring(firstSlashed + 2, secondSlashed);

    // slice the reply string
    final replyElement = replySection.split("++");
    if (replyElement.length <= 1) {
      _decodedString = _decodedString.substring(secondSlashed);
      return null;
    }

    replyElement.removeWhere((element) => element.isEmpty);

    bool isReplyElementsLengthAll6 = true;
    for (int i = 0; i < replyElement.length; i++) {
      if (replyElement[i].length != 6) {
        isReplyElementsLengthAll6 = false;
        break;
      }
    }
    List<dynamic> returned;
    if (isReplyElementsLengthAll6 == true) {
      returned = replyElement.map((element) => base64DecodeFloat(element)).toList();
    } else {
      returned = replyElement;
    }

    _decodedString = _decodedString.substring(secondSlashed);
    return returned;
  }


}

class BLEserial {
  // // serialized data queues for reading and writing
  // List<int> serialBufferQueue = [];
  // List<int> encodedBufferQueue = [];
  // List<int> replyNotify = [];
  // int encodedBuffer_endsignPos = 0;
  // late Function(List<dynamic>) replyNotifyCallback; // sign will be given by List<int>. can be null like []

  // ble state management booleans
  bool _deviceFounded = false;
  bool get deviceFounded => _deviceFounded;
  void Function(bool)? deviceFoundedCallback; // state will be given by bool
  bool _scanStarted = false;
  bool get scanStarted => _scanStarted;
  void Function(bool)? scanStartedCallback; // state will be given by bool
  bool _connected = false;
  bool get connected => _connected;
  void Function(bool)? connectedCallback; // state will be given by bool
  void Function(dynamic)? replyNotifyCallback;

  // flutter_reactive_ble objects
  late final StreamSubscription<DiscoveredDevice> _scanStreamSubscription; // scanning stream
  late final StreamSubscription<ConnectionStateUpdate> _connectivityStreamSubscription;
  late final StreamSubscription<List<int>> _notifyDataStreamSubscription;

  late final Stream<DiscoveredDevice> _scanStream; // scanning stream
  late final Stream<ConnectionStateUpdate> _connectivityStream;
  late final Stream<List<int>> _notifyDataStream;

  DiscoveredDevice? _ubiqueDevice; // device information object
  QualifiedCharacteristic? _rxCharacteristic; // characteristic object

  // UUIDs and informations of your targeted device
  late final Uuid _serviceUuid;
  late final Uuid _characteristicUuid;
  final String _targetedDeviceName;

  // all of functionalities are from this class, by flutter_reactive_ble package
  late FlutterReactiveBle flutterReactiveBle;

  BLEserial(String serviceUuidString, String characteristicUuidString, this._targetedDeviceName,
      {this.deviceFoundedCallback, this.scanStartedCallback, this.connectedCallback, required this.replyNotifyCallback}) {
    flutterReactiveBle = FlutterReactiveBle();

    _serviceUuid = Uuid.parse(serviceUuidString);
    _characteristicUuid = Uuid.parse(characteristicUuidString);
  }

  Future<void> dispose() async {
    await _scanStreamSubscription.cancel();
    await _connectivityStreamSubscription.cancel();
    await _notifyDataStreamSubscription.cancel();
  }

  void ble_debug() {
    final b64List = [80, 52, 52, 49, 80, 119]; // P441Pw
    final floater = 1.111;

    final toFloat = _b64DecodeFloat(b64List);
    final toB64 = _b64EncodeFloat(floater);

    log("$toB64, $toFloat");
  }

  /// b64DecodeFloat
  /// decode the length=6 b64-encoded List<int> param @b64 to a single float data
  /// by the floating point byte representation
  double _b64DecodeFloat(List<int> b64) {
    if (b64.length != 6) {
      throw Exception("b64 length must be 6.");
    }

    // add the ascii - notation "AA" then decode
    List<int> b64_ruled = List.from(b64);
    b64_ruled.add(65);
    b64_ruled.add(65);
    final b64String = ascii.decode(b64_ruled);
    var b64bytes = base64.decode(b64String);
    b64bytes = b64bytes.sublist(0, b64bytes.length - 2);

    // reverse the b64, cause the endian makes the problem. then convert to double form.
    final bytes = Uint8List.fromList(b64bytes);
    final byteData = ByteData.sublistView(bytes);
    double value = byteData.getFloat32(0);

    return value;
  }

  /// b64EncodeFloat
  /// encode the single float to a length=6 b64-encoded List<int> param data
  /// follows the floating point byte representation
  List<int> _b64EncodeFloat(double floater) {
    var byteData = ByteData(4);
    byteData.setFloat32(0, floater);
    final bytes = byteData.buffer.asUint8List();
    final b64bytes = ascii.encode(base64.encode(bytes));
    var result = List.from(b64bytes);
    result = result.sublist(0, result.length - 2);

    return List.from(result);
  }

  Future<void> startScan() async {
    bool permGranted = false;
    _scanStarted = true;

    // call the scan started callback.
    if (scanStartedCallback != null) {
      scanStartedCallback!(_scanStarted);
    }

    // grant the permision from user, then check if permissions have granted (or already been granted)
    if (Platform.isAndroid) {
      final List<Permission> statues = [
        Permission.locationWhenInUse,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth
      ];

      await statues.request();
      permGranted = true;

      final List<bool> isPermDenied = [];
      statues.forEach((state) async {
        final isDenied = await state.isDenied;
        isPermDenied.add(isDenied);
      });

      for (var state in isPermDenied) {
        if (state == false) {
          permGranted = false;
          break;
        }
      }
    } else if (Platform.isIOS) {
      // no IOS support currently possible.
      throw Exception("IOS permission for BLE not implemented yet.");
      permGranted = true;
    }

    // if granted, then start scanning the ble
    if (permGranted) {
      //assigning the scanning stream
      _scanStream = flutterReactiveBle.scanForDevices(withServices: []);
      _scanStreamSubscription = _scanStream.listen((device) {
        // check if searched device is matched for targeted device name.
        if (device.name == _targetedDeviceName) {
          // log(device.toString());
          _ubiqueDevice = device;
          _deviceFounded = true;
          if (deviceFoundedCallback != null) {
            deviceFoundedCallback!(_deviceFounded);
          }
        }
      });
    }
  }

  Future<void> connectToDevice() async {
    // check if device has been found and the scanning settled.
    if (_deviceFounded == false) {
      throw Exception(
          ["stringFormat.connectToDevice() : _deviceFounded is not true. please validate the param before call this function."]);
    } else if (_ubiqueDevice == null) {
      throw Exception("_ubiqueDevice is null!");
    }
    // shutting down the stream of scanning
    await _scanStreamSubscription.cancel();

    // open connection stream and get subscription
    _connectivityStream = flutterReactiveBle.connectToAdvertisingDevice(
        id: _ubiqueDevice!.id, prescanDuration: const Duration(seconds: 1), withServices: [_serviceUuid, _characteristicUuid]);
    _connectivityStreamSubscription = _connectivityStream.listen((event) {
      switch (event.connectionState) {
        // if connection settled, get the characteristic information.
        case DeviceConnectionState.connected:
          {
            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: _serviceUuid, characteristicId: _characteristicUuid, deviceId: _ubiqueDevice!.id);
            _deviceFounded = false;
            _connected = true;

            if (connectedCallback != null) {
              connectedCallback!(_connected);
            }
            break;
          }
        // if not settled, just break.
        case DeviceConnectionState.disconnected:
          {
            log("failed to connect.");
            break;
          }
        default:
      }
    });
  }

  void openReadStreamSample() {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    } else if (_rxCharacteristic == null) {
      throw Exception("_rxCharacteristic is Null!!");
    }
    // insert the action would be executed when data been notified.
    _notifyDataStream = flutterReactiveBle.subscribeToCharacteristic(_rxCharacteristic!);
    _notifyDataStreamSubscription = _notifyDataStream.listen((event) {
      log(event.toString());

      // event type is List<int>
      // send event to serialbuffer, turn serialbuffer's data to interpreted form, then send it to th encodedbuffer.
      serialBufferQueue = serialBufferQueue + event;
      int interpret_iter = serialBufferQueue.length;
      interpret_iter = ((interpret_iter - interpret_iter % 3) ~/ 3);
      for (int i = 0; i < interpret_iter; i++) {
        final popped_byte = serialBufferQueue.sublist(0, 3);
        final interpreted = base64.encode(popped_byte);
        final interpreted_list = ascii.encode(interpreted);
        encodedBufferQueue = encodedBufferQueue + interpreted_list;
        serialBufferQueue = serialBufferQueue.sublist(3);
      }

      // if encodedbuffer has "++//" then send it to custom function thread. then remembers the current "++//" position to save the computation resource
      final List<int> endmark = ascii.encode('++//');
      final List<int> startmark = ascii.encode('//');

      // log("encodedBufferQueue : ${ascii.decode(encodedBufferQueue)}"); //debug

      List<List<dynamic>> replyNotify_list = [];

      while (true) {
        // find the index where '++//' placed.
        late int endindex;
        if (encodedBuffer_endsignPos == 0) {
          endindex = findFirstSub(encodedBufferQueue, endmark);
        } else {
          endindex = findFirstSub(encodedBufferQueue.sublist(encodedBuffer_endsignPos), endmark);
        }

        // if endsign not found, stop iteration.
        if (endindex == -1) {
          // remember the length of encodedBufffer, to start from there later.
          encodedBuffer_endsignPos = encodedBufferQueue.length;
          break;
        }

        // if encodedBuffer_endsignPos non zero, add it.
        if (encodedBuffer_endsignPos != 0) {
          endindex += encodedBuffer_endsignPos;
        }

        // if found, put the command in the reply queue.
        final startindex = findFirstSub(encodedBufferQueue, startmark);
        final sign = lstrip(encodedBufferQueue.sublist(startindex + 2, endindex), 65); // strip the letter A

        //remove sign from encoded queue
        encodedBufferQueue = encodedBufferQueue.sublist(endindex + 4);
        encodedBuffer_endsignPos = 0;

        // process the sign, then push it to the reply list
        // split the sign by "++"
        var sign_str = ascii.decode(sign);
        final sign_splitted = sign_str.split("++");

        // if each part b64code length == 6 then regard it as float
        List<dynamic> reply = [];
        for (int i = 0; i < sign_splitted.length; i++) {
          final part = sign_splitted[i];
          if (part.length == 6) {
            try {
              reply.add(_b64DecodeFloat(ascii.encode(part)));
            } catch (e) {
              // log("???$e");
              reply.add(part);
            }
          } else {
            reply.add(part);
          }
        }
        // log("debug reply : $reply, $sign_str");
        replyNotify_list.add(reply);
      }

      // call the replyNotify callback.
      replyNotify_list.forEach(replyNotifyCallback);
    });
  }

  void writePing(Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    String foo = 'p';
    List<int> bytes = ascii.encode(foo);

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: bytes).then(call);
  }

  /// void writeEmit(Function(void) call)
  /// write "//e//" command, which send the sensor value only once.
  void writeEmit(Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    String foo = 'r';
    List<int> bytes = ascii.encode(foo);

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: bytes).then(call);
  }

  /// void writeSuperEmit(Function(void) call)
  /// write "//E//" command, which send the sensor value continuously.
  /// WARNING : this command makes other command not working except "//X//"
  void writeSuperEmit(Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    String foo = 'R';
    List<int> bytes = ascii.encode(foo);

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: bytes).then(call);
  }

  /// void writeStopSuperEmit(Function(void) call)
  /// write "//X//" command, which will make the "//E//" command stop.
  void writeStopSuperEmit(Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    String foo = 'X';
    List<int> bytes = ascii.encode(foo);

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: bytes).then(call);
  }
}

class DoubleTimeMassLoggerBLE extends BLEserial {
  DoubleTimeMassLoggerBLE(String serviceUuidString, String characteristicUuidString, String targetedDeviceName,
      {void Function(bool)? deviceFoundedCallback,
      void Function(bool)? scanStartedCallback,
      void Function(bool)? connectedCallback,
      required void Function(dynamic) replyNotifyCallback})
      : super(serviceUuidString, characteristicUuidString, targetedDeviceName,
            deviceFoundedCallback: deviceFoundedCallback,
            scanStartedCallback: scanStartedCallback,
            connectedCallback: scanStartedCallback,
            replyNotifyCallback: replyNotifyCallback);

  /// writeSave
  /// overwrite the current settings of BW chip's EEPROM data.
  void writeSave(double l0_div, double l0_off, double l1_div, double l1_off, double l2_div, double l2_off, Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    // convert params to the b64 format
    // also create the save command sending, "//S++<value0>++<value1>++… <value>++//"
    final param_list = [l0_div, l0_off, l1_div, l1_off, l2_div, l2_off];
    List<int> sending = List.from(ascii.encode("//S++"));
    final sepword = ascii.encode("++");
    final endword = ascii.encode("//");

    for (int i = 0; i < 6; i++) {
      final target = param_list[i];
      final encoded = _b64EncodeFloat(target);
      for (int j = 0; j < encoded.length; j++) {
        final letter = encoded[j];
        sending.add(letter);
      }
      sending = sending + sepword;
    }

    sending = sending + endword;

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: sending).then(call);
  }

  /// writeSaveCheck
  /// make BWchip reply the current settings of chip's EEPROM data.
  void writeSaveCheck(Function(void) call) {
    if (_connected == false || _rxCharacteristic == null) {
      throw Exception(
          ["stringFormat.connectToDevice() : _connected is not true. please validate the param before call this function."]);
    }

    String foo = '//s//';
    List<int> bytes = ascii.encode(foo);

    flutterReactiveBle.writeCharacteristicWithResponse(_rxCharacteristic!, value: bytes).then(call);
  }
}
