import 'package:apro_test/controller/provider/bell_provider.dart';
import 'package:apro_test/controller/services/audio_service.dart';
import 'package:apro_test/controller/services/bell_task_handler_service.dart';
import 'package:apro_test/view/screens/bell_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service and request permissions early
  // final AudioService audioService = AudioService();
  await AudioService.instance.requestPermissions();
  // await audioService.requestPermissions();

  // Initialize notification permissions
  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  // Request notification permissions on iOS
  await notifications
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );

  // Request notification permissions on Android
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestExactAlarmsPermission();

  try {
    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false for production
    );

    debugPrint("✅ Workmanager initialized successfully");
  } catch (e) {
    debugPrint("❌ Workmanager initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BellProvider(),
      child: MaterialApp(
        title: 'Mindfulness Bell',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF8B5FBF),
            secondary: Color(0xFFFFD700),
            surface: Color(0xFF2D2D42),
          ),
        ),
        home: const MindfulnessBellScreen(),
      ),
    );
  }
}
