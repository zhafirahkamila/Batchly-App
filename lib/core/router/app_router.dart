import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/bootstrap/splash_gate.dart';
import '../../screens/chatbot/chatbot_placeholder_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/ingredients/ingredient_form_screen.dart';
import '../../screens/ingredients/ingredients_list_screen.dart';
import '../../screens/overhead/overhead_form_screen.dart';
import '../../screens/overhead/overhead_list_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/recipes/pricing_sheet.dart';
import '../../screens/recipes/recipe_detail_screen.dart';
import '../../screens/recipes/recipe_form_screen.dart';
import '../../screens/recipes/recipes_list_screen.dart';
import '../../screens/shell/root_shell.dart';

/// Builds the app's GoRouter. Auth-gated routes redirect to /login when the
/// user isn't authenticated (guest counts as authed). The router listens to
/// [AuthProvider] via `refreshListenable` so state changes trigger a redirect
/// re-eval without any manual push/pop plumbing.
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onPublic = loc == '/login' || loc == '/register' || loc == '/splash';

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onPublic && loc != '/splash' ? null : '/login';
        case AuthStatus.authenticated:
        case AuthStatus.guest:
          return onPublic ? '/' : null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashGate()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            RootShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: '/ingredients',
            builder: (_, __) => const IngredientsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const IngredientFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, s) => IngredientFormScreen(
                  ingredientId: int.parse(s.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/recipes',
            builder: (_, __) => const RecipesListScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const RecipeFormScreen()),
              GoRoute(
                path: ':id',
                builder: (_, s) => RecipeDetailScreen(
                  recipeId: int.parse(s.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => RecipeFormScreen(
                      recipeId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                  GoRoute(
                    path: 'pricing',
                    builder: (_, s) => PricingSheet(
                      recipeId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/chatbot',
            builder: (_, __) => const ChatbotPlaceholderScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'overhead',
                builder: (_, __) => const OverheadListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const OverheadFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (_, s) => OverheadFormScreen(
                      overheadId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              // The pricing sheet reaches Tambah Overhead from inside the
              // recipes tab as well — this alias keeps the URL working there.
              GoRoute(
                path: 'overhead/:id',
                redirect: (_, s) => '/profile/overhead/${s.pathParameters['id']}/edit',
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: Center(child: Text('Halaman tidak ditemukan: ${state.uri}')),
    ),
  );
}
