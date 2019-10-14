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
        body: MainPage(),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          H5PayWidget(
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
          SizedBox(height: 10),
          FlatButton(
            textColor: Colors.white,
            color: Colors.blue,
            onPressed: () async {
              final status = await showH5PayDialog(
                context: context,
                paymentSchemes: ['sms'],
                getH5Url: () async => 'https://is.gd/4cLE6j',
                verifyResult: () async => false,
              );
              Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(status.toString()),
              ));
            },
            child: Text('showH5PayDialog'),
          ),
        ],
      ),
    );
  }
}
