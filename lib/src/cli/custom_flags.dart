import 'package:args/args.dart';

extension CustomFlags on ArgParser {
  void addVerboseFlag() {
    addFlag(
      'verbose',
      help: 'Print verbose output.',
      negatable: false,
    );
  }
}
