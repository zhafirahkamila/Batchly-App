import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../models/recipe.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecipesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Resep')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        child: p.loading && p.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : p.items.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Belum ada resep',
                        subtitle: 'Tambahkan resep pertama untuk mulai menghitung HPP.',
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 600;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: wide ? (p.items.length / 2).ceil() : p.items.length,
                        itemBuilder: (context, index) {
                          if (!wide) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RecipeCard(recipe: p.items[index]),
                            );
                          }
                          final left = p.items[index * 2];
                          final rightIdx = index * 2 + 1;
                          final right = rightIdx < p.items.length ? p.items[rightIdx] : null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _RecipeCard(recipe: left)),
                                const SizedBox(width: 12),
                                Expanded(child: right == null ? const SizedBox() : _RecipeCard(recipe: right)),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      onTap: () => context.push('/recipes/${recipe.id}'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.accent(c),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cookie_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
                const SizedBox(height: 2),
                Text('Batch: ${_qty(recipe.yieldQty)} ${recipe.yieldUnit}',
                    style: TextStyle(color: c.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }

  String _qty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
