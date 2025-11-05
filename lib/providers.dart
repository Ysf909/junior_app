// providers.dart
import 'package:junior_app/view_model/navigation_view_model.dart';
import 'package:provider/provider.dart';
import 'package:junior_app/view_model/login_view_model.dart';
import 'package:junior_app/view_model/signup_view_model.dart';

class AppProviders {
  static final providers = [
    ChangeNotifierProvider(create: (context) => LoginViewModel()),
    ChangeNotifierProvider(create: (context) => SignupViewModel()),
    ChangeNotifierProvider(create: (context) => NavigationViewModel()),
  ];
}
