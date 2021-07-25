import 'package:flutter/services.dart';

class H5PayChannel {
  static const _channel = const MethodChannel('h5pay');

  static Future<bool?> launchRedirectUrl(String url, List<String> targetSchemes) {
    return _channel.invokeMethod(
      'launchRedirectUrl',
      <String, Object>{
        'targetSchemes': targetSchemes,
        'url': url,
      },
    );
  }

  static Future<bool?> launchUrl(String url) {
    return _channel.invokeMethod(
      'launchUrl',
      <String, Object>{
        'url': url,
      },
    );
  }

  static Future<bool?> canLaunch(String url) {
    return _channel.invokeMethod(
      'canLaunch',
      <String, Object>{
        'url': url,
      },
    );
  }
}
