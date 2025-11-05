import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/todo_model.dart';
enum TodoFilter { all, completed, uncompleted }


class TodoViewModel with ChangeNotifier {
  List<TodoModel> _todos = [];
  bool _isLoading = false;
  String? _error;
  TodoFilter _filter = TodoFilter.all;
  TodoFilter get filter => _filter;

  int get countAll => todos.length;
  int get countCompleted => completedTodos.length;
  int get countUncompleted => uncompletedTodos.length;

  void setFilter(TodoFilter f) {
  if (_filter == f) return;
  _filter = f;
  notifyListeners();
}
  List<TodoModel> get allTodos => todos;
List<TodoModel> get completedTodos =>
    todos.where((t) => t.completed == true).toList();
List<TodoModel> get uncompletedTodos =>
    todos.where((t) => t.completed != true).toList();

List<TodoModel> get filteredTodos {
  switch (_filter) {
    case TodoFilter.completed:
      return completedTodos;
    case TodoFilter.uncompleted:
      return uncompletedTodos;
    case TodoFilter.all:
    default:
      return allTodos;
  }
}

  List<TodoModel> get todos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTodos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      };

      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _todos = data.map((item) => TodoModel.fromJson(item)).toList();
      } else {
        _todos = [];
        _error = 'Failed to fetch todos: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      _todos = [];
      _error = 'Failed to fetch todos: $e';
    }

    _isLoading = false;
    notifyListeners();
    
  }
}