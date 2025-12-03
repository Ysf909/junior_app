import 'package:flutter/material.dart';
import 'package:junior_app/view_model/location_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// PAGES
import 'package:junior_app/view/pages/cloud_page.dart';
import 'package:junior_app/view/pages/login_view.dart';
import 'package:junior_app/view/pages/signup_view.dart';
import 'package:junior_app/view/pages/main_page.dart';

// VIEW MODELS
import 'package:junior_app/view_model/auth_view_model.dart';
import 'package:junior_app/view_model/login_view_model.dart';
import 'package:junior_app/view_model/signup_view_model.dart';
import 'package:junior_app/view_model/navigation_view_model.dart';
import 'package:junior_app/view_model/timer_view_model.dart';
import 'package:junior_app/view_model/network_view_model.dart';
import 'package:junior_app/view_model/photo_library_view_model.dart';
import 'package:junior_app/view_model/todo_view_model.dart';
import 'package:junior_app/view_model/theme_view_model.dart';
import 'package:junior_app/view_model/localization_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// âš ï¸ you can delete this import because we're not actually using easy_localization here
// import 'package:junior_app/extensions/localization_extension.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // init localization BEFORE runApp
  final localizationVM = LocalizationViewModel();
  await localizationVM.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalizationViewModel>.value(
          value: localizationVM,
        ),
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()..checkLoginStatus()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => SignupViewModel()),
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(create: (_) => TimerViewModel()),
        ChangeNotifierProvider(create: (_) => NetworkViewModel()),
        ChangeNotifierProvider(create: (_) => GalleryViewModel()),
        ChangeNotifierProvider(create: (_) => TodoViewModel()),
        ChangeNotifierProvider(create: (_) => LocationViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeVM = context.watch<ThemeViewModel>();
    final loc = context.watch<LocalizationViewModel>();
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Junior App',

          locale: loc.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supported) {
            if (locale == null) return supported.first;
            for (final l in supported) {
              if (l.languageCode == locale.languageCode) {
                return l;
              }
            }
            return supported.first;
          },

          theme: themeVM.lightTheme,
          darkTheme: themeVM.darkTheme,
          themeMode: themeVM.mode,

          routes: {
            '/': (context) => _buildHomePage(authVM),
            '/login': (context) => const LoginV(),
            '/signup': (context) => const SignupV(),
            '/main': (context) => const MainPage(),
            '/cloud': (context) => const CloudPage(),
          },
          initialRoute: '/',
        );
      },
    );
  }

  Widget _buildHomePage(AuthViewModel authVM) {
    if (authVM.isLoggedIn) {
      return const MainPage();
    } else {
      return const LoginV();
    }
  }
}

