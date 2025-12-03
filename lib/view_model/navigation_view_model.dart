// lib/view_models/navigation_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/src/material/app.dart';

enum AppScreen {
  timer,
  listView,
  gallery,
  network, location,
  ChatPage,
}

class NavigationViewModel with ChangeNotifier {
  AppScreen _currentScreen = AppScreen.timer;
  String _screenTitle = 'Timer';

  AppScreen get currentScreen => _currentScreen;
  String get screenTitle => _screenTitle;

  void navigateTo(AppScreen screen) {
    _currentScreen = screen;
    _updateScreenTitle();
    notifyListeners();
  }

  void _updateScreenTitle() {
    switch (_currentScreen) {
      case AppScreen.timer:
        _screenTitle = 'Timer';
        break;
      case AppScreen.listView:
        _screenTitle = 'List View';
        break;
      case AppScreen.gallery:
        _screenTitle = 'Gallery';
        break;
      case AppScreen.network:
        _screenTitle = 'Network Service';
        break;
      case AppScreen.location:
        _screenTitle = 'Location';
        break;
      case AppScreen.ChatPage:
        _screenTitle = 'Chat';
        break;
    }
  }

  bool get isTimerScreen => _currentScreen == AppScreen.timer;

  void updateTheme(ThemeMode newTheme) {}
}