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

  // Chatbot is not in this list — it's the floating center action button.
  static const _tabs = [
    ('/', Icons.dashboard_rounded, 'Home'),
    ('/ingredients', Icons.egg_alt_outlined, 'Pantry'),
    ('/recipes', Icons.receipt_long_rounded, 'Recipe'),
    ('/profile', Icons.person_outline, 'Profile'),
  ];

  static const _chatbotPath = '/chatbot';

  /// Returns the selected tab index, or -1 if the current path isn't a tab
  /// (e.g. on /chatbot, no tab is highlighted).
  int _indexForPath(String path) {
    var best = -1;
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
      floatingActionButton: _ChatbotFab(
        selected: widget.currentPath.startsWith(_chatbotPath),
        onTap: () => context.go(_chatbotPath),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        color: c.surface,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: _tabs[0].$2,
                label: _tabs[0].$3,
                selected: idx == 0,
                onTap: () => context.go(_tabs[0].$1),
              ),
              _NavItem(
                icon: _tabs[1].$2,
                label: _tabs[1].$3,
                selected: idx == 1,
                onTap: () => context.go(_tabs[1].$1),
              ),
              const SizedBox(width: 72), // space for the notched FAB
              _NavItem(
                icon: _tabs[2].$2,
                label: _tabs[2].$3,
                selected: idx == 2,
                onTap: () => context.go(_tabs[2].$1),
              ),
              _NavItem(
                icon: _tabs[3].$2,
                label: _tabs[3].$3,
                selected: idx == 3,
                onTap: () => context.go(_tabs[3].$1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.primary : c.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatbotFab extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const _ChatbotFab({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: c.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: selected ? 30 : 28,
          ),
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
      color: c.primary.withOpacity(0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: c.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Guest Mode — data isn't saved. Sign up to save.",
                  style: TextStyle(color: c.textPrimary, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Sign up'),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 18, color: c.textSecondary),
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
