import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._internal();

  AudioService._internal();

  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;

  static const Map<String, String> _soundPaths = {
    'singing_bowl': 'sounds/mixkit-bell-tick-tock-timer-1046.wav',
    'ohm_bell': 'sounds/mixkit-melodic-classic-door-bell-111.wav',
    'gong': 'sounds/mixkit-service-bell-931.wav',
  };

  static const Map<String, String> _notificationSounds = {
    'singing_bowl': 'mixkit_bell_tick_tock_timer_1046',
    'ohm_bell': 'mixkit_melodic_classic_door_bell_111',
    'gong': 'mixkit_service_bell_931',
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();

      await requestPermissions();

      await _configureAudioContext();

      _isInitialized = true;
      debugPrint("✅ Audio service initialized successfully");
    } catch (e) {
      debugPrint("❌ Failed to initialize audio service: $e");
      throw Exception('Failed to initialize audio service: $e');
    }
  }

  Future<void> _configureAudioContext() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
            },
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true, 
            contentType: AndroidContentType.sonification, 
            usageType: AndroidUsageType.alarm, 
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
    } catch (e) {
      debugPrint("❌ Error configuring audio context: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      final permissions = <Permission>[
        Permission.notification,
        Permission.microphone,
        Permission.scheduleExactAlarm
      ];

      if (await Permission.scheduleExactAlarm.isDenied) {
        permissions.add(Permission.scheduleExactAlarm);
      }

      final results = await permissions.request();

      bool criticalPermissionsGranted =
          results[Permission.notification] == PermissionStatus.granted &&
              results[Permission.microphone] == PermissionStatus.granted;

      if (!criticalPermissionsGranted) {
        debugPrint("⚠️ Critical permissions not granted");
        debugPrint("   Notification: ${results[Permission.notification]}");
        debugPrint("   Microphone: ${results[Permission.microphone]}");
      } else {
        debugPrint("✅ All critical permissions granted");
      }

      debugPrint("📋 Permission results: $results");
    } catch (e) {
      debugPrint('❌ Permission request error: $e');
    }
  }

  Future<void> playBell(String bellType) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final soundPath = _soundPaths[bellType];
      if (soundPath == null) {
        debugPrint('❌ Unknown bell type: $bellType');
        await _playFallbackSound();
        return;
      }

      await _audioPlayer?.stop();

      await _audioPlayer?.setVolume(1.0);

      await _audioPlayer?.play(AssetSource(soundPath));

      debugPrint("🔔 Playing bell sound: $bellType");
    } catch (e) {
      debugPrint('❌ Error playing bell sound: $e');
      await _playFallbackSound();
    }
  }

  Future<void> _playFallbackSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      debugPrint("🔔 Played fallback system sound");
    } catch (systemSoundError) {
      debugPrint('❌ System sound fallback failed: $systemSoundError');
    }
  }

  static Future<void> playBellFromBackground(String bellType) async {
    debugPrint("🔔 Attempting to play bell from background: $bellType");

    AudioPlayer? backgroundPlayer;

    try {
      backgroundPlayer = AudioPlayer();

      await backgroundPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm, 
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
          iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.defaultToSpeaker,
                AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
              }),
        ),
      );

      final soundPath = _soundPaths[bellType];
      if (soundPath == null) {
        debugPrint('❌ Unknown bell type in background: $bellType');
        await SystemSound.play(SystemSoundType.alert);
        return;
      }

      await backgroundPlayer.setVolume(1.0);

      await backgroundPlayer.play(AssetSource(soundPath));

      await Future.delayed(const Duration(seconds: 3));

      debugPrint("✅ Background bell sound played successfully");
    } catch (e) {
      debugPrint('❌ Error playing bell from background: $e');

      try {
        await SystemSound.play(SystemSoundType.alert);
        debugPrint("🔔 Played fallback system sound in background");
      } catch (systemSoundError) {
        debugPrint('❌ All audio playback attempts failed: $systemSoundError');
      }
    } finally {
      try {
        await backgroundPlayer?.dispose();
      } catch (e) {
        debugPrint('❌ Error disposing background player: $e');
      }
    }
  }

  static String getNotificationSoundName(String bellType) {
    return _notificationSounds[bellType] ??
        _notificationSounds['singing_bowl']!;
  }

  Future<bool> isDeviceInSilentMode() async {
    try {
      return false; 
    } catch (e) {
      debugPrint('❌ Error checking silent mode: $e');
      return false;
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      if (_isInitialized && _audioPlayer != null) {
        await _audioPlayer!.setVolume(volume.clamp(0.0, 1.0));
        debugPrint("🔊 Volume set to: ${(volume * 100).round()}%");
      }
    } catch (e) {
      debugPrint('❌ Error setting volume: $e');
    }
  }

  Future<void> stop() async {
    try {
      if (_isInitialized && _audioPlayer != null) {
        await _audioPlayer!.stop();
        debugPrint("⏹️ Audio playback stopped");
      }
    } catch (e) {
      debugPrint('❌ Error stopping audio: $e');
    }
  }

  Future<bool> testAudio(String bellType) async {
    try {
      await playBell(bellType);
      return true;
    } catch (e) {
      debugPrint('❌ Audio test failed: $e');
      return false;
    }
  }

  static List<String> getAvailableBellTypes() {
    return _soundPaths.keys.toList();
  }

  bool get isReady => _isInitialized && _audioPlayer != null;

  Future<void> dispose() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      _isInitialized = false;
      debugPrint("🗑️ Audio service disposed");
    } catch (e) {
      debugPrint('❌ Error disposing audio service: $e');
    }
  }
}
