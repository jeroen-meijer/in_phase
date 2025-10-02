import 'dart:io';

import 'package:rkdb_dart/rkdb_dart.dart';

Future<void> main(List<String> arguments) async {
  final exitCodeValue = await runRkdbCli(arguments);
  exit(exitCodeValue);
}
