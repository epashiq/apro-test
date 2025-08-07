
import 'package:apro_test/controller/provider/bell_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BellProvider>(
      builder: (context, controller, child) {
        return Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => cancelBell(context, controller),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A54),
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      controller.isActive ? 'Stop' : 'Cancel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Save Button
            Expanded(
              child: GestureDetector(
                onTap: () => saveBell(context, controller),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5FBF), Color(0xFFB984E3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5FBF).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void cancelBell(BuildContext context, BellProvider controller) async {
    if (controller.isActive) {
      final bool? shouldStop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Stop Bell Schedule',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to stop the mindfulness bell schedule?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Stop',
                style: TextStyle(color: Color(0xFF8B5FBF)),
              ),
            ),
          ],
        ),
      );

      if (shouldStop == true) {
        await controller.cancelBellSchedule();
        if (context.mounted) {
          _showSnackBar(context, 'Bell schedule stopped', Icons.stop_circle);
        }
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void saveBell(BuildContext context, BellProvider controller) async {
    _showLoadingDialog(context);

    try {
      final success = await controller.saveSettings();
      
      if (context.mounted) {
        Navigator.of(context).pop(); 
        
        if (success) {
          _showSnackBar(
            context, 
            'Mindfulness bell schedule saved successfully!',
            Icons.check_circle,
          );
        } else {
          _showSnackBar(
            context, 
            'Failed to save bell schedule. Please check your time settings.',
            Icons.error,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); 
        _showSnackBar(
          context, 
          'Error: ${e.toString()}',
          Icons.error,
          isError: true,
        );
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8B5FBF),
        ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context, 
    String message, 
    IconData icon, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red.shade700 
            : const Color(0xFF8B5FBF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
