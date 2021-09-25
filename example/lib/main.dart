import 'package:flutter/material.dart';
import 'package:h5pay/h5pay.dart';

void main() => runApp(MaterialApp(home: IndexPage()));

class IndexPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example app'),
      ),
      body: Center(
        child: TextButton(
          child: Text('Plugin Test'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          },
        ),
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin Test'),
      ),
      body: MainBody(),
    );
  }
}

class MainBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          H5PayWidget(
            getPaymentArguments: () async => PaymentArguments(
              url: 'https://is.gd/4cLE6j',
              redirectSchemes: ['sms'],
              httpHeaders: {
                'referer': 'https://is.gd',
              },
            ),
            verifyResult: () async => true,
            builder: (context, status, controller) => TextButton(
              onPressed: status != PaymentStatus.gettingArguments &&
                      status != PaymentStatus.launchingUrl &&
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
          TextButton(
            onPressed: () async {
              final status = await showH5PayDialog(
                context: context,
                getPaymentArguments: () async => PaymentArguments(
                  url: 'https://is.gd/4cLE6j',
                  redirectSchemes: ['sms'],
                  httpHeaders: {
                    'referer': 'https://is.gd',
                  },
                ),
                verifyResult: () async => true,
              );
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
