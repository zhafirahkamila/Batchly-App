import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';

class BatchlyApp extends StatefulWidget {
  const BatchlyApp({super.key});

  @override
  State<BatchlyApp> createState() => _BatchlyAppState();
}

class _BatchlyAppState extends State<BatchlyApp> {
  late final _router = buildRouter(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'Batchly',
      debugShowCheckedModeBanner: false,
      themeMode: themeProv.mode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }
}
