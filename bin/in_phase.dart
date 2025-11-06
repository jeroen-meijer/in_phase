import 'dart:io';

import 'package:in_phase/in_phase.dart';

Future<void> main(List<String> arguments) async {
  final exitCodeValue = await runInPhaseCli(arguments);
  exit(exitCodeValue);
}

