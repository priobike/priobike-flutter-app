import 'package:flutter/material.dart';

class GameIntroService with ChangeNotifier {
  bool _alreadyJoined = false;

  bool get alreadyJoined => _alreadyJoined;

  void joinGame() {
    _alreadyJoined = true;
    notifyListeners();
  }
}
