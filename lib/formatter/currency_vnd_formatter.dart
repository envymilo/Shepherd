import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyVNDFormatter extends TextInputFormatter {
  final int maxValue;

  CurrencyVNDFormatter({required this.maxValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Convert to integer
    int? value = newText.isEmpty ? 0 : int.parse(newText);

    // Cap the value at maxValue
    value = value > maxValue ? maxValue : value;

    // Format the number with thousands separator
    final formatter = NumberFormat('#,###', 'vi_VN');
    String formattedValue = formatter.format(value);

    // Add VND suffix
    String finalText = '$formattedValue VND';

    // Calculate cursor position - place it before " VND"
    int cursorPosition = finalText.length - 4; // 4 is length of " VND"

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}
