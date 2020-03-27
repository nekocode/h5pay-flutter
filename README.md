# h5pay
[![build status](https://api.travis-ci.com/nekocode/h5pay-flutter.svg)](https://travis-ci.com/nekocode/h5pay-flutter)
[![pub package](https://img.shields.io/pub/v/h5pay.svg)](https://pub.dev/packages/h5pay)

A H5 payment (such as Alipay, WeChat Pay) plugin for flutter.

<kbd><img border="1" src="https://github.com/nekocode/h5pay-flutter/blob/master/image/screenshot.gif?raw=true"></img></kbd>

## Usage

Use the `showH5PayDialog` method to show a loading dialog and jump to payment app. When user switches from payment app back to your app, you can check payment result with your server in the `verifyResult` callback (Optional).

```dart
import 'package:h5pay/h5pay.dart';

final PaymentStatus status = await showH5PayDialog(
  context: context,
  // You can get payment url (normally is http or payment app scheme) from server in the getPaymentArguments callback
  getPaymentArguments: () async => PaymentArguments(
    url: 'https://is.gd/4cLE6j',
    redirectSchemes: ['alipay', 'alipays', 'weixin', 'wechat'],
  ),
  verifyResult: () async => true, // check order result with your server
);
if (status == PaymentStatus.success) {
  // Do something
}
```

Values of `PaymentStatus`:

```dart
enum PaymentStatus {
  idle,
  gettingArguments,
  getArgumentsFail,
  launchingUrl,
  cantLaunchUrl, // Maybe target payment app is not installed
  launchUrlTimeout, // Maybe redirecting url is fail
  jumping,
  jumpTimeout,
  verifying,
  success,
  fail,
}
```

### Notes

* In iOS, for allowing to jump to the payment app from your app, you must add schemes of the payment apps into the `Info.plist` file. Just like:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
	<string>wechat</string>
	<string>weixin</string>
	<string>alipay</string>
	<string>alipays</string>
</array>
```

### Advanced

If you have more complex requirements, you can use the `H5PayWidget`. Check the [example](example) for more detail.

