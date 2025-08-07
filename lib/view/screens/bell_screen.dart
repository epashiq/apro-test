import 'package:apro_test/controller/provider/bell_provider.dart';
import 'package:apro_test/view/widgets/button_widget.dart';
import 'package:apro_test/view/widgets/repeat_interval_drop_down.dart';
import 'package:apro_test/view/widgets/time_picker_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bell_selector.dart';

class MindfulnessBellScreen extends StatefulWidget {
  const MindfulnessBellScreen({super.key});

  @override
  State<MindfulnessBellScreen> createState() => _MindfulnessBellScreenState();
}

class _MindfulnessBellScreenState extends State<MindfulnessBellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BellProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mindfulness Bell',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<BellProvider>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BellSelector(),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      TimePickerWidget(
                        label: 'Starts in',
                        time: controller.startTime,
                        onTimeChanged: controller.setStartTime,
                      ),
                      const SizedBox(height: 20),
                      TimePickerWidget(
                        label: 'Ends in',
                        time: controller.endTime,
                        onTimeChanged: controller.setEndTime,
                      ),
                      const SizedBox(height: 20),
                      const IntervalSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mute Bell in Silent Mode',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.toggleMuteInSilentMode,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: controller.muteInSilentMode
                                  ? const Color(0xFF8B5FBF)
                                  : Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            color: controller.muteInSilentMode
                                ? const Color(0xFF8B5FBF)
                                : Colors.transparent,
                          ),
                          child: controller.muteInSilentMode
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const ButtonWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
