import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grid_strategy_app/main.dart';

void main() {
  testWidgets('grid strategy app renders the trading dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GridStrategyPage(autoRefresh: false, loadStorage: false),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('操盘台'), findsOneWidget);
    expect(find.byType(GridStrategyPage), findsOneWidget);
  });
}
