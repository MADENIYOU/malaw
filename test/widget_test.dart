import 'package:flutter_test/flutter_test.dart';

import 'package:covoiturage_app/app.dart';

void main() {
  testWidgets('App boots and shows the auth screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CovoiturageApp());
    await tester.pump();

    expect(find.text('Se connecter comme passager'), findsOneWidget);
    expect(find.text('Se connecter comme chauffeur'), findsOneWidget);
  });
}
