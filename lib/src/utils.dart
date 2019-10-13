import 'package:flutter/foundation.dart';

class SimpleChangeNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
