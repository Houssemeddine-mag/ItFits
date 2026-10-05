import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itfits/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ItFitsApp()));

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));
  });
}