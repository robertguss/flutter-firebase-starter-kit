import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_starter_kit/app.dart';

void main() {
  testWidgets('renders the starter kit shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('Starter Kit'), findsOneWidget);
  });
}
