import 'package:batchly_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme.light() and AppTheme.dark() build without errors',
      (WidgetTester tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Center(child: Text('Batchly'))),
        ),
      );
      expect(find.text('Batchly'), findsOneWidget);
    }
  });
}
