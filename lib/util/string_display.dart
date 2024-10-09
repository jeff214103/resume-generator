String stringConversion(String? value, String? missingText) {
  if (value == null || value.isEmpty == true) {
    return missingText??'Missing';
  }
  return value;
}