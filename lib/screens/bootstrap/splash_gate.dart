import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../providers/auth_provider.dart';

/// The initial screen. Kicks off AuthProvider.bootstrap() the first time it
/// builds; the router's redirect callback moves the user to /login or /
/// once auth becomes ready.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Fire and forget — AuthProvider notifies listeners which triggers the
    // router redirect.
    context.read<AuthProvider>().bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: AppGradients.accent(c),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Icon(Icons.blender, size: 44, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Batchly',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
