import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/profile_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  bool _busy = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final u = context.read<AuthProvider>().user;
    if (u != null) {
      _nameCtrl.text = u.name;
      _businessCtrl.text = u.businessName ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (auth.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up to save your profile.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final svc = context.read<ProfileService>();
      final updated = await svc.update(
        name: _nameCtrl.text.trim(),
        businessName: _businessCtrl.text.trim().isEmpty ? '' : _businessCtrl.text.trim(),
      );
      auth.updateLocalUser(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accent(c),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        (auth.user?.name.isNotEmpty ?? false)
                            ? auth.user!.name.substring(0, 1).toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.user?.name ?? 'Guest',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            )),
                        Text(auth.user?.email ?? '',
                            style: TextStyle(color: c.textSecondary, fontSize: 12)),
                        if (auth.isGuest)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: c.accentPrimary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Guest Mode',
                              style: TextStyle(
                                color: c.accentPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Account Information'),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              enabled: !auth.isGuest,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _businessCtrl,
              decoration: const InputDecoration(labelText: 'Business Name'),
              enabled: !auth.isGuest,
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Save Profile',
              icon: Icons.save_outlined,
              loading: _busy,
              onPressed: auth.isGuest ? null : (_busy ? null : _save),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Appearance'),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Mode',
                      style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                    ],
                    selected: {themeProv.mode},
                    onSelectionChanged: (s) => themeProv.setMode(s.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Other'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.receipt_outlined, color: c.accentPrimary),
                    title: const Text('Overhead Costs'),
                    subtitle: const Text('Manage costs for electricity, gas, packaging, etc.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/profile/overhead'),
                  ),
                  Divider(height: 1, color: c.border),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: c.textSecondary),
                    title: const Text('About Batchly'),
                    subtitle: const Text('COGS calculator for small F&B businesses.'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Batchly',
                        applicationVersion: '1.0.0',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: Text(auth.isGuest ? 'Exit Guest Mode' : 'Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.marginDangerText,
                side: BorderSide(color: c.marginDangerText.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
