import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:atlas_app/main.dart';
import 'package:atlas_app/providers/memory_provider.dart';

void main() {
  testWidgets('AtlasApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MemoryProvider(),
        child: const AtlasApp(),
      ),
    );

    expect(find.text('ATLAS'), findsOneWidget);

    // Fast-forward pending splash screen timer
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
