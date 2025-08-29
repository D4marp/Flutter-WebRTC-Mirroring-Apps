import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MirroringService extends ChangeNotifier {
  static const platform = MethodChannel('com.example.mirroring_app/screen_capture');
  
  bool _isCapturing = false;
  String _status = 'Ready';
  
  bool get isCapturing => _isCapturing;
  String get status => _status;
  
  Future<bool> startScreenCapture() async {
    try {
      _status = 'Requesting permission...';
      notifyListeners();
      
      final bool result = await platform.invokeMethod('startScreenCapture');
      
      if (result) {
        _isCapturing = true;
        _status = 'Screen sharing active';
      } else {
        _status = 'Failed to start capture';
      }
      
      notifyListeners();
      return result;
    } catch (e) {
      _status = 'Error: $e';
      _isCapturing = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> stopScreenCapture() async {
    try {
      final bool result = await platform.invokeMethod('stopScreenCapture');
      
      _isCapturing = false;
      _status = 'Ready';
      notifyListeners();
      
      return result;
    } catch (e) {
      _status = 'Error stopping capture: $e';
      notifyListeners();
      return false;
    }
  }
  
  void updateStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
