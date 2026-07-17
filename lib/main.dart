import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/prefs_store.dart';
import 'core/storage/secure_token_store.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/guest_data_store.dart';
import 'providers/ingredients_provider.dart';
import 'providers/overhead_provider.dart';
import 'providers/pricing_provider.dart';
import 'providers/recipes_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/ingredients_service.dart';
import 'services/overhead_service.dart';
import 'services/pricing_service.dart';
import 'services/profile_service.dart';
import 'services/recipes_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---- Singletons that don't depend on Provider ----------------------------
  final api = ApiClient();
  final tokenStore = SecureTokenStore();
  final prefsStore = PrefsStore();
  final guest = GuestDataStore();
  final authService = AuthService(api);
  final profileService = ProfileService(api);

  final themeProvider = ThemeProvider(prefsStore);
  await themeProvider.load();

  final authProvider = AuthProvider(
    authService: authService,
    api: api,
    tokenStore: tokenStore,
  );

  runApp(
    MultiProvider(
      providers: [
        // Auth is at the top because every feature provider reads its
        // isGuest flag through the service layer.
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<GuestDataStore>.value(value: guest),

        Provider<ApiClient>.value(value: api),
        Provider<ProfileService>.value(value: profileService),

        // Feature providers wrap service instances that already know how to
        // branch between the real API and the guest store.
        ChangeNotifierProvider<IngredientsProvider>(
          create: (_) => IngredientsProvider(
            IngredientsService(api, authProvider, guest),
          ),
        ),
        ChangeNotifierProvider<OverheadProvider>(
          create: (_) => OverheadProvider(
            OverheadService(api, authProvider, guest),
          ),
        ),
        ChangeNotifierProvider<RecipesProvider>(
          create: (_) => RecipesProvider(
            RecipesService(api, authProvider, guest),
          ),
        ),
        ChangeNotifierProvider<PricingProvider>(
          create: (_) => PricingProvider(
            PricingService(api, authProvider, guest),
          ),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(
            DashboardService(api, authProvider, guest),
          ),
        ),
      ],
      child: const BatchlyApp(),
    ),
  );
}
