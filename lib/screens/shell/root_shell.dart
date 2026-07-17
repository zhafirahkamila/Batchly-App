import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// The shell that wraps all authenticated (or guest) screens. Owns the bottom
/// nav bar and the guest-mode banner nudging the user to sign up.
class RootShell extends StatefulWidget {
  final Widget child;
  final String currentPath;

  const RootShell({super.key, required this.child, required this.currentPath});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  bool _bannerDismissed = false;

  static const _tabs = [
    ('/', Icons.dashboard_rounded, 'Home'),
    ('/ingredients', Icons.egg_alt_outlined, 'Pantry'),
    ('/recipes', Icons.receipt_long_rounded, 'Recipe'),
    ('/chatbot', Icons.smart_toy_outlined, 'Chatbot'),
    ('/profile', Icons.person_outline, 'Profile'),
  ];

  int _indexForPath(String path) {
    // Highest-index prefix match wins (so /profile/overhead → Profil tab, not
    // Dashboard).
    var best = 0;
    var bestLen = -1;
    for (var i = 0; i < _tabs.length; i++) {
      final p = _tabs[i].$1;
      final matches = p == '/' ? path == '/' : path.startsWith(p);
      if (matches && p.length > bestLen) {
        best = i;
        bestLen = p.length;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final showBanner = auth.isGuest && !_bannerDismissed;
    final idx = _indexForPath(widget.currentPath);

    return Scaffold(
      body: Column(
        children: [
          if (showBanner)
            _GuestBanner(
              onDismiss: () => setState(() => _bannerDismissed = true),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => context.go(_tabs[i].$1),
          items: [
            for (final t in _tabs)
              BottomNavigationBarItem(icon: Icon(t.$2), label: t.$3),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _GuestBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.accentPrimary.withOpacity(0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: c.accentPrimary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode Tamu — data tidak disimpan. Daftar untuk menyimpan.',
                  style: TextStyle(color: c.textPrimary, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Daftar'),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 18, color: c.textSecondary),
                tooltip: 'Tutup',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
