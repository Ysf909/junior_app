// lib/view_model/localization_view_model.dart
import 'package:flutter/material.dart';
import 'package:junior_app/services/localization_service.dart';

class LocalizationViewModel extends ChangeNotifier {
  final LocalizationService _service = LocalizationService.instance;

  String _currentLang = 'en';
  String get currentLang => _currentLang;

  Locale get locale => Locale(_currentLang);

  Map<String, dynamic> get strings => _service.data;

  Future<void> init() async {
    await _service.load(_currentLang);
    notifyListeners();
  }

  Future<void> changeLanguage(String langCode) async {
    _currentLang = langCode;
    await _service.load(langCode);
    notifyListeners();
  }

  String t(String key) {
    return _service.translate(key);
  }
}
