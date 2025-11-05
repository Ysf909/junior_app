import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:junior_app/view_model/localization_view_model.dart';

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return Provider.of<LocalizationViewModel>(this, listen: false).t(key);
  }
}
