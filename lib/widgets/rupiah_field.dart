import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/utils/rupiah_formatter.dart';

/// TextField that formats input as rupiah with thousands separators while the
/// user types. Emits raw ints via [onChanged].
class RupiahField extends StatefulWidget {
  final String label;
  final int? initialValue;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  const RupiahField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<RupiahField> createState() => _RupiahFieldState();
}

class _RupiahFieldState extends State<RupiahField> {
  late TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : NumberFormat.decimalPattern('id_ID').format(widget.initialValue),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _c,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: 'Rp ',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: widget.validator == null
          ? null
          : (raw) => widget.validator!(parseRupiah(raw ?? '')),
      onChanged: (raw) {
        final n = parseRupiah(raw);
        widget.onChanged(n);
        if (n == null) return;
        final formatted = NumberFormat.decimalPattern('id_ID').format(n);
        if (formatted != raw) {
          _c.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
    );
  }
}
