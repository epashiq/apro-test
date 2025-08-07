

import 'package:apro_test/controller/provider/bell_provider.dart';
import 'package:apro_test/model/bell_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BellSelector extends StatelessWidget {
  const BellSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BellProvider>(
      builder: (context, controller, child) {
        final bells = BellModel.getAllBells();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bells.map((bell) {
                final isSelected = controller.selectedBell.id == bell.id;

                return InkWell(
                  onTap: () {
                    controller.selectBell(bell);
                    controller.playBellPreview();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8B5FBF)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            getBellAsset(bell.id),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bell.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF8B5FBF)
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Select A Sound For Your Mindfulness Bell',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String getBellAsset(String bellType) {
    if (bellType == 'singing_bowl') {
        return 'assets/images/singing-bowl.png';
    }else if(bellType=='ohm_bell'){
      return 'assets/images/ohm-bell.png';
    }else if(bellType=='gong'){
      return 'assets/images/gong.png';
    }else{
     return 'no image found';
    }
  }
}
