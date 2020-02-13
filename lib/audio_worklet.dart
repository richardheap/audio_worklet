import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class AudioWorklet {
  static const _channel = const MethodChannel('audio_worklet');

  static AWEvents _handler;

  static setEventHandler(AWEvents handler) {
    _channel.setMethodCallHandler(nativeHandler);
    _handler = handler;
  }

  static Future<int> get nativeRate async {
    return await _channel.invokeMethod('nativeRate');
  }

  static void start(int sampleRate) {
    _channel.invokeMethod('start', {
      'rate': sampleRate,
    });
  }

  static void stop() {
    _channel.invokeMethod('stop');
  }

  static Future<dynamic> nativeHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'getAudio':
        return _handler?.getAudio();
      default:
        throw MissingPluginException('notImplemented');
    }
  }
}

abstract class AWEvents {
  Float64List getAudio();
}
