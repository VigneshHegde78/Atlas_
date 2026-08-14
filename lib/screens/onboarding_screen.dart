import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(36),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                          colors: [
                            Color(0x100B192C),
                            Color(0x2010B981),
                          ],
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 48,
                            left: 40,
                            child: Transform.rotate(
                              angle: -0.2,
                              child: const Icon(
                                Icons.photo_library_rounded,
                                size: 48,
                                color: Colors.black26,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 56,
                            right: 48,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: const Icon(
                                Icons.link_rounded,
                                size: 40,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 64,
                            color: AtlasColors.rose,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Save Anything',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AtlasColors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Share links, screenshots, ideas, or files into ATLAS from anywhere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PermissionsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AtlasColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                    shadowColor: AtlasColors.blue.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
