import 'package:flutter_test/flutter_test.dart';
import 'package:fmt_tracker/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FMTTrackerApp());
    expect(find.text('FMT Tracker'), findsAny);
  });
}
