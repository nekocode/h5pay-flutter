import 'package:flutter/services.dart';

class H5PayChannel {
  static const _channel = const MethodChannel('h5pay');
  static const codeSuccess = 1;
  static const codeFail = 0;
  static const codeFailCantJump = -1;

  static Future<int> launchPaymentUrl(String url, List<String> paymentSchemes) {
    return _channel.invokeMethod(
      'launchPaymentUrl',
      <String, Object>{
        'paymentSchemes': paymentSchemes,
        'url': url,
      },
    );
  }

  static Future<bool> launchUrl(String url) {
    return _channel.invokeMethod(
      'launchUrl',
      <String, Object>{
        'url': url,
      },
    );
  }

  static Future<bool> canLaunch(String url) {
    return _channel.invokeMethod(
      'canLaunch',
      <String, Object>{
        'url': url,
      },
    );
  }
}
