import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/page_provider.dart';
import 'providers/block_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
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
}

class NotionApp extends StatelessWidget {
  const NotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      home: const _AppRoot(),
    );
  }
}

/// Checks for a stored session on startup; shows login or home accordingly.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryRestoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
