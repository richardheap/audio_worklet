import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_worklet/audio_worklet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements AWEvents {
  int _nativeRate = -1;
  Float64List buffer;

  @override
  void initState() {
    super.initState();
    AudioWorklet.setEventHandler(this);
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var rate = 0;

    try {
      rate = await AudioWorklet.nativeRate;
    } on PlatformException {
      rate = -1;
    }

    if (rate > 0) {
      buffer = Float64List(rate ~/ 10);
      for (var i = 0; i < buffer.length; i++) {
        buffer[i] = sin(2000 * pi * i / rate);
      }
    }

    if (!mounted) return;

    setState(() {
      _nativeRate = rate;
    });
  }

  @override
  Float64List getAudio() => buffer;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Worklet Example App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Native rate is $_nativeRate'),
              RaisedButton(
                child: Text('Start'),
                onPressed: () => AudioWorklet.start(_nativeRate),
              ),
              RaisedButton(
                child: Text('Stop'),
                onPressed: () => AudioWorklet.stop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
