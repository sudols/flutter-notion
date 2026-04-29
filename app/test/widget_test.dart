import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/workspace_provider.dart';
import 'package:app/providers/page_provider.dart';
import 'package:app/providers/block_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
          ChangeNotifierProvider(create: (_) => PageProvider()),
          ChangeNotifierProvider(create: (_) => BlockProvider()),
        ],
        child: const NotionApp(),
      ),
    );
    // Should show a loading spinner or the login screen.
    expect(find.byType(CircularProgressIndicator), findsAny);
  });
}
