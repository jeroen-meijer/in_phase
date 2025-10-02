import 'dart:convert';

String jsonEncodeWithIndent(Object object) {
  return const JsonEncoder.withIndent('  ').convert(object);
}
