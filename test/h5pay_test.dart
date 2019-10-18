import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h5pay/h5pay.dart';
import 'package:h5pay/src/channel.dart';

void main() {
  const MethodChannel channel = MethodChannel('h5pay');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      expect(methodCall.method, 'launch');
      await Future.delayed(Duration(seconds: 1));
      return Channel.codeSuccess;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  testWidgets('H5PayWidget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: H5PayWidget(
            paymentUrl: 'https://baidu.com',
            verifyResult: () async =>
                Future.delayed(Duration(milliseconds: 500), () => true),
            builder: (context, status, controller) {
              print('Current payment status: ' + status.toString());
              return FlatButton(
                onPressed: controller.launch,
                child: Text(status.toString()),
              );
            },
          ),
        ),
      ),
    );

    Finder findText(PaymentStatus status) => find.text(status.toString());
    void verifyStatus(PaymentStatus status) {
      expect(findText(status), findsOneWidget);
    }

    Future changeAppLifecycleState(AppLifecycleState state) async {
      return ServicesBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(state.toString()),
        (_) {},
      );
    }

    verifyStatus(PaymentStatus.idle);
    await tester.tap(findText(PaymentStatus.idle));
    await tester.pump();
    verifyStatus(PaymentStatus.gettingSchemeUrl);
    await tester.pump(new Duration(seconds: 1));
    verifyStatus(PaymentStatus.jumping);

    await changeAppLifecycleState(AppLifecycleState.inactive);
    await tester.pump();
    await changeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    verifyStatus(PaymentStatus.verifying);
    await tester.pump(new Duration(milliseconds: 500));
    verifyStatus(PaymentStatus.success);
    await tester.pump(new Duration(seconds: 5));
  });
}
