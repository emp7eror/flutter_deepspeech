import 'dart:async';

import 'package:flutter/services.dart';

class FlutterDeepSpeech {
  static const MethodChannel _channel =
      const MethodChannel('flutter_deepspeech');

  static const EventChannel _partialResults =
      const EventChannel('flutter_deepspeech_partial');

  static Stream<String> get partialResults =>
      _partialResults.receiveBroadcastStream().map((event) => event["result"]);

  static Future<void> init(
      String modelPath, int partialThreshold, String scorerPath) {
    return _channel.invokeMethod('init', {
      "model_path": modelPath,
      "partial_threshold": partialThreshold,
      "scorer_path": scorerPath
    });
  }

  static Future<void> start() {
    return _channel.invokeMethod('start');
  }

  static Future<String> finish() {
    return _channel.invokeMethod('finish');
  }
}
