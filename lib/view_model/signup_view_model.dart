// SignupViewModel.dart
import 'package:flutter/material.dart';
import '../validation.dart';
import '../preferences_service.dart';

class SignupViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _error;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _firstNameError;
  String? _lastNameError;

  // Getters
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get firstName => _firstName;
  String get lastName => _lastName;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get firstNameError => _firstNameError;
  String? get lastNameError => _lastNameError;

  // Add init method to check login status on app start
  Future<void> init() async {
    _isLoggedIn = await PreferencesService.isLoggedIn();
    if (_isLoggedIn) {
      _email = await PreferencesService.getEmail() ?? "";
    }
    _isInitialized = true;
    notifyListeners();
  }

  // Setters with validation
  void setEmail(String value) {
    _email = value.trim();
    _validateEmail();
    _clearError();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _validatePassword();
    _validateConfirmPassword();
    _clearError();
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _validateConfirmPassword();
    _clearError();
    notifyListeners();
  }

  void setFirstName(String value) {
    _firstName = value.trim();
    _validateFirstName();
    _clearError();
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value.trim();
    _validateLastName();
    _clearError();
    notifyListeners();
  }

  // Validation methods
  void _validateEmail() {
    _emailError = Validation.email(_email);
  }

  void _validatePassword() {
    _passwordError = Validation.password(_password);
  }

  void _validateConfirmPassword() {
    _confirmPasswordError = Validation.confirmPassword(_confirmPassword, _password);
  }

  void _validateFirstName() {
    _firstNameError = Validation.name(_firstName, 'first name');
  }

  void _validateLastName() {
    _lastNameError = Validation.name(_lastName, 'last name');
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
    }
  }

  bool _validateForm() {
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();
    _validateFirstName();
    _validateLastName();
    
    return _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _firstNameError == null &&
        _lastNameError == null;
  }

  // FIXED: Remove context parameter and AuthViewModel dependency
  Future<bool> signup() async {
    print('🚀 Signup started');
    
    if (!_validateForm()) {
      _error = "Please fix the errors above";
      print('❌ Form validation failed');
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock API call - simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful signup
      _isLoading = false;
      _isLoggedIn = true;
      
      // Save login state to preferences
      await PreferencesService.setLoggedIn(true, email: _email);
      
      print('✅ Signup successful - preferences saved');
      notifyListeners();
      
      return true;

    } catch (e) {
      _isLoading = false;
      _error = "An error occurred during signup. Please try again.";
      print('❌ Signup error: $e');
      notifyListeners();
      return false;
    }
  }

  // Add method to update login status
  void setLoggedIn(bool status) {
    _isLoggedIn = status;
    notifyListeners();
  }

  Future<void> clear() async {
    _email = '';
    _password = '';
    _confirmPassword = '';
    _firstName = '';
    _lastName = '';
    _isLoading = false;
    _isLoggedIn = false;
    _error = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _firstNameError = null;
    _lastNameError = null;
    await PreferencesService.logout();
    notifyListeners();
  }

  // Debug method
  void debugState() {
    print('=== SignupVM Debug ===');
    print('Email: $_email, Error: $_emailError');
    print('First Name: $_firstName, Error: $_firstNameError');
    print('Last Name: $_lastName, Error: $_lastNameError');
    print('Password length: ${_password.length}, Error: $_passwordError');
    print('Confirm Password length: ${_confirmPassword.length}, Error: $_confirmPasswordError');
    print('Is Loading: $_isLoading');
    print('Is Form Valid: ${_validateForm()}');
    print('====================');
  }
}