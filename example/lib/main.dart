import 'package:flutter/material.dart';
import 'package:h5pay/h5pay.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('H5Pay plugin example app'),
        ),
        body: Center(
          child: H5PayWidget(
            paymentSchemes: ['sms'],
            getH5Url: () async => 'https://is.gd/4cLE6j',
            verifyResult: () async => true,
            builder: (context, status, controller) => FlatButton(
              textColor: Colors.white,
              color: Colors.blue,
              onPressed: status != PaymentStatus.gettingSchemeUrl &&
                      status != PaymentStatus.jumping &&
                      status != PaymentStatus.verifying
                  ? () async {
                      controller.launch();
                    }
                  : null,
              child: Text(status.toString()),
            ),
          ),
        ),
      ),
    );
  }
}
