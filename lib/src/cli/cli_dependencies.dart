import 'dart:async';

import 'package:doos/doos.dart';
import 'package:rkdb_dart/src/misc/misc.dart';

Future<T> runWithCliDependencies<T>(FutureOr<T> Function() fn) async {
  return Zonable.injectMany(
    [
      Env.fromHostEnvironment(),
      Doos(
        adapter: await DoosJsonStorageAdapter.create(
          file: Constants.cacheFile,
          clearFileOnReadError: true,
        ),
      ),
      RequestPool(),
    ],
    fn,
  );
}
