import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aplicacion/app.dart';

void main() {
  testWidgets('App boots into login page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AtencionDignaApp()));
    await tester.pump();
    expect(find.text('Atencion Digna'), findsOneWidget);
  });
}
