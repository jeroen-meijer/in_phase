import 'dart:async';
import 'dart:collection';

import 'package:dcli/dcli.dart';
import 'package:rkdb_dart/src/logger/logger.dart';
import 'package:uuid/uuid.dart';

void Function(String message, {Object? id, bool? isReturning}) createLogger(
  String context,
) {
  return (String message, {Object? id, bool? isReturning}) {
    log.debug(
      [
        blue('$RequestPool'),
        grey(context.padRight(15), level: 0),
        if (id case final id?)
          if (isReturning != null)
            yellow(id.toString())
          else
            orange(id.toString()),
        switch (isReturning) {
          true => green('←'),
          false => blue('→'),
          null => grey('・'),
        },
        message,
      ].join(' '),
    );
  };
}

/// A pool that manages concurrent requests with deduplication, retry logic,
/// and configurable concurrency limits.
///
/// The RequestPool:
/// - Deduplicates requests using provided identifiers
/// - Manages concurrent execution with a configurable limit
/// - Retries failed requests with exponential backoff
/// - Returns Futures that resolve when requests complete or fail after max
///   retries
final class RequestPool {
  RequestPool({
    this.maxConcurrent = 3,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.defaultTtl = const Duration(hours: 1),
  }) {
    final log = createLogger('constructor');
    log(
      'created RequestPool with maxConcurrent=$maxConcurrent, '
      'maxRetries=$maxRetries, retryDelay=$retryDelay',
    );
  }

  /// Maximum number of concurrent requests
  final int maxConcurrent;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Base delay between retries
  final Duration retryDelay;

  /// Default TTL for requests
  final Duration defaultTtl;

  /// Currently running requests by identifier
  final Map<Object, Future<dynamic>> _activeRequests = {};

  /// Per-identifier state (shared completer + versioning)
  final Map<Object, _RequestState> _states = {};

  /// Failed requests by identifier (for retryFailed functionality)
  final Map<Object, Future<dynamic>> _failedRequests = {};

  /// Successful requests by identifier (for TTL success caching)
  final Map<Object, Future<dynamic>> _successRequests = {};

  /// TTL timers for cached requests
  final Map<Object, Timer> _ttlTimers = {};

  /// Queue of pending requests waiting to be executed
  final Queue<_PendingRequest<dynamic>> _pendingQueue = Queue();

  /// Number of currently executing requests
  int _runningCount = 0;

  /// UUID generator for creating unique identifiers
  static const _uuid = Uuid();

