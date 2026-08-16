import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'providers/memory_provider.dart';
import 'screens/share_processing_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

DateTime? _lastSharedAt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final memoryProvider = MemoryProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: memoryProvider,
      child: const AtlasApp(),
    ),
  );

  _initShareIntentListener(memoryProvider);
}

void _initShareIntentListener(MemoryProvider provider) {
  // Shares delivered while the app is already running (warm start).
  ReceiveSharingIntent.instance.getMediaStream().listen(
    (files) => _handleSharedFiles(provider, files),
    onError: (err) => debugPrint("Share intent stream error: $err"),
  );

  // Shares delivered on cold start (app launched via the share sheet).
  ReceiveSharingIntent.instance.getInitialMedia().then((files) {
    if (files.isEmpty) return;
    _handleSharedFiles(provider, files);
    ReceiveSharingIntent.instance.reset();
  }).catchError((err) {
    debugPrint("Share initial intent error: $err");
  });
}

void _handleSharedFiles(MemoryProvider provider, List<SharedMediaFile> files) {
  if (files.isEmpty || provider.isProcessingShare) return;

  final now = DateTime.now();
  if (_lastSharedAt != null && now.difference(_lastSharedAt!) < const Duration(seconds: 2)) {
    return;
  }
  _lastSharedAt = now;

  provider.startSharedContentProcessing(files);
  _pushShareProcessingScreen();
}

void _pushShareProcessingScreen() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) {
    Future.delayed(const Duration(milliseconds: 250), _pushShareProcessingScreen);
    return;
  }

  nav.push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => const ShareProcessingScreen(),
    ),
  );
}

class AtlasApp extends StatelessWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: AtlasTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
