import 'dart:async';

import 'package:flutter/widgets.dart';

import 'channel.dart';
import 'utils.dart';

enum PaymentStatus {
  idle,
  gettingSchemeUrl,
  getSchemeUrlTimeout,
  jumping,
  cantJump, // Maybe target payment app is not installed
  jumpTimeout,
  verifying,
  success,
  fail,
}

typedef Future<String> GetUrlCallback();
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
  H5PayWidget({
    Key key,
    List<String> paymentSchemes,
    Duration getSchemeUrlTimeout,
    Duration jumpTimeout,
    @required this.getH5Url,
    @required this.verifyResult,
    @required this.builder,
  })  : this.paymentSchemes =
            paymentSchemes ?? const ['alipay', 'alipays', 'weixin', 'wechat'],
        this.getSchemeUrlTimeout =
            getSchemeUrlTimeout ?? const Duration(seconds: 5),
        this.jumpTimeout = jumpTimeout ?? const Duration(seconds: 3),
        assert(getH5Url != null),
        assert(verifyResult != null),
        assert(builder != null),
        super(key: key) {
    assert(!this.getSchemeUrlTimeout.isNegative);
    assert(!this.jumpTimeout.isNegative);
  }

  final List<String> paymentSchemes;
  final Duration getSchemeUrlTimeout;
  final Duration jumpTimeout;
  final GetUrlCallback getH5Url;
  final VerifyResultCallback verifyResult;
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
    WidgetsBinding.instance.addObserver(this);
    _controller._launchNotifier.addListener(() async {
      setState(() {
        _status = PaymentStatus.gettingSchemeUrl;
      });

      PaymentStatus failStatus = await _launch();
      if (failStatus != null) {
        setState(() {
          _status = failStatus;
        });
        return;
      }

      // Start to listen app lifecycle
      _listenLifecycle = true;
      _jumped = false;
      setState(() {
        _status = PaymentStatus.jumping;
      });

      // Check if jump is successful
      failStatus = await _checkJump();
      if (failStatus != null) {
        // Jump failed
        _listenLifecycle = false;
        setState(() {
          _status = failStatus;
        });
        return;
      }
    });
  }

  @override
  void dispose() {
    _controller._dispose();
    WidgetsBinding.instance.removeObserver(this);
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

      setState(() {
        _status = PaymentStatus.verifying;
      });
      bool success;
      try {
        success = await widget.verifyResult();
      } catch (_) {
        success = false;
      }
      setState(() {
        _status = success == true ? PaymentStatus.success : PaymentStatus.fail;
      });
    }
  }

  Future<PaymentStatus> _launch() async {
    final url = await widget.getH5Url();
    if (url == null || url.isEmpty) {
      return PaymentStatus.fail;
    }

    final completer = Completer<PaymentStatus>();
    void completeOnce(PaymentStatus status) {
      if (!completer.isCompleted) {
        completer.complete(status);
      }
    }

    Channel.launch(url, widget.paymentSchemes).then((code) {
      PaymentStatus failStatus;
      switch (code) {
        case Channel.codeFailCantJump:
          failStatus = PaymentStatus.cantJump;
          break;
        case Channel.codeFail:
          failStatus = PaymentStatus.fail;
          break;
      }
      completeOnce(failStatus);

      //
    }).catchError((e) {
      debugPrint(e.toString());
      completeOnce(PaymentStatus.fail);
    });

    Future.delayed(widget.getSchemeUrlTimeout, () {
      completeOnce(PaymentStatus.getSchemeUrlTimeout);
    });

    return completer.future;
  }

  Future<PaymentStatus> _checkJump() async {
    final count =
        (widget.jumpTimeout.inMilliseconds / _checkJumpPeriod.inMilliseconds)
            .ceil();

    // Cycle check
    for (int i = 0; i < count; i++) {
      if (_jumped) {
        return null;
      }
      await Future.delayed(_checkJumpPeriod);
    }

    return PaymentStatus.jumpTimeout;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _status, _controller);
  }
}