  /// Adds a request to the pool with deduplication.
  ///
  /// If a request with the same [identifier] is already active or pending,
  /// returns the existing Future. Otherwise, queues the request for execution.
  ///
  /// The [requestFn] should be a function that returns a `Future<T>`.
  /// The [identifier] is used for deduplication - requests with the same
  /// identifier will be deduplicated. If not provided, each request will
  /// be treated as unique and no deduplication will occur.
  ///
  /// If [retryFailed] is true (default), failed requests will be retried.
  /// If false, previously failed requests will return the old error Future.
  ///
  /// If [force] is true, the request will always restart, even if one is
  /// already active. All consumers waiting for this identifier will get
  /// the new result.
  ///
  /// If [ttl] is provided, the cached request will be automatically removed
  /// after the specified duration expires.
  Future<T> request<T>(
    Future<T> Function() requestFn, {
    Object? identifier,
    bool retryFailed = true,
    bool force = false,
    Duration? ttl,
  }) {
    identifier ??= _uuid.v4();
    final log = createLogger('request');
    log(
      'requesting with force=$force, '
      'retryFailed=$retryFailed, '
      'ttl=${ttl == Duration.zero ? 'disabled' : ttl ?? 'default'}',
      id: identifier,
      isReturning: false,
    );

    ttl ??= defaultTtl;

    var state = _states[identifier];

    if (force) {
      log('forcing restart', id: identifier);
      if (state == null) {
        state = _RequestState(completer: Completer<Object?>(), version: 0);
        _states[identifier] = state;
        log('created new state', id: identifier);
      }
      state.version++;
      _failedRequests.remove(identifier);
      _successRequests.remove(identifier);
      _activeRequests[identifier] = state.completer.future.then<T>(
        (v) => v as T,
      );
      log('incremented version to ${state.version}', id: identifier);
    } else {
      if (state != null && _activeRequests.containsKey(identifier)) {
        log(
          'returning existing active request',
          id: identifier,
          isReturning: true,
        );
        return _activeRequests[identifier]! as Future<T>;
      }
      if (!retryFailed && _failedRequests.containsKey(identifier)) {
        log(
          'returning existing failed request',
          id: identifier,
          isReturning: true,
        );
        return _failedRequests[identifier]! as Future<T>;
      }
      if (_successRequests.containsKey(identifier)) {
        log(
          'returning cached successful request (within TTL)',
          id: identifier,
          isReturning: true,
        );
        return _successRequests[identifier]! as Future<T>;
      }
      if (state == null) {
        state = _RequestState(completer: Completer<Object?>(), version: 0);
        _states[identifier] = state;
        log('created new state', id: identifier);
      }
      if (!_activeRequests.containsKey(identifier)) {
        _activeRequests[identifier] = state.completer.future.then<T>(
          (v) => v as T,
        );
        log('registered active request', id: identifier);
      }
    }

    final key = identifier;
    _ttlTimers[key]?.cancel();
    if (ttl != Duration.zero) {
      _ttlTimers[key] = Timer(ttl, () {
        log('TTL expired', id: key);
        _clearCached(key);
      });
      log('set TTL timer, duration=$ttl', id: identifier);
    } else {
      _successRequests.remove(key);
    }

    final pendingRequest = _PendingRequest<T>(
      identifier: identifier,
      requestFn: requestFn,
      completer: state.completer,
      attemptsLeft: maxRetries + 1,
      version: state.version,
    );

    _pendingQueue.add(pendingRequest);
    log(
      'queued request, version=${state.version}, '
      'attemptsLeft=${maxRetries + 1}',
      id: identifier,
    );

    _processQueue();

    return _activeRequests[identifier]! as Future<T>;
  }

  /// Processes the queue of pending requests, respecting concurrency limits.
  void _processQueue() {
    while (_runningCount < maxConcurrent && _pendingQueue.isNotEmpty) {
      final pendingRequest = _pendingQueue.removeFirst();
      _executeRequest(pendingRequest);
    }
  }

