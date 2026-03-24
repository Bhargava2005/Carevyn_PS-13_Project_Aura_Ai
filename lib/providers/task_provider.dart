// lib/providers/task_provider.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/ai_task_model.dart';
import '../services/api_service.dart';

enum TaskState { idle, loading, success, error }

class TaskResult {
  final String? text;
  final Uint8List? imageBytes;
  final AiTaskType taskType;
  final DateTime timestamp;

  TaskResult({
    this.text,
    this.imageBytes,
    required this.taskType,
    required this.timestamp,
  });

  bool get isImage => imageBytes != null;
}

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService;

  AiTask _activeTask = AiTasks.all.first;
  TaskState _state = TaskState.idle;
  String? _errorMessage;
  final List<TaskResult> _results = [];  // ← make final, was mutable reassigned


  AiTask get activeTask => _activeTask;
  TaskState get state => _state;
  String? get errorMessage => _errorMessage;
  List<TaskResult> get results => List.unmodifiable(_results); // ← expose safely

  bool get isLoading => _state == TaskState.loading;

  TaskProvider({required ApiService apiService}) : _apiService = apiService;

  void selectTask(AiTask task) {
    _activeTask = task;
    _errorMessage = null;
    _state = TaskState.idle;
    notifyListeners();
  }




  void clearError() {
    _errorMessage = null;
    _state = TaskState.idle;
    notifyListeners();
  }

  void clearResults() {
    _results.clear();
    notifyListeners();
  }

  Future<void> runTask({String? textInput}) async { // ← removed unused params
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.runTask( // ← now matches ApiService
        task: _activeTask,
        textInput: textInput,
      );

      _results.insert(
        0,
        TaskResult(
          text: result.text,
          imageBytes: result.imageBytes,
          taskType: _activeTask.type,
          timestamp: DateTime.now(),
        ),
      );
      _state = TaskState.success;
    } on ApiException catch (e) {
      _state = TaskState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = TaskState.error;
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      notifyListeners();
    }
  }
}