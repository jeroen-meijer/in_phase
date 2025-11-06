import 'dart:async';

import 'package:doos/doos.dart';
import 'package:in_phase/src/database/database.exports.dart';
import 'package:in_phase/src/misc/misc.dart';

Future<T> runWithCliDependencies<T>(FutureOr<T> Function() fn) async {
  final database = await createDatabase();

  try {
    return await Zonable.injectMany(
      [
        Env.fromHostEnvironment(),
        Doos(
          adapter: await DoosJsonStorageAdapter.create(
            file: Constants.cacheFile,
            clearFileOnReadError: true,
          ),
        ),
        RequestPool(),
        database,
      ],
      fn,
    );
  } finally {
    await database.close();
  }
}
