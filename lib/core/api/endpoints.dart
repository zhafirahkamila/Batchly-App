/// Single source of truth for backend paths. Keep in sync with
/// `batchly_backend/src/app.js` and route files.
class Endpoints {
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authMe = '/api/auth/me';

  static const ingredients = '/api/ingredients';
  static String ingredientById(int id) => '/api/ingredients/$id';

  static const recipes = '/api/recipes';
  static String recipeById(int id) => '/api/recipes/$id';
  static String recipeCalculate(int id) => '/api/recipes/$id/calculate';
  static String recipePricing(int id) => '/api/recipes/$id/pricing';

  static const overhead = '/api/overhead';
  static String overheadById(int id) => '/api/overhead/$id';

  static const dashboardSummary = '/api/dashboard/summary';

  static const profile = '/api/profile';
}
