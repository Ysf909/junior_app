// lib/view_models/timer_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerViewModel with ChangeNotifier {
  static const String _firstLoginKey = 'first_login_date';
  static const String _totalTimeKey = 'total_time_spent';
  static const String _lastResumeKey = 'last_resume_time';

  int _elapsedSeconds = 0;
  bool _isRunning = false;
  DateTime? _firstLoginDate;
  int _totalTimeSpent = 0;
  DateTime? _lastResumeTime;

  int get elapsedSeconds => _elapsedSeconds;
  bool get isRunning => _isRunning;
  DateTime? get firstLoginDate => _firstLoginDate;
  int get totalTimeSpent => _totalTimeSpent;

  String get formattedElapsedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedTotalTime {
    final hours = _totalTimeSpent ~/ 3600;
    final minutes = (_totalTimeSpent % 3600) ~/ 60;
    final seconds = _totalTimeSpent % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  TimerViewModel() {
    _loadTimerData();
  }

  Future<void> _loadTimerData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load first login date
    final firstLoginString = prefs.getString(_firstLoginKey);
    if (firstLoginString != null) {
      _firstLoginDate = DateTime.parse(firstLoginString);
    }
    
    // Load total time spent
    _totalTimeSpent = prefs.getInt(_totalTimeKey) ?? 0;
    
    // Load last resume time and calculate elapsed time if app was closed while running
    final lastResumeString = prefs.getString(_lastResumeKey);
    if (lastResumeString != null) {
      _lastResumeTime = DateTime.parse(lastResumeString);
      final now = DateTime.now();
      final difference = now.difference(_lastResumeTime!).inSeconds;
      _elapsedSeconds = difference;
      _totalTimeSpent += difference;
      _isRunning = true;
      _startTimer();
    }
    
    notifyListeners();
  }

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _lastResumeTime = DateTime.now();
      _saveTimerState();
      _startTimer();
      notifyListeners();
    }
  }

  void pauseTimer() {
    if (_isRunning) {
      _isRunning = false;
      _updateTotalTime();
      _lastResumeTime = null;
      _saveTimerState();
      notifyListeners();
    }
  }

  void resetTimer() {
    _elapsedSeconds = 0;
    _isRunning = false;
    _lastResumeTime = null;
    _saveTimerState();
    notifyListeners();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRunning) {
        _elapsedSeconds++;
        _totalTimeSpent++;
        notifyListeners();
        _startTimer();
      }
    });
  }

  void _updateTotalTime() {
    if (_lastResumeTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastResumeTime!).inSeconds;
      _totalTimeSpent += difference;
    }
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save first login date if not already saved
    if (_firstLoginDate == null) {
      _firstLoginDate = DateTime.now();
      await prefs.setString(_firstLoginKey, _firstLoginDate!.toIso8601String());
    }
    
    await prefs.setInt(_totalTimeKey, _totalTimeSpent);
    
    if (_lastResumeTime != null) {
      await prefs.setString(_lastResumeKey, _lastResumeTime!.toIso8601String());
    } else {
      await prefs.remove(_lastResumeKey);
    }
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLoginKey);
    await prefs.remove(_totalTimeKey);
    await prefs.remove(_lastResumeKey);
    
    _elapsedSeconds = 0;
    _totalTimeSpent = 0;
    _firstLoginDate = null;
    _lastResumeTime = null;
    _isRunning = false;
    
    notifyListeners();
  }
}