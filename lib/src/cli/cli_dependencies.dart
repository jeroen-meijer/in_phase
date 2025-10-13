import 'dart:async';

import 'package:doos/doos.dart';
import 'package:rkdb_dart/src/database/database.exports.dart';
import 'package:rkdb_dart/src/misc/misc.dart';

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
