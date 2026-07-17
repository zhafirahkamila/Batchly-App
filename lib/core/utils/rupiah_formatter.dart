import 'package:intl/intl.dart';

/// Formats numbers as Indonesian rupiah (Rp 12.500). Non-finite values render
/// as "-" so a card doesn't display "NaN" when a recipe has no pricing yet.
String formatRupiah(num? value, {int decimalDigits = 0}) {
  if (value == null || !value.isFinite) return '-';
  final f = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: decimalDigits,
  );
  return f.format(value);
}

/// Parse a user-typed rupiah string ("Rp 12.500", "12500", "12.500") into an
/// int. Returns null if unparseable.
int? parseRupiah(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
