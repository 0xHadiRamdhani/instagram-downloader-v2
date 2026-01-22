import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:instagram_downloader/main.dart';

void main() {
  testWidgets('InstaGrab app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InstaGrabApp()));
    expect(find.text('InstaGrab'), findsOneWidget);
    expect(find.textContaining('Download Instagram'), findsOneWidget);
    expect(find.text('Fetch Media'), findsOneWidget);
  });
}
