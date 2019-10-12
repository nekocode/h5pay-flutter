import 'dart:async';

import 'package:flutter/services.dart';

class H5pay {
  static const MethodChannel _channel =
      const MethodChannel('h5pay');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
