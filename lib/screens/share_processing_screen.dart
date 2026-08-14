import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';

class ShareProcessingScreen extends StatefulWidget {
  const ShareProcessingScreen({super.key});

  @override
  State<ShareProcessingScreen> createState() => _ShareProcessingScreenState();
}

class _ShareProcessingScreenState extends State<ShareProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

    return Scaffold(
      backgroundColor: AtlasColors.blue.withOpacity(0.95),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    RotationTransition(
                      turns: _spinController,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 3,
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          color: AtlasColors.emerald,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_rounded,
                          color: AtlasColors.emerald,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    memoryProvider.processingTitle,
                    key: ValueKey(memoryProvider.processingTitle),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    memoryProvider.processingSubtitle,
                    key: ValueKey(memoryProvider.processingSubtitle),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: memoryProvider.processingCompleted ? 1.0 : 0.0,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: memoryProvider.processingCompleted
                          ? () {
                              memoryProvider.resetShareProcessing();
                              Navigator.of(context).pop();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AtlasColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Return to previous app',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
