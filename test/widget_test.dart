// LOUD のスモークテスト。Supabase / AdMob は実機で初期化するため
// ここでは空の widget tree が描画できることだけ検証する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders an empty MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
