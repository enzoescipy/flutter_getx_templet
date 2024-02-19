import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'controller/BLEserial.dart';
import 'modules/list.dart';

void main() {
  return runApp(
    const MaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // pre-calibrated value (simple calibration)
  double common_divide = 1 / 0.000034597298466976;
  double common_offset = 50.0;
  // calibration stage parameterszd
  int _BWCalibrationStageNum = 0;
  double _zeroWeightValue = 0.0;
  double _fullWeightUserValue = 0.0;
  double _fullWeightValue = 0.0;

  // replyQueue will receieve the command's replies
  List<List<dynamic>> replyQueue = [];
  List<void Function()> replyAction = [];

  // BLESerial object
  late DoubleTimeMassLoggerBLE bleSerial;

  // showing the newest 5 replyQueue items, function.
  String currentReplyQueue() {
    String result = "";
    List<List<dynamic>> replyQueueCopied = replyQueue;
    if (replyQueue.length > 4) {
      replyQueueCopied = replyQueueCopied.sublist(replyQueueCopied.length - 5, replyQueueCopied.length);
    }
    for (int i = 0; i < replyQueueCopied.length; i++) {
      var targetList = replyQueueCopied[i];
      var targetListString = "";
      targetList.forEach((element) {
        targetListString += element.toString() + ",";
      });
      result += targetListString + "\n";
    }

    // show the number of list and number of action
    result += "\n" + replyQueue.length.toString() + "  :  " + replyAction.length.toString();

    return result;
    // return "hello, world!\nhello, world!!"; // debug
  }

  //initState override
  @override
  void initState() {
    void deviceFoundedCall(bool state) {setState(() {
      
    });}

    void scanStartedCall(bool state) {setState(() {
      
    });}

    void connectedCall(bool state) {setState(() {
      
    });}

    void replyCall(dynamic sign) {
      // setState(() {
      //   replyQueue = replyQueue + [sign];
      //   // log("reply : $replyQueue");
      // });
      // replyAction.forEach((element) {
      //   element();
      // });
    }

    bleSerial = DoubleTimeMassLoggerBLE(
        "0000ffe0-0000-1000-8000-00805f9b34fb", "0000ffe1-0000-1000-8000-00805f9b34fb", '=Brewing_halo_01',
        deviceFoundedCallback: deviceFoundedCall,
        scanStartedCallback: scanStartedCall,
        connectedCallback: connectedCall,
        replyNotifyCallback: replyCall);

    //debug
    // list_debug();
    // bleSerial.ble_debug();
    //debug

    super.initState();
  }

  Widget CompansateBrewHaloElevatedButton() {
    if (bleSerial.connected == false) {
      // before connection
      // log("CompansateBrewHaloElevatedButton : before connection");
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.grey, // background
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {},
        child: const Text("compensate\nBrewingHalo"),
      );
    }
    if (_BWCalibrationStageNum == 0) {
      // return just same activated button
      log("conCompansateBrewHaloElevatedButton : $_BWCalibrationStageNum");
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue, // background
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {
          setState(() {
            _BWCalibrationStageNum++;
          });
        },
        child: const Text("compensate\nBrewingHalo"),
      );
    } else if (_BWCalibrationStageNum == 1) {
      // returns the guide for the first calibration stage, which would have to put the zero weight
      log("conCompansateBrewHaloElevatedButton : $_BWCalibrationStageNum");
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue, // background
          onPrimary: Colors.white, // foreground
        ),
        onPressed: () {
          setState(() {
            _BWCalibrationStageNum++;
            replyAction.add(() {
              setState(() {
                log("_zeroWeightValue calculated.");
                _zeroWeightValue = replyQueue[replyQueue.length - 1]
                    .getRange(3, 5)
                    .reduce((value, element) => value + element); // sum of three sensors
              });
            });
          });
          bleSerial.writeEmit((x) {
            log("writeEmit fired. (0)");
          });
        },
        child: const Text("Stage 1\nPut the zero weight"),
      );
    } else if (_BWCalibrationStageNum == 2) {
      // returns the button + inputText that guide user to put the standard weight on the pruduct.
      log("conCompansateBrewHaloElevatedButton : $_BWCalibrationStageNum");
      return SizedBox(
          width: 200,
          child: TextField(
            decoration:
                const InputDecoration(labelText: "standard weight (g) : ", contentPadding: EdgeInsets.symmetric(vertical: 40.0)),
            onSubmitted: (str) {
              setState(() {
                _fullWeightUserValue = double.parse(str);
                _BWCalibrationStageNum++;
                replyAction.clear();
                replyAction.add(() {
                  setState(() {
                    log("_fullWeightValue calculated.");
                    _fullWeightValue = replyQueue[replyQueue.length - 1]
                        .getRange(3, 5)
                        .reduce((value, element) => value + element); // sum of three sensors
                  });
                });
              });
              bleSerial.writeEmit((x) => {log("writeEmit fired. (1)")});
            },
          ));
    } else if (_BWCalibrationStageNum == 3) {
      // log("conCompansateBrewHaloElevatedButton : $_BWCalibrationStageNum");

      // debug code that check the _zeroWeightValue, _fullWeightValue, _fullWeightUserValue
      // log("_zeroWeightValue : $_zeroWeightValue");
      // log("_fullWeightValue : $_fullWeightValue");
      // log("_fullWeightUserValue : $_fullWeightUserValue");
      //debug

      bleSerial.writeSaveCheck((p0) => null);
      setState(() {
        replyAction.clear();
        replyAction.add(() {
          log("device-dedicated compensation value receieved.");
          final new_div = _fullWeightUserValue / (_fullWeightValue - _zeroWeightValue);
          final new_off = -new_div * _zeroWeightValue;
          log("$new_div, $new_off");
          bleSerial.writeSave(new_div, new_off / 3, new_div, new_off / 3, new_div, new_off / 3, (p0) {
            setState(() {
              log("_BWCalibrationStageNum == 3 writeSave setState completed.");
              replyAction.clear();
            });
          });
        });
        _BWCalibrationStageNum = 0;
      });
      // return CompansateBrewHaloElevatedButton();
      return Text("terminate");
    } else {
      log("conCompansateBrewHaloElevatedButton : $_BWCalibrationStageNum");
      return Text("ERR");
    }
  }

  @override
  void dispose() async {
    await bleSerial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // currentReplyQueue() return text
          Text(currentReplyQueue()),
          // command buttons
          Row(
            children: [
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () => bleSerial.writeSave(common_divide, common_offset / 3, common_divide, common_offset / 3,
                          common_divide, common_offset / 3, (x) => {log("writeSave test fired.")}),
                      // onPressed: () => bleSerial.writeSave(1.11, 2.22, 3.33, 4.44, 5.55, 6.66, (x) => {log("writeSave fired.")}) ,
                      child: const Text("Save"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("Save"),
                    ),
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () => bleSerial.writeSaveCheck((x) => {log("writeSaveCheck fired.")}),
                      // onPressed: () => bleSerial.writeSave(1.11, 2.22, 3.33, 4.44, 5.55, 6.66, (x) => {log("writeSave fired.")}) ,
                      child: const Text("saveCheck"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("saveCheck"),
                    ),
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () => bleSerial.writeEmit((x) => {log("writeEmit fired.")}),
                      // onPressed: () => bleSerial.writeSave(1.11, 2.22, 3.33, 4.44, 5.55, 6.66, (x) => {log("writeSave fired.")}) ,
                      child: const Text("emit"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("emit"),
                    ),
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () => bleSerial.writeSuperEmit((x) => {log("writeSuperEmit fired.")}),
                      // onPressed: () => bleSerial.writeSave(1.11, 2.22, 3.33, 4.44, 5.55, 6.66, (x) => {log("writeSave fired.")}) ,
                      child: const Text("EMIT"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("EMIT"),
                    ),
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () => bleSerial.writeStopSuperEmit((x) => {log("writeStopSuperEmit fired.")}),
                      // onPressed: () => bleSerial.writeSave(1.11, 2.22, 3.33, 4.44, 5.55, 6.66, (x) => {log("writeSave fired.")}) ,
                      child: const Text("EMIT STOP"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("EMIT STOP"),
                    ),
            ],
          ),
          Row(
            children: [
              // True condition
              CompansateBrewHaloElevatedButton(),
              bleSerial.connected
                  // True condition
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {
                        setState(() {
                          replyQueue = [];
                          replyAction = [];
                        });
                      },
                      child: const Text("flush"),
                    )
                  // False condition
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey, // background
                        onPrimary: Colors.white, // foreground
                      ),
                      onPressed: () {},
                      child: const Text("flush"),
                    ),
            ],
          )
        ],
      ),
      persistentFooterButtons: [
        // We want to enable this button if the scan has NOT started
        // If the scan HAS started, it should be disabled.
        bleSerial.scanStarted
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.search),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: bleSerial.startScan,
                child: const Icon(Icons.search),
              ),
        bleSerial.deviceFounded
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: bleSerial.connectToDevice,
                child: const Icon(Icons.bluetooth),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.bluetooth),
              ),
        bleSerial.connected
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: bleSerial.openReadStreamSample,
                child: const Icon(Icons.add_call),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.add_call),
              ),
      ],
    );
  }
}
