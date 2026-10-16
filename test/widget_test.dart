
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wao_web/main.dart';

void main() {
  testWidgets('WAO inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const WaoWebApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
