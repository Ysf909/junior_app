// lib/services/localization_service.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocalizationService {
  // 1) singleton
  LocalizationService._internal();
  static final LocalizationService instance = LocalizationService._internal();

  // 2) data storage
  Map<String, dynamic> _localizedStrings = {};

  Map<String, dynamic> get data => _localizedStrings;

  // 3) the method your ViewModel is calling
  Future<void> load(String langCode) async {
    // this MUST match your pubspec.yaml
    // you have: assets/translations/
    final path = 'assets/translations/$langCode.json';

    final jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap;
  }

  // optional helper
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
