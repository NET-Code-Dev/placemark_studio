import 'package:flutter/foundation.dart';
import '../../core/errors/app_exception.dart';

enum ViewState { idle, loading, success, error }

abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  AppException? _lastException;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  AppException? get lastException => _lastException;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isIdle => _state == ViewState.idle;
  bool get isSuccess => _state == ViewState.success;

  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    _lastException = null;
    notifyListeners();
  }

  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    _lastException = null;
    notifyListeners();
  }

  void setError(String message, [AppException? exception]) {
    _state = ViewState.error;
    _errorMessage = message;
    _lastException = exception;
    notifyListeners();
  }

  void setIdle() {
    _state = ViewState.idle;
    _errorMessage = null;
    _lastException = null;
    notifyListeners();
  }

  void clearError() {
    if (_state == ViewState.error) {
      _state = ViewState.idle;
      _errorMessage = null;
      _lastException = null;
      notifyListeners();
    }
  }

  Future<T> safeExecute<T>(Future<T> Function() operation) async {
    try {
      setLoading();
      final result = await operation();
      setSuccess();
      return result;
    } on AppException catch (e) {
      setError(e.message, e);
      rethrow;
    } catch (e) {
      setError('An unexpected error occurred: ${e.toString()}');
      rethrow;
    }
  }
}
