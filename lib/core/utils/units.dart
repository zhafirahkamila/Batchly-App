/// Unit vocabulary. The backend accepts many aliases (see backend
/// `utils/units.js`) but the app surfaces just five canonical units, each
/// mapped to its family + factor-to-base so we can reproduce the backend's
/// math client-side for guest mode / live preview.
enum UnitFamily { weight, volume, count }

class UnitDef {
  final String code;         // wire format sent to backend
  final String label;        // shown in UI
  final UnitFamily family;
  final double toBaseFactor; // multiply to convert into the family's base unit

  const UnitDef(this.code, this.label, this.family, this.toBaseFactor);
}

const List<UnitDef> kAppUnits = [
  UnitDef('gram', 'gram', UnitFamily.weight, 1),
  UnitDef('kg', 'kg', UnitFamily.weight, 1000),
  UnitDef('ml', 'ml', UnitFamily.volume, 1),
  UnitDef('liter', 'liter', UnitFamily.volume, 1000),
  UnitDef('pcs', 'pcs', UnitFamily.count, 1),
];

UnitDef? findUnit(String? code) {
  if (code == null) return null;
  final normalized = code.trim().toLowerCase();
  for (final u in kAppUnits) {
    if (u.code == normalized) return u;
  }
  // Try common aliases the backend accepts so an ingredient stored with an
  // odd unit still round-trips cleanly.
  const aliases = {
    'g': 'gram',
    'kilogram': 'kg',
    'milliliter': 'ml',
    'litre': 'liter',
    'l': 'liter',
    'piece': 'pcs',
    'pieces': 'pcs',
    'unit': 'pcs',
    'butir': 'pcs',
    'buah': 'pcs',
  };
  final alias = aliases[normalized];
  if (alias != null) return findUnit(alias);
  return null;
}

/// Compatible units of the same family (used to filter the unit dropdown when
/// the user picks an ingredient in a recipe row — e.g. an ingredient priced in
/// "kg" can only be consumed in weight units).
List<UnitDef> unitsForFamily(UnitFamily family) {
  return kAppUnits.where((u) => u.family == family).toList();
}