  /// Executes a single request with retry logic.
  void _executeRequest<T>(_PendingRequest<T> pendingRequest) {
    final log = createLogger('_executeRequest');
    _runningCount++;
    log(
      'executing request, version=${pendingRequest.version}',
      id: pendingRequest.identifier,
    );

    final currentVersion = _states[pendingRequest.identifier]?.version;
    if (currentVersion != pendingRequest.version) {
      log(
        'request outdated, currentVersion=$currentVersion, '
        'requestVersion=${pendingRequest.version}',
        id: pendingRequest.identifier,
      );
      _runningCount--;
      _processQueue();
      return;
    }

    pendingRequest
        .requestFn()
        .then((result) {
          final v = _states[pendingRequest.identifier]?.version;
          if (v == pendingRequest.version) {
            log(
              'request completed successfully',
              id: pendingRequest.identifier,
            );
            pendingRequest.completer.complete(result);
            _cacheSuccess(pendingRequest.identifier);
          } else {
            log(
              'request completed but outdated, currentVersion=$v, '
              'requestVersion=${pendingRequest.version}',
              id: pendingRequest.identifier,
            );
            _runningCount--;
            _processQueue();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          final v = _states[pendingRequest.identifier]?.version;
          if (v != pendingRequest.version) {
            log(
              'request failed but outdated, currentVersion=$v, '
              'requestVersion=${pendingRequest.version}',
              id: pendingRequest.identifier,
            );
            _runningCount--;
            _processQueue();
            return;
          }

          pendingRequest.attemptsLeft--;
          log(
            'request failed, attemptsLeft=${pendingRequest.attemptsLeft}, '
            'error=$error',
            id: pendingRequest.identifier,
          );

          if (pendingRequest.attemptsLeft > 0) {
            log(
              'scheduling retry in $retryDelay',
              id: pendingRequest.identifier,
            );
            Timer(retryDelay, () {
              final vr = _states[pendingRequest.identifier]?.version;
              if (vr == pendingRequest.version) {
                log(
                  'retrying request',
                  id: pendingRequest.identifier,
                );
                _pendingQueue.addFirst(pendingRequest);
              } else {
                log(
                  'retry cancelled, currentVersion=$vr, '
                  'requestVersion=${pendingRequest.version}',
                  id: pendingRequest.identifier,
                );
              }
              _runningCount--;
              _processQueue();
            });
          } else {
            log(
              'request failed permanently, error=$error',
              id: pendingRequest.identifier,
            );
            pendingRequest.completer.completeError(error, stackTrace);
            _cleanupFailed(pendingRequest.identifier);
          }
        });
  }

  /// Caches a successful result under TTL and cleans up active state.
  void _cacheSuccess(Object identifier) {
    final log = createLogger('_cacheSuccess');
    final future = _activeRequests.remove(identifier);
    if (future != null && _ttlTimers.containsKey(identifier)) {
      _successRequests[identifier] = future;
      log('cached successful request (kept under TTL)', id: identifier);
    }

    _states.remove(identifier);
    _runningCount--;
    _processQueue();
  }

  /// Cleans up a failed request and moves it to failed requests map.
  void _cleanupFailed(Object identifier) {
    final log = createLogger('_cleanupFailed');
    log(
      'cleaning up failed request',
      id: identifier,
    );
    final future = _activeRequests.remove(identifier);
    if (future != null) {
      _failedRequests[identifier] = future;
      log(
        'moved failed request to failed cache',
        id: identifier,
      );
    }
    _successRequests.remove(identifier);
    _states.remove(identifier);
    _runningCount--;
    _processQueue();
  }

  /// Clears a cached request from all maps and cancels its TTL timer.
  void _clearCached(Object identifier) {
    final log = createLogger('_clearCached');
    log(
      'clearing cached request',
      id: identifier,
    );
    _activeRequests.remove(identifier);
    _failedRequests.remove(identifier);
    _successRequests.remove(identifier);
    _ttlTimers.remove(identifier)?.cancel();
    _states.remove(identifier);
  }

  /// Returns the number of currently active requests.
  int get activeRequestCount => _activeRequests.length;

  /// Returns the number of pending requests in the queue.
  int get pendingRequestCount => _pendingQueue.length;

  /// Returns the number of currently running requests.
  int get runningRequestCount => _runningCount;

  /// Clears all pending requests and cancels active ones.
  /// NOTE(jeroen-meijer): Use with caution - this will cause all pending
  /// and active requests to complete with a StateError.
  void clear() {
    final log = createLogger('clear');
    log('clearing all requests');
    while (_pendingQueue.isNotEmpty) {
      final pending = _pendingQueue.removeFirst();
      pending.completer.completeError(
        StateError('RequestPool was cleared'),
      );
    }

    _activeRequests.clear();
    _failedRequests.clear();
    _successRequests.clear();

    for (final timer in _ttlTimers.values) {
      timer.cancel();
    }
    _ttlTimers.clear();

    _runningCount = 0;
    log('cleared all requests');
  }
}

/// Internal class representing a pending request.
final class _PendingRequest<T> {
  _PendingRequest({
    required this.identifier,
    required this.requestFn,
    required this.completer,
    required this.attemptsLeft,
    required this.version,
  });

  final Object identifier;
  final Future<T> Function() requestFn;
  final Completer<Object?> completer;
  int attemptsLeft;
  final int version;
}

final class _RequestState {
  _RequestState({
    required this.completer,
    required this.version,
  });

  final Completer<Object?> completer;
  int version;
}
