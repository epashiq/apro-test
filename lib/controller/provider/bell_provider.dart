

import 'package:apro_test/model/bell_model.dart';
import 'package:flutter/material.dart';
import '../services/bell_service.dart';
import '../services/storage_service.dart';

class BellProvider extends ChangeNotifier {
  final BellService _bellService = BellService();
  final StorageService _storageService = StorageService();

  BellModel _selectedBell = BellModel.getAllBells().first;
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 15);
  TimeOfDay _endTime = const TimeOfDay(hour: 14, minute: 15);
  int _repeatInterval = 10;
  bool _muteInSilentMode = false;
  bool _isActive = false;

  BellModel get selectedBell => _selectedBell;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  int get repeatInterval => _repeatInterval;
  bool get muteInSilentMode => _muteInSilentMode;
  bool get isActive => _isActive;
  List<int> get availableIntervals => const [5, 10, 15];

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _storageService.loadSettings();
      if (settings != null) {
        _selectedBell = settings.bellModel;
        _startTime = settings.startTime;
        _endTime = settings.endTime;
        _repeatInterval = settings.repeatInterval;
        _muteInSilentMode = settings.muteInSilentMode;
        
        _isActive = await _bellService.isActive();
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  void selectBell(BellModel bell) {
    _selectedBell = bell;
    notifyListeners();
  }

  void setStartTime(TimeOfDay time) {
    _startTime = time;
    notifyListeners();
  }

  void setEndTime(TimeOfDay time) {
    _endTime = time;
    notifyListeners();
  }

  void setRepeatInterval(int interval) {
    _repeatInterval = interval;
    notifyListeners();
  }

  void toggleMuteInSilentMode() {
    _muteInSilentMode = !_muteInSilentMode;
    notifyListeners();
  }

  bool _isValidTimeRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    final end = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
    
    final adjustedEnd = end.isBefore(start) ? end.add(const Duration(days: 1)) : end;
    
    return adjustedEnd.isAfter(start);
  }


  Future<bool> saveSettings() async {
    try {
      if (!_isValidTimeRange()) {
        throw Exception('End time must be after start time');
      }

      final settings = BellSettings(
        bellModel: _selectedBell,
        startTime: _startTime,
        endTime: _endTime,
        repeatInterval: _repeatInterval,
        muteInSilentMode: _muteInSilentMode,
      );

      await _storageService.saveSettings(settings);

      await _bellService.stopBellSchedule();

      await _bellService.startBellSchedule(settings);
      
      _isActive = true;
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  Future<void> cancelBellSchedule() async {
    try {
      await _bellService.stopBellSchedule();
      _isActive = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error canceling bell schedule: $e');
    }
  }

  Future<void> playBellPreview() async {
    try {
      await _bellService.playBellPreview(_selectedBell.id);
    } catch (e) {
      debugPrint('Error playing bell preview: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}