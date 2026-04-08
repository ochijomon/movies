import 'package:flutter_test/flutter_test.dart';
import 'package:booksmovies/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MoviesApp());
    // Verify the app shell renders with the MOVIES brand
    expect(find.text('MOVIES'), findsWidgets);
  });
}
