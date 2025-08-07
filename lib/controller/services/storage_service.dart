import 'dart:convert';
import 'dart:developer';
import 'package:apro_test/model/bell_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _settingsKey = 'bell_settings';
  static const String _activeSettingsKey = 'active_bell_settings';

  Future<void> saveSettings(BellSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  Future<BellSettings?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson == null) return null;
      
      final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
      return BellSettings.fromJson(settingsMap);
    } catch (e) {
      log('Error loading settings: $e');
      return null;
    }
  }

  Future<void> saveActiveSettings(BellSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_activeSettingsKey, settingsJson);
      await prefs.setInt('${_activeSettingsKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw Exception('Failed to save active settings: $e');
    }
  }

  Future<BellSettings?> loadActiveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_activeSettingsKey);
      
      if (settingsJson == null) return null;
      
      final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
      return BellSettings.fromJson(settingsMap);
    } catch (e) {
      log('Error loading active settings: $e');
      return null;
    }
  }

  Future<void> clearActiveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSettingsKey);
      await prefs.remove('${_activeSettingsKey}_timestamp');
    } catch (e) {
      throw Exception('Failed to clear active settings: $e');
    }
  }

  Future<bool> hasActiveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_activeSettingsKey);
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getActiveSettingsTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${_activeSettingsKey}_timestamp');
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }
}