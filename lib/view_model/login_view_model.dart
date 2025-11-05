// LoginViewModel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../validation.dart';
import 'auth_view_model.dart';

class LoginViewModel extends ChangeNotifier {
  String _email = "";
  String _password = "";
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  String? _emailError;
  String? _passwordError;

  // Getters
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;

  Future<void> init() async {
    _isInitialized = true;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    _emailError = Validation.email(value);
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _passwordError = Validation.password(value);
    notifyListeners();
  }

  bool _validateForm() {
    _emailError = Validation.email(_email);
    _passwordError = Validation.password(_password);
    return _emailError == null && _passwordError == null;
  }

  Future<bool> login(BuildContext context) async {
    if (!_validateForm()) {
      notifyListeners();
      return false;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (_email.isNotEmpty && _password.isNotEmpty) {
        // Get AuthViewModel and update global auth state
        final authViewModel = context.read<AuthViewModel>();
        await authViewModel.login(_email);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = "Invalid credentials";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = "An error occurred during login. Please try again.";
      notifyListeners();
      return false;
    }
  }

  Future<void> clear() async {
    _email = '';
    _password = '';
    _isLoading = false;
    _error = null;
    _emailError = null;
    _passwordError = null;
    notifyListeners();
  }
}