import 'package:flutter/material.dart';

import '../core/utils/units.dart';

class UnitDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final UnitFamily? restrictToFamily;
  final String label;

  const UnitDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.restrictToFamily,
    this.label = 'Satuan',
  });

  @override
  Widget build(BuildContext context) {
    final options = restrictToFamily == null
        ? kAppUnits
        : unitsForFamily(restrictToFamily!);
    // Normalize the incoming value to a canonical code we actually render.
    final normalized = findUnit(value)?.code;
    final resolved =
        options.any((u) => u.code == normalized) ? normalized : options.first.code;

    return DropdownButtonFormField<String>(
      value: resolved,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((u) => DropdownMenuItem(value: u.code, child: Text(u.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
