import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:patta_safar/main.dart';

void main() {
  testWidgets('shows the Patta Safar opening decision', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PattaSafarApp());
    await tester.pump();

    expect(find.text('PATTA SAFAR'), findsOneWidget);
    expect(find.textContaining('BLIND'), findsOneWidget);
    expect(find.textContaining('SEEN'), findsOneWidget);
  });
}
