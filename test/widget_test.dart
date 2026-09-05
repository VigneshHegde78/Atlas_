import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atlas_app/main.dart';
import 'package:atlas_app/providers/memory_provider.dart';
import 'package:atlas_app/screens/splash_screen.dart';

void main() {
  testWidgets('AtlasApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MemoryProvider(),
        child: const AtlasApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // Fast-forward pending splash screen timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
