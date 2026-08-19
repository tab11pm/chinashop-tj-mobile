import 'package:flutter/services.dart';

const tajikPhonePrefix = '+992';
const tajikLocalPhoneLength = 9;

String tajikLocalPhoneDigits(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('992') && digits.length > tajikLocalPhoneLength) {
    digits = digits.substring(3);
  }
  if (digits.length > tajikLocalPhoneLength) {
    digits = digits.substring(0, tajikLocalPhoneLength);
  }
  return digits;
}

String tajikPhoneToE164(String localDigits) {
  return '$tajikPhonePrefix${tajikLocalPhoneDigits(localDigits)}';
}

class TajikPhoneInputFormatter extends TextInputFormatter {
  const TajikPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = tajikLocalPhoneDigits(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
