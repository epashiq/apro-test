import 'package:flutter/material.dart';

class BellModel {
  final String id;
  final String name;
  final String assetPath;
  final String imagePath;

  const BellModel({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.imagePath,
  });

  static List<BellModel> getAllBells() {
    return [
      const BellModel(
        id: 'singing_bowl',
        name: 'Singing Bowl',
        assetPath: 'sounds/mixkit-bell-tick-tock-timer-1046.wav',
        imagePath: 'assets/images/singing-bowl.png',
      ),
      const BellModel(
        id: 'ohm_bell',
        name: 'Ohm Bell',
        assetPath: 'sounds/mixkit-melodic-classic-door-bell-111.wav',
        imagePath: 'assets/images/ohm-bell.png',
      ),
      const BellModel(
        id: 'gong',
        name: 'Gong',
        assetPath: 'sounds/mixkit-service-bell-931.wav',
        imagePath: 'assets/images/gong.png',
      ),
    ];
  }
}

class BellSettings {
  final BellModel bellModel;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int repeatInterval; // in minutes
  final bool muteInSilentMode;

  const BellSettings({
    required this.bellModel,
    required this.startTime,
    required this.endTime,
    required this.repeatInterval,
    required this.muteInSilentMode,
  });

  Map<String, dynamic> toJson() {
    return {
      'bellType': bellModel.id,
      'startTimeHour': startTime.hour,
      'startTimeMinute': startTime.minute,
      'endTimeHour': endTime.hour,
      'endTimeMinute': endTime.minute,
      'repeatInterval': repeatInterval,
      'muteInSilentMode': muteInSilentMode,
    };
  }

  static BellSettings fromJson(Map<String, dynamic> json) {
    final allBells = BellModel.getAllBells();
    final bellType = allBells.firstWhere(
      (bell) => bell.id == json['bellType'],
      orElse: () => allBells.first,
    );

    return BellSettings(
      bellModel: bellType,
      startTime: TimeOfDay(
        hour: json['startTimeHour'] ?? 12,
        minute: json['startTimeMinute'] ?? 15,
      ),
      endTime: TimeOfDay(
        hour: json['endTimeHour'] ?? 14,
        minute: json['endTimeMinute'] ?? 15,
      ),
      repeatInterval: json['repeatInterval'] ?? 10,
      muteInSilentMode: json['muteInSilentMode'] ?? false,
    );
  }
}
