import 'package:flutter_test/flutter_test.dart';
import 'package:roommate_finder/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomMateFinderApp());
    expect(find.byType(RoomMateFinderApp), findsOneWidget);

    // The splash screen waits ~2.8s before routing. Let that timer fire,
    // otherwise the tree is torn down with a pending timer and the test fails.
    // Pump fixed frames rather than pumpAndSettle: the splash runs a looping
    // animation, so the tree never reaches a settled state.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
  });
}
