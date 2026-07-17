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
      GoRoute(
        path: '/splash',
        // No transition on splash: it hard-redirects away as soon as auth
        // bootstraps; a fade would just add flicker.
        builder: (_, _) => const SplashGate(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, s) => _fadePage(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (ctx, s) => _fadePage(s, const RegisterScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            RootShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (ctx, s) => _fadePage(s, const DashboardScreen()),
          ),
          GoRoute(
            path: '/ingredients',
            pageBuilder: (ctx, s) => _fadePage(s, const IngredientsListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (ctx, s) => _fadePage(s, const IngredientFormScreen()),
              ),
              GoRoute(
                path: ':id/edit',
                pageBuilder: (ctx, s) => _fadePage(
                  s,
                  IngredientFormScreen(
                    ingredientId: int.parse(s.pathParameters['id']!),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/recipes',
            pageBuilder: (ctx, s) => _fadePage(s, const RecipesListScreen()),
            routes: [
              GoRoute(
                path: 'new',
                pageBuilder: (ctx, s) => _fadePage(s, const RecipeFormScreen()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (ctx, s) => _fadePage(
                  s,
                  RecipeDetailScreen(
                    recipeId: int.parse(s.pathParameters['id']!),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (ctx, s) => _fadePage(
                      s,
                      RecipeFormScreen(
                        recipeId: int.parse(s.pathParameters['id']!),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'pricing',
                    pageBuilder: (ctx, s) => _fadePage(
                      s,
                      PricingSheet(
                        recipeId: int.parse(s.pathParameters['id']!),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/chatbot',
            pageBuilder: (ctx, s) => _fadePage(s, const ChatbotPlaceholderScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (ctx, s) => _fadePage(s, const ProfileScreen()),
            routes: [
              GoRoute(
                path: 'overhead',
                pageBuilder: (ctx, s) => _fadePage(s, const OverheadListScreen()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (ctx, s) => _fadePage(s, const OverheadFormScreen()),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    pageBuilder: (ctx, s) => _fadePage(
                      s,
                      OverheadFormScreen(
                        overheadId: int.parse(s.pathParameters['id']!),
                      ),
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
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}

CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
