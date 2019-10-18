import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'h5pay_widget.dart';

Future<PaymentStatus> showH5PayDialog({
  @required BuildContext context,
  List<String> paymentSchemes,
  Duration getPaymentUrlTimeout,
  Duration jumpTimeout,
  @required GetUrlCallback getPaymentUrl,
  @required VerifyResultCallback verifyResult,
  WidgetBuilder builder,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (
      BuildContext buildContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return WillPopScope(
        onWillPop: () async => false,
        child: SafeArea(
          child: Builder(builder: (BuildContext context) {
            return _H5PayDialog(
              paymentSchemes: paymentSchemes,
              getPaymentUrlTimeout: getPaymentUrlTimeout,
              jumpTimeout: jumpTimeout,
              getPaymentUrl: getPaymentUrl,
              verifyResult: verifyResult,
              builder: builder,
            );
          }),
        ),
      );
    },
  );
}

class _H5PayDialog extends StatelessWidget {
  _H5PayDialog({
    Key key,
    this.paymentSchemes,
    this.getPaymentUrlTimeout,
    this.jumpTimeout,
    @required this.getPaymentUrl,
    @required this.verifyResult,
    WidgetBuilder builder,
  })  : this.builder = _buildSimpleDialog,
        assert(getPaymentUrl != null),
        assert(verifyResult != null),
        super(key: key);

  final List<String> paymentSchemes;
  final Duration getPaymentUrlTimeout;
  final Duration jumpTimeout;
  final GetUrlCallback getPaymentUrl;
  final VerifyResultCallback verifyResult;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return H5PayWidget(
      paymentSchemes: paymentSchemes,
      getPaymentUrlTimeout: getPaymentUrlTimeout,
      jumpTimeout: jumpTimeout,
      getPaymentUrl: getPaymentUrl,
      verifyResult: verifyResult,
      builder: (context, status, controller) {
        switch (status) {
          case PaymentStatus.idle:
            controller.launch();
            break;
          case PaymentStatus.gettingPaymentUrl:
          case PaymentStatus.jumping:
          case PaymentStatus.verifying:
            break;
          case PaymentStatus.getPaymentUrlTimeout:
          case PaymentStatus.cantJump:
          case PaymentStatus.jumpTimeout:
          case PaymentStatus.success:
          case PaymentStatus.fail:
            // Pop dialog with result
            Future.microtask(() {
              Navigator.pop(context, status);
            });
            break;
        }

        return builder(context);
      },
    );
  }

  static Widget _buildSimpleDialog(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}
