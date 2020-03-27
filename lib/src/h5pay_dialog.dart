import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'h5pay_widget.dart';

Future<PaymentStatus> showH5PayDialog({
  @required BuildContext context,
  @required GetArgumentsCallback getPaymentArguments,
  VerifyResultCallback verifyResult,
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
              getPaymentArguments: getPaymentArguments,
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
    @required this.getPaymentArguments,
    this.verifyResult,
    WidgetBuilder builder,
  })  : this.builder = builder ?? _buildSimpleDialog,
        assert(getPaymentArguments != null),
        super(key: key);

  final GetArgumentsCallback getPaymentArguments;
  final VerifyResultCallback verifyResult;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return H5PayWidget(
      getPaymentArguments: getPaymentArguments,
      verifyResult: verifyResult,
      builder: (context, status, controller) {
        switch (status) {
          case PaymentStatus.idle:
            controller.launch();
            break;
          case PaymentStatus.gettingArguments:
          case PaymentStatus.launchingUrl:
          case PaymentStatus.jumping:
          case PaymentStatus.verifying:
            break;
          case PaymentStatus.getArgumentsFail:
          case PaymentStatus.cantLaunchUrl:
          case PaymentStatus.launchUrlTimeout:
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
