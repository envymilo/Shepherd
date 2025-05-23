import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter extends TextInputFormatter {
  final Function(String formattedValue, String rawValue) onFormatted;

  CurrencyFormatter(this.onFormatted);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Check if we are backspacing
    bool isBackspace = newValue.text.length < oldValue.text.length;

    // Remove spaces for the raw value
    final rawValue = newValue.text.replaceAll(" ", "");

    // Allow empty input when user deletes all characters
    if (rawValue.isEmpty) {
      onFormatted("", "");
      return const TextEditingValue(
        text: "",
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse the raw input to an integer for formatting
    final intValue = int.tryParse(rawValue) ?? 0;

    // Format the integer with thousands separators
    final formattedValue = NumberFormat.currency(
      locale: 'vi',
      symbol: 'vnd',
      decimalDigits: 0,
    ).format(intValue).replaceAll(",", " "); // Replace commas with spaces

    // Call the callback to update the raw and formatted values
    onFormatted(formattedValue, rawValue);

    // Adjust cursor position if backspacing
    int cursorPosition = newValue.selection.baseOffset;
    if (isBackspace) {
      cursorPosition =
          formattedValue.length - (oldValue.text.length - cursorPosition);
    } else {
      cursorPosition = formattedValue.length;
    }

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

String formatCurrency(int? number) {
  if (number == null) {
    return '0'; // or an empty string, or another default value
  }
  final numberString = number.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < numberString.length; i++) {
    if (i > 0 && (numberString.length - i) % 3 == 0) {
      buffer.write('.'); // Add a dot every three digits from the right
    }
    buffer.write(numberString[i]);
  }

  return buffer.toString();
}
