import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../providers/memory_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'universe_screen.dart';
import 'needs_review_screen.dart';
import 'screenshot_review_screen.dart';
import 'share_processing_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  StreamSubscription? _intentDataStreamSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    UniverseScreen(),
    NeedsReviewScreen(),
    ScreenshotReviewScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShareIntentListener();
  }

  void _initShareIntentListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty && mounted) {
        _triggerShareModal(value.first.path);
      }
    }, onError: (err) {
      debugPrint("Sharing intent error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty && mounted) {
        _triggerShareModal(value.first.path);
      }
    });
  }

  void _triggerShareModal([String sharedText = '']) {
    final provider = Provider.of<MemoryProvider>(context, listen: false);
    provider.simulateShareProcessing(
      titleText: sharedText.isNotEmpty ? sharedText : 'Shared Item',
      onDone: () {},
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => const ShareProcessingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoryProvider = Provider.of<MemoryProvider>(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 100,
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Bottom Nav background bar
              Container(
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AtlasColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [AtlasTheme.floatShadow],
                  border: Border.all(color: Colors.grey.shade200.withOpacity(0.8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.home_rounded,
                        color: _currentIndex == 0 ? AtlasColors.blue : Colors.grey.shade400,
                        size: 24,
                      ),
                      onPressed: () => setState(() => _currentIndex = 0),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.hub_rounded,
                        color: _currentIndex == 1 ? AtlasColors.blue : Colors.grey.shade400,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const UniverseScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 52), // Space for center (+) button

                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.move_to_inbox_rounded,
                            color: _currentIndex == 2 ? AtlasColors.blue : Colors.grey.shade400,
                            size: 24,
                          ),
                          onPressed: () => setState(() => _currentIndex = 2),
                        ),
                        if (memoryProvider.triageItems.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AtlasColors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.image_rounded,
                            color: _currentIndex == 3 ? AtlasColors.blue : Colors.grey.shade400,
                            size: 24,
                          ),
                          onPressed: () => setState(() => _currentIndex = 3),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AtlasColors.emerald,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Unclipped Floating Center Hero (+) FAB
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: () => _triggerShareModal('Quick Save Note'),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: AtlasColors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AtlasColors.blue.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
