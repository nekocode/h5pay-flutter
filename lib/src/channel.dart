import 'package:flutter/services.dart';

class Channel {
  static const _channel = const MethodChannel('h5pay');
  static const codeSuccess = 1;
  static const codeFail = 0;
  static const codeFailCantJump = -1;

  static Future<int> launch(String url, List<String> paymentSchemes) {
    return _channel.invokeMethod(
      'launch',
      <String, Object>{
        'paymentSchemes': paymentSchemes,
        'url': url,
      },
    );
  }
}
