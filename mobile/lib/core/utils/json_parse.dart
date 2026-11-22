String jsonString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num || value is bool) return value.toString();
  return fallback;
}

String? jsonStringNullable(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int jsonInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double? jsonDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool jsonBool(Object? value) {
  return value == true || value == 1 || value == '1';
}

List<String> jsonStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}
