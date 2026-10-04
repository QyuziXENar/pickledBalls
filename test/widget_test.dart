import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/main.dart';

void main() {
  testWidgets('Home screen shows game menu', (WidgetTester tester) async {
    // 1. Updated MyApp -> PickleballApp
    await tester.pumpWidget(const PaddleBlitzApp());

    // 2. Updated assertions to match current labels
    expect(find.textContaining('PICKLEBALL'), findsOneWidget);
    expect(find.text('GAME'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });
}