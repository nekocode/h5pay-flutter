import 'dart:async';

import 'package:flutter/widgets.dart';

import 'h5pay_channel.dart';
import 'utils.dart';

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

class PaymentArguments {
  // Payment url (can be http or any other protocol)
  final String url;

  // If scheme of the 'url' argument is 'http' and this argument is not null,
  // then this library will launch the url in a hidden webview, catch the
  // redirect url which has the scheme you specified, and finally launch
  // the new url by using the system api.
  //
  // You can leave this argument to null to launch the url by using
  // the system api directly.
  final List<String>? redirectSchemes;

  // Additional http headers for webview
  final Map<String, String>? httpHeaders;

  // Timeout duration of jumping to payment app (or system browser)
  final Duration jumpTimeout;

  // Timeout duration of launching url
  final Duration launchUrlTimeout;

  PaymentArguments({
    required this.url,
    this.redirectSchemes,
    this.httpHeaders,
    Duration? jumpTimeout,
    Duration? launchUrlTimeout,
  })  : assert(url.isNotEmpty),
        assert(jumpTimeout == null || !jumpTimeout.isNegative),
        assert(launchUrlTimeout == null || !launchUrlTimeout.isNegative),
        this.jumpTimeout = jumpTimeout ?? const Duration(seconds: 3),
        this.launchUrlTimeout = launchUrlTimeout ?? const Duration(seconds: 5);
}

typedef Future<PaymentArguments> GetArgumentsCallback();
typedef Future<bool> VerifyResultCallback();
typedef Widget H5PayWidgetBuilder(
  BuildContext context,
  PaymentStatus status,
  H5PayController controller,
);

class H5PayController {
  final _launchNotifier = SimpleChangeNotifier();

  void launch() {
    _launchNotifier.notify();
  }

  void _dispose() {
    _launchNotifier.dispose();
  }
}

class H5PayWidget extends StatefulWidget {
  const H5PayWidget({
    Key? key,
    required this.getPaymentArguments,
    required this.builder,
    this.verifyResult,
  }) : super(key: key);

  final GetArgumentsCallback getPaymentArguments;
  final VerifyResultCallback? verifyResult;
  final H5PayWidgetBuilder builder;

  @override
  _H5PayWidgetState createState() => _H5PayWidgetState();
}

class _H5PayWidgetState extends State<H5PayWidget> with WidgetsBindingObserver {
  static const _checkJumpPeriod = Duration(milliseconds: 100);
  final _controller = H5PayController();

  PaymentStatus _status = PaymentStatus.idle;
  bool _listenLifecycle = false;
  bool _jumped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    _controller._launchNotifier.addListener(() async {
      // Start to get payment arguments
      _setPaymentStatus(PaymentStatus.gettingArguments);
      PaymentArguments args;
      try {
        args = await widget.getPaymentArguments();
      } catch (_) {
        _setPaymentStatus(PaymentStatus.getArgumentsFail);
        return;
      }
      if (!mounted) {
        return;
      }

      // Start to launch url
      _setPaymentStatus(PaymentStatus.launchingUrl);
      var failStatus = await _launch(args);
      if (!mounted) {
        return;
      }
      if (failStatus != null) {
        _setPaymentStatus(failStatus);
        return;
      }

      // Start to listen app lifecycle
      _listenLifecycle = true;
      _jumped = false;
      _setPaymentStatus(PaymentStatus.jumping);

      // Check if jump is successful
      failStatus = await _checkJump(args);
      if (!mounted) {
        return;
      }
      if (failStatus != null) {
        // Jump failed
        _listenLifecycle = false;
        _setPaymentStatus(failStatus);
        return;
      }
    });
  }

  @override
  void dispose() {
    _controller._dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_listenLifecycle) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Start to jump to payment app
      _jumped = true;
    } else if (state == AppLifecycleState.resumed) {
      // Resume from payment app
      _listenLifecycle = false;

      bool success = true;
      // Try to verify the payment result
      final verifyResult = widget.verifyResult;
      if (verifyResult != null) {
        _setPaymentStatus(PaymentStatus.verifying);
        try {
          success = await verifyResult();
        } catch (_) {
          success = false;
        }
      }

      _setPaymentStatus(
          success == true ? PaymentStatus.success : PaymentStatus.fail);
    }
  }

  Future<PaymentStatus?> _launch(PaymentArguments args) async {
    final completer = Completer<PaymentStatus?>();
    void completeOnce(PaymentStatus? status) {
      if (!completer.isCompleted) {
        completer.complete(status);
      }
    }

    final redirectSchemes = args.redirectSchemes;
    if (redirectSchemes != null) {
      H5PayChannel.launchRedirectUrl(
        args.url,
        redirectSchemes,
        httpHeaders: args.httpHeaders,
      ).then((success) {
        if (success == true) {
          completeOnce(null);
        } else {
          completeOnce(PaymentStatus.cantLaunchUrl);
        }
      }).catchError((e) {
        debugPrint(e.toString());
        completeOnce(PaymentStatus.fail);
      });
    } else {
      H5PayChannel.launchUrl(args.url).then((success) {
        if (success == true) {
          completeOnce(null);
        } else {
          completeOnce(PaymentStatus.cantLaunchUrl);
        }
      }).catchError((e) {
        debugPrint(e.toString());
        completeOnce(PaymentStatus.fail);
      });
    }

    Future.delayed(args.launchUrlTimeout, () {
      completeOnce(PaymentStatus.launchUrlTimeout);
    });

    return completer.future;
  }

  Future<PaymentStatus?> _checkJump(PaymentArguments args) async {
    final count =
        (args.jumpTimeout.inMilliseconds / _checkJumpPeriod.inMilliseconds)
            .ceil();

    // Cycle check
    for (int i = 0; i < count; i++) {
      if (_jumped || !mounted) {
        return null;
      }
      await Future.delayed(_checkJumpPeriod);
    }

    return PaymentStatus.jumpTimeout;
  }

  void _setPaymentStatus(PaymentStatus status) {
    _status = status;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _status, _controller);
  }
}
