import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/ingredient.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_data_store.dart';

/// Thin wrapper that talks to the real API when authenticated and to
/// [GuestDataStore] in guest mode. This is the dual-path pattern each feature
/// uses so screens don't need to know whether the current session is guest
/// or authed.
class IngredientsService {
  final ApiClient _api;
  final AuthProvider _auth;
  final GuestDataStore _guest;

  IngredientsService(this._api, this._auth, this._guest);

  Future<List<Ingredient>> list() async {
    if (_auth.isGuest) return _guest.ingredients;
    final res = await _api.get(Endpoints.ingredients) as List;
    return res.cast<Map<String, dynamic>>().map(Ingredient.fromJson).toList();
  }

  Future<Ingredient> create({
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) async {
    if (_auth.isGuest) {
      return _guest.addIngredient(
        name: name,
        purchasePrice: purchasePrice,
        purchaseQty: purchaseQty,
        purchaseUnit: purchaseUnit,
        category: category,
      );
    }
    final res = await _api.post(Endpoints.ingredients, body: {
      'name': name,
      'purchase_price': purchasePrice,
      'purchase_qty': purchaseQty,
      'purchase_unit': purchaseUnit,
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return Ingredient.fromJson(res as Map<String, dynamic>);
  }

  Future<Ingredient> update(int id, {
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) async {
    if (_auth.isGuest) {
      return _guest.updateIngredient(
        id,
        name: name,
        purchasePrice: purchasePrice,
        purchaseQty: purchaseQty,
        purchaseUnit: purchaseUnit,
        category: category,
      );
    }
    final res = await _api.put(Endpoints.ingredientById(id), body: {
      'name': name,
      'purchase_price': purchasePrice,
      'purchase_qty': purchaseQty,
      'purchase_unit': purchaseUnit,
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return Ingredient.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    if (_auth.isGuest) {
      _guest.deleteIngredient(id);
      return;
    }
    await _api.delete(Endpoints.ingredientById(id));
  }
}
