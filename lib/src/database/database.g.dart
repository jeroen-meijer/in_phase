// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedPlaylistsTable extends CachedPlaylists
    with TableInfo<$CachedPlaylistsTable, CachedPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, snapshotId, name, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedPlaylistsTable createAlias(String alias) {
    return $CachedPlaylistsTable(attachedDatabase, alias);
  }
}

class CachedPlaylist extends DataClass implements Insertable<CachedPlaylist> {
  /// Spotify playlist ID (primary key).
  final String id;

  /// Snapshot ID for change detection.
  final String snapshotId;

  /// Playlist name.
  final String name;

  /// When this was cached.
  final DateTime cachedAt;
  const CachedPlaylist({
    required this.id,
    required this.snapshotId,
    required this.name,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return CachedPlaylistsCompanion(
      id: Value(id),
      snapshotId: Value(snapshotId),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPlaylist(
      id: serializer.fromJson<String>(json['id']),
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'snapshotId': serializer.toJson<String>(snapshotId),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedPlaylist copyWith({
    String? id,
    String? snapshotId,
    String? name,
    DateTime? cachedAt,
  }) => CachedPlaylist(
    id: id ?? this.id,
    snapshotId: snapshotId ?? this.snapshotId,
    name: name ?? this.name,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedPlaylist copyWithCompanion(CachedPlaylistsCompanion data) {
    return CachedPlaylist(
      id: data.id.present ? data.id.value : this.id,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlaylist(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, snapshotId, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPlaylist &&
          other.id == this.id &&
          other.snapshotId == this.snapshotId &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class CachedPlaylistsCompanion extends UpdateCompanion<CachedPlaylist> {
  final Value<String> id;
  final Value<String> snapshotId;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedPlaylistsCompanion({
    this.id = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPlaylistsCompanion.insert({
    required String id,
    required String snapshotId,
    required String name,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       snapshotId = Value(snapshotId),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedPlaylist> custom({
    Expression<String>? id,
    Expression<String>? snapshotId,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? snapshotId,
    Value<String>? name,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedPlaylistsCompanion(
      id: id ?? this.id,
      snapshotId: snapshotId ?? this.snapshotId,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPlaylistTracksTable extends CachedPlaylistTracks
    with TableInfo<$CachedPlaylistTracksTable, CachedPlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_playlists (id)',
    ),
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNamesMeta = const VerificationMeta(
    'artistNames',
  );
  @override
  late final GeneratedColumn<String> artistNames = GeneratedColumn<String>(
    'artist_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    playlistId,
    uri,
    name,
    artistNames,
    addedAt,
    albumId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist_names')) {
      context.handle(
        _artistNamesMeta,
        artistNames.isAcceptableOrUnknown(
          data['artist_names']!,
          _artistNamesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistNamesMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, playlistId, addedAt};
  @override
  CachedPlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPlaylistTrack(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artistNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_names'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
    );
  }

  @override
  $CachedPlaylistTracksTable createAlias(String alias) {
    return $CachedPlaylistTracksTable(attachedDatabase, alias);
  }
}

class CachedPlaylistTrack extends DataClass
    implements Insertable<CachedPlaylistTrack> {
  /// Spotify track ID.
  final String trackId;

  /// Playlist ID (foreign key).
  final String playlistId;

  /// Track URI.
  final String uri;

  /// Track name.
  final String name;

  /// Artist names (JSON array).
  final String artistNames;

  /// When track was added to playlist.
  final DateTime addedAt;

  /// Album ID (optional).
  final String? albumId;
  const CachedPlaylistTrack({
    required this.trackId,
    required this.playlistId,
    required this.uri,
    required this.name,
    required this.artistNames,
    required this.addedAt,
    this.albumId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['playlist_id'] = Variable<String>(playlistId);
    map['uri'] = Variable<String>(uri);
    map['name'] = Variable<String>(name);
    map['artist_names'] = Variable<String>(artistNames);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    return map;
  }

  CachedPlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return CachedPlaylistTracksCompanion(
      trackId: Value(trackId),
      playlistId: Value(playlistId),
      uri: Value(uri),
      name: Value(name),
      artistNames: Value(artistNames),
      addedAt: Value(addedAt),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
    );
  }

  factory CachedPlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPlaylistTrack(
      trackId: serializer.fromJson<String>(json['trackId']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      uri: serializer.fromJson<String>(json['uri']),
      name: serializer.fromJson<String>(json['name']),
      artistNames: serializer.fromJson<String>(json['artistNames']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      albumId: serializer.fromJson<String?>(json['albumId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'playlistId': serializer.toJson<String>(playlistId),
      'uri': serializer.toJson<String>(uri),
      'name': serializer.toJson<String>(name),
      'artistNames': serializer.toJson<String>(artistNames),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'albumId': serializer.toJson<String?>(albumId),
    };
  }

  CachedPlaylistTrack copyWith({
    String? trackId,
    String? playlistId,
    String? uri,
    String? name,
    String? artistNames,
    DateTime? addedAt,
    Value<String?> albumId = const Value.absent(),
  }) => CachedPlaylistTrack(
    trackId: trackId ?? this.trackId,
    playlistId: playlistId ?? this.playlistId,
    uri: uri ?? this.uri,
    name: name ?? this.name,
    artistNames: artistNames ?? this.artistNames,
    addedAt: addedAt ?? this.addedAt,
    albumId: albumId.present ? albumId.value : this.albumId,
  );
  CachedPlaylistTrack copyWithCompanion(CachedPlaylistTracksCompanion data) {
    return CachedPlaylistTrack(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      uri: data.uri.present ? data.uri.value : this.uri,
      name: data.name.present ? data.name.value : this.name,
      artistNames: data.artistNames.present
          ? data.artistNames.value
          : this.artistNames,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlaylistTrack(')
          ..write('trackId: $trackId, ')
          ..write('playlistId: $playlistId, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('addedAt: $addedAt, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    playlistId,
    uri,
    name,
    artistNames,
    addedAt,
    albumId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPlaylistTrack &&
          other.trackId == this.trackId &&
          other.playlistId == this.playlistId &&
          other.uri == this.uri &&
          other.name == this.name &&
          other.artistNames == this.artistNames &&
          other.addedAt == this.addedAt &&
          other.albumId == this.albumId);
}

class CachedPlaylistTracksCompanion
    extends UpdateCompanion<CachedPlaylistTrack> {
  final Value<String> trackId;
  final Value<String> playlistId;
  final Value<String> uri;
  final Value<String> name;
  final Value<String> artistNames;
  final Value<DateTime> addedAt;
  final Value<String?> albumId;
  final Value<int> rowid;
  const CachedPlaylistTracksCompanion({
    this.trackId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.uri = const Value.absent(),
    this.name = const Value.absent(),
    this.artistNames = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.albumId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPlaylistTracksCompanion.insert({
    required String trackId,
    required String playlistId,
    required String uri,
    required String name,
    required String artistNames,
    required DateTime addedAt,
    this.albumId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       playlistId = Value(playlistId),
       uri = Value(uri),
       name = Value(name),
       artistNames = Value(artistNames),
       addedAt = Value(addedAt);
  static Insertable<CachedPlaylistTrack> custom({
    Expression<String>? trackId,
    Expression<String>? playlistId,
    Expression<String>? uri,
    Expression<String>? name,
    Expression<String>? artistNames,
    Expression<DateTime>? addedAt,
    Expression<String>? albumId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (uri != null) 'uri': uri,
      if (name != null) 'name': name,
      if (artistNames != null) 'artist_names': artistNames,
      if (addedAt != null) 'added_at': addedAt,
      if (albumId != null) 'album_id': albumId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPlaylistTracksCompanion copyWith({
    Value<String>? trackId,
    Value<String>? playlistId,
    Value<String>? uri,
    Value<String>? name,
    Value<String>? artistNames,
    Value<DateTime>? addedAt,
    Value<String?>? albumId,
    Value<int>? rowid,
  }) {
    return CachedPlaylistTracksCompanion(
      trackId: trackId ?? this.trackId,
      playlistId: playlistId ?? this.playlistId,
      uri: uri ?? this.uri,
      name: name ?? this.name,
      artistNames: artistNames ?? this.artistNames,
      addedAt: addedAt ?? this.addedAt,
      albumId: albumId ?? this.albumId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artistNames.present) {
      map['artist_names'] = Variable<String>(artistNames.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPlaylistTracksCompanion(')
          ..write('trackId: $trackId, ')
          ..write('playlistId: $playlistId, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('addedAt: $addedAt, ')
          ..write('albumId: $albumId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAlbumsTable extends CachedAlbums
    with TableInfo<$CachedAlbumsTable, CachedAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistNamesMeta = const VerificationMeta(
    'artistNames',
  );
  @override
  late final GeneratedColumn<String> artistNames = GeneratedColumn<String>(
    'artist_names',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    releaseDate,
    label,
    artistNames,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAlbum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('artist_names')) {
      context.handle(
        _artistNamesMeta,
        artistNames.isAcceptableOrUnknown(
          data['artist_names']!,
          _artistNamesMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAlbum(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      artistNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_names'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedAlbumsTable createAlias(String alias) {
    return $CachedAlbumsTable(attachedDatabase, alias);
  }
}

class CachedAlbum extends DataClass implements Insertable<CachedAlbum> {
  /// Spotify album ID (primary key).
  final String id;

  /// Album name.
  final String name;

  /// Release date string.
  final String? releaseDate;

  /// Label name.
  final String? label;

  /// Artist names (JSON array).
  final String? artistNames;

  /// When this was cached.
  final DateTime cachedAt;
  const CachedAlbum({
    required this.id,
    required this.name,
    this.releaseDate,
    this.label,
    this.artistNames,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || artistNames != null) {
      map['artist_names'] = Variable<String>(artistNames);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedAlbumsCompanion toCompanion(bool nullToAbsent) {
    return CachedAlbumsCompanion(
      id: Value(id),
      name: Value(name),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      artistNames: artistNames == null && nullToAbsent
          ? const Value.absent()
          : Value(artistNames),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedAlbum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAlbum(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      label: serializer.fromJson<String?>(json['label']),
      artistNames: serializer.fromJson<String?>(json['artistNames']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'label': serializer.toJson<String?>(label),
      'artistNames': serializer.toJson<String?>(artistNames),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedAlbum copyWith({
    String? id,
    String? name,
    Value<String?> releaseDate = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> artistNames = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedAlbum(
    id: id ?? this.id,
    name: name ?? this.name,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    label: label.present ? label.value : this.label,
    artistNames: artistNames.present ? artistNames.value : this.artistNames,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedAlbum copyWithCompanion(CachedAlbumsCompanion data) {
    return CachedAlbum(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      label: data.label.present ? data.label.value : this.label,
      artistNames: data.artistNames.present
          ? data.artistNames.value
          : this.artistNames,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAlbum(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('label: $label, ')
          ..write('artistNames: $artistNames, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, releaseDate, label, artistNames, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAlbum &&
          other.id == this.id &&
          other.name == this.name &&
          other.releaseDate == this.releaseDate &&
          other.label == this.label &&
          other.artistNames == this.artistNames &&
          other.cachedAt == this.cachedAt);
}

class CachedAlbumsCompanion extends UpdateCompanion<CachedAlbum> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> releaseDate;
  final Value<String?> label;
  final Value<String?> artistNames;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedAlbumsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.label = const Value.absent(),
    this.artistNames = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAlbumsCompanion.insert({
    required String id,
    required String name,
    this.releaseDate = const Value.absent(),
    this.label = const Value.absent(),
    this.artistNames = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedAlbum> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? releaseDate,
    Expression<String>? label,
    Expression<String>? artistNames,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (releaseDate != null) 'release_date': releaseDate,
      if (label != null) 'label': label,
      if (artistNames != null) 'artist_names': artistNames,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAlbumsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? releaseDate,
    Value<String?>? label,
    Value<String?>? artistNames,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedAlbumsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      releaseDate: releaseDate ?? this.releaseDate,
      label: label ?? this.label,
      artistNames: artistNames ?? this.artistNames,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (artistNames.present) {
      map['artist_names'] = Variable<String>(artistNames.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAlbumsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('label: $label, ')
          ..write('artistNames: $artistNames, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackAlbumMappingsTable extends TrackAlbumMappings
    with TableInfo<$TrackAlbumMappingsTable, TrackAlbumMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackAlbumMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_albums (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, albumId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_album_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackAlbumMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, albumId};
  @override
  TrackAlbumMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackAlbumMapping(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
    );
  }

  @override
  $TrackAlbumMappingsTable createAlias(String alias) {
    return $TrackAlbumMappingsTable(attachedDatabase, alias);
  }
}

class TrackAlbumMapping extends DataClass
    implements Insertable<TrackAlbumMapping> {
  /// Spotify track ID.
  final String trackId;

  /// Spotify album ID.
  final String albumId;
  const TrackAlbumMapping({required this.trackId, required this.albumId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['album_id'] = Variable<String>(albumId);
    return map;
  }

  TrackAlbumMappingsCompanion toCompanion(bool nullToAbsent) {
    return TrackAlbumMappingsCompanion(
      trackId: Value(trackId),
      albumId: Value(albumId),
    );
  }

  factory TrackAlbumMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackAlbumMapping(
      trackId: serializer.fromJson<String>(json['trackId']),
      albumId: serializer.fromJson<String>(json['albumId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'albumId': serializer.toJson<String>(albumId),
    };
  }

  TrackAlbumMapping copyWith({String? trackId, String? albumId}) =>
      TrackAlbumMapping(
        trackId: trackId ?? this.trackId,
        albumId: albumId ?? this.albumId,
      );
  TrackAlbumMapping copyWithCompanion(TrackAlbumMappingsCompanion data) {
    return TrackAlbumMapping(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackAlbumMapping(')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, albumId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackAlbumMapping &&
          other.trackId == this.trackId &&
          other.albumId == this.albumId);
}

class TrackAlbumMappingsCompanion extends UpdateCompanion<TrackAlbumMapping> {
  final Value<String> trackId;
  final Value<String> albumId;
  final Value<int> rowid;
  const TrackAlbumMappingsCompanion({
    this.trackId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrackAlbumMappingsCompanion.insert({
    required String trackId,
    required String albumId,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       albumId = Value(albumId);
  static Insertable<TrackAlbumMapping> custom({
    Expression<String>? trackId,
    Expression<String>? albumId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (albumId != null) 'album_id': albumId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrackAlbumMappingsCompanion copyWith({
    Value<String>? trackId,
    Value<String>? albumId,
    Value<int>? rowid,
  }) {
    return TrackAlbumMappingsCompanion(
      trackId: trackId ?? this.trackId,
      albumId: albumId ?? this.albumId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackAlbumMappingsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('albumId: $albumId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedArtistsTable extends CachedArtists
    with TableInfo<$CachedArtistsTable, CachedArtist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedArtist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedArtist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedArtist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedArtistsTable createAlias(String alias) {
    return $CachedArtistsTable(attachedDatabase, alias);
  }
}

class CachedArtist extends DataClass implements Insertable<CachedArtist> {
  /// Spotify artist ID (primary key).
  final String id;

  /// Artist name.
  final String name;

  /// When this was cached.
  final DateTime cachedAt;
  const CachedArtist({
    required this.id,
    required this.name,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedArtistsCompanion toCompanion(bool nullToAbsent) {
    return CachedArtistsCompanion(
      id: Value(id),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedArtist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedArtist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedArtist copyWith({String? id, String? name, DateTime? cachedAt}) =>
      CachedArtist(
        id: id ?? this.id,
        name: name ?? this.name,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedArtist copyWithCompanion(CachedArtistsCompanion data) {
    return CachedArtist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedArtist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedArtist &&
          other.id == this.id &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class CachedArtistsCompanion extends UpdateCompanion<CachedArtist> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedArtistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedArtistsCompanion.insert({
    required String id,
    required String name,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<CachedArtist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedArtistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedArtistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedArtistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedArtistAlbumListsTable extends CachedArtistAlbumLists
    with TableInfo<$CachedArtistAlbumListsTable, CachedArtistAlbumList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedArtistAlbumListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_artists (id)',
    ),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [artistId, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_artist_album_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedArtistAlbumList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {artistId};
  @override
  CachedArtistAlbumList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedArtistAlbumList(
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedArtistAlbumListsTable createAlias(String alias) {
    return $CachedArtistAlbumListsTable(attachedDatabase, alias);
  }
}

class CachedArtistAlbumList extends DataClass
    implements Insertable<CachedArtistAlbumList> {
  /// Spotify artist ID (primary key, foreign key).
  final String artistId;

  /// When this list was cached.
  final DateTime cachedAt;
  const CachedArtistAlbumList({required this.artistId, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artist_id'] = Variable<String>(artistId);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedArtistAlbumListsCompanion toCompanion(bool nullToAbsent) {
    return CachedArtistAlbumListsCompanion(
      artistId: Value(artistId),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedArtistAlbumList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedArtistAlbumList(
      artistId: serializer.fromJson<String>(json['artistId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artistId': serializer.toJson<String>(artistId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedArtistAlbumList copyWith({String? artistId, DateTime? cachedAt}) =>
      CachedArtistAlbumList(
        artistId: artistId ?? this.artistId,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedArtistAlbumList copyWithCompanion(
    CachedArtistAlbumListsCompanion data,
  ) {
    return CachedArtistAlbumList(
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedArtistAlbumList(')
          ..write('artistId: $artistId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(artistId, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedArtistAlbumList &&
          other.artistId == this.artistId &&
          other.cachedAt == this.cachedAt);
}

class CachedArtistAlbumListsCompanion
    extends UpdateCompanion<CachedArtistAlbumList> {
  final Value<String> artistId;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedArtistAlbumListsCompanion({
    this.artistId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedArtistAlbumListsCompanion.insert({
    required String artistId,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : artistId = Value(artistId),
       cachedAt = Value(cachedAt);
  static Insertable<CachedArtistAlbumList> custom({
    Expression<String>? artistId,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artistId != null) 'artist_id': artistId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedArtistAlbumListsCompanion copyWith({
    Value<String>? artistId,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedArtistAlbumListsCompanion(
      artistId: artistId ?? this.artistId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedArtistAlbumListsCompanion(')
          ..write('artistId: $artistId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistAlbumRelationshipsTable extends ArtistAlbumRelationships
    with TableInfo<$ArtistAlbumRelationshipsTable, ArtistAlbumRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistAlbumRelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_artists (id)',
    ),
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_albums (id)',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [artistId, albumId, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artist_album_relationships';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtistAlbumRelationship> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_artistIdMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {artistId, albumId};
  @override
  ArtistAlbumRelationship map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtistAlbumRelationship(
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $ArtistAlbumRelationshipsTable createAlias(String alias) {
    return $ArtistAlbumRelationshipsTable(attachedDatabase, alias);
  }
}

class ArtistAlbumRelationship extends DataClass
    implements Insertable<ArtistAlbumRelationship> {
  /// Spotify artist ID.
  final String artistId;

  /// Spotify album ID.
  final String albumId;

  /// Order in the artist's album list.
  final int orderIndex;
  const ArtistAlbumRelationship({
    required this.artistId,
    required this.albumId,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['artist_id'] = Variable<String>(artistId);
    map['album_id'] = Variable<String>(albumId);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  ArtistAlbumRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return ArtistAlbumRelationshipsCompanion(
      artistId: Value(artistId),
      albumId: Value(albumId),
      orderIndex: Value(orderIndex),
    );
  }

  factory ArtistAlbumRelationship.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtistAlbumRelationship(
      artistId: serializer.fromJson<String>(json['artistId']),
      albumId: serializer.fromJson<String>(json['albumId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'artistId': serializer.toJson<String>(artistId),
      'albumId': serializer.toJson<String>(albumId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  ArtistAlbumRelationship copyWith({
    String? artistId,
    String? albumId,
    int? orderIndex,
  }) => ArtistAlbumRelationship(
    artistId: artistId ?? this.artistId,
    albumId: albumId ?? this.albumId,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  ArtistAlbumRelationship copyWithCompanion(
    ArtistAlbumRelationshipsCompanion data,
  ) {
    return ArtistAlbumRelationship(
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtistAlbumRelationship(')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(artistId, albumId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtistAlbumRelationship &&
          other.artistId == this.artistId &&
          other.albumId == this.albumId &&
          other.orderIndex == this.orderIndex);
}

class ArtistAlbumRelationshipsCompanion
    extends UpdateCompanion<ArtistAlbumRelationship> {
  final Value<String> artistId;
  final Value<String> albumId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const ArtistAlbumRelationshipsCompanion({
    this.artistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtistAlbumRelationshipsCompanion.insert({
    required String artistId,
    required String albumId,
    required int orderIndex,
    this.rowid = const Value.absent(),
  }) : artistId = Value(artistId),
       albumId = Value(albumId),
       orderIndex = Value(orderIndex);
  static Insertable<ArtistAlbumRelationship> custom({
    Expression<String>? artistId,
    Expression<String>? albumId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (artistId != null) 'artist_id': artistId,
      if (albumId != null) 'album_id': albumId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtistAlbumRelationshipsCompanion copyWith({
    Value<String>? artistId,
    Value<String>? albumId,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return ArtistAlbumRelationshipsCompanion(
      artistId: artistId ?? this.artistId,
      albumId: albumId ?? this.albumId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistAlbumRelationshipsCompanion(')
          ..write('artistId: $artistId, ')
          ..write('albumId: $albumId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLabelSearchesTable extends CachedLabelSearches
    with TableInfo<$CachedLabelSearchesTable, CachedLabelSearche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLabelSearchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _labelNameMeta = const VerificationMeta(
    'labelName',
  );
  @override
  late final GeneratedColumn<String> labelName = GeneratedColumn<String>(
    'label_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [labelName, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_label_searches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLabelSearche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('label_name')) {
      context.handle(
        _labelNameMeta,
        labelName.isAcceptableOrUnknown(data['label_name']!, _labelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_labelNameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {labelName};
  @override
  CachedLabelSearche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLabelSearche(
      labelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedLabelSearchesTable createAlias(String alias) {
    return $CachedLabelSearchesTable(attachedDatabase, alias);
  }
}

class CachedLabelSearche extends DataClass
    implements Insertable<CachedLabelSearche> {
  /// Label name (primary key).
  final String labelName;

  /// When this search was cached.
  final DateTime cachedAt;
  const CachedLabelSearche({required this.labelName, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['label_name'] = Variable<String>(labelName);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedLabelSearchesCompanion toCompanion(bool nullToAbsent) {
    return CachedLabelSearchesCompanion(
      labelName: Value(labelName),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedLabelSearche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLabelSearche(
      labelName: serializer.fromJson<String>(json['labelName']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'labelName': serializer.toJson<String>(labelName),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedLabelSearche copyWith({String? labelName, DateTime? cachedAt}) =>
      CachedLabelSearche(
        labelName: labelName ?? this.labelName,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedLabelSearche copyWithCompanion(CachedLabelSearchesCompanion data) {
    return CachedLabelSearche(
      labelName: data.labelName.present ? data.labelName.value : this.labelName,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLabelSearche(')
          ..write('labelName: $labelName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(labelName, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLabelSearche &&
          other.labelName == this.labelName &&
          other.cachedAt == this.cachedAt);
}

class CachedLabelSearchesCompanion extends UpdateCompanion<CachedLabelSearche> {
  final Value<String> labelName;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedLabelSearchesCompanion({
    this.labelName = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLabelSearchesCompanion.insert({
    required String labelName,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : labelName = Value(labelName),
       cachedAt = Value(cachedAt);
  static Insertable<CachedLabelSearche> custom({
    Expression<String>? labelName,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (labelName != null) 'label_name': labelName,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLabelSearchesCompanion copyWith({
    Value<String>? labelName,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedLabelSearchesCompanion(
      labelName: labelName ?? this.labelName,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (labelName.present) {
      map['label_name'] = Variable<String>(labelName.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLabelSearchesCompanion(')
          ..write('labelName: $labelName, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLabelTracksTable extends CachedLabelTracks
    with TableInfo<$CachedLabelTracksTable, CachedLabelTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLabelTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelNameMeta = const VerificationMeta(
    'labelName',
  );
  @override
  late final GeneratedColumn<String> labelName = GeneratedColumn<String>(
    'label_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_label_searches (label_name)',
    ),
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNamesMeta = const VerificationMeta(
    'artistNames',
  );
  @override
  late final GeneratedColumn<String> artistNames = GeneratedColumn<String>(
    'artist_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumNameMeta = const VerificationMeta(
    'albumName',
  );
  @override
  late final GeneratedColumn<String> albumName = GeneratedColumn<String>(
    'album_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    labelName,
    uri,
    name,
    artistNames,
    albumId,
    albumName,
    releaseDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_label_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLabelTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('label_name')) {
      context.handle(
        _labelNameMeta,
        labelName.isAcceptableOrUnknown(data['label_name']!, _labelNameMeta),
      );
    } else if (isInserting) {
      context.missing(_labelNameMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist_names')) {
      context.handle(
        _artistNamesMeta,
        artistNames.isAcceptableOrUnknown(
          data['artist_names']!,
          _artistNamesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistNamesMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('album_name')) {
      context.handle(
        _albumNameMeta,
        albumName.isAcceptableOrUnknown(data['album_name']!, _albumNameMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId, labelName};
  @override
  CachedLabelTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLabelTrack(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      labelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_name'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artistNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_names'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      albumName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_name'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
    );
  }

  @override
  $CachedLabelTracksTable createAlias(String alias) {
    return $CachedLabelTracksTable(attachedDatabase, alias);
  }
}

class CachedLabelTrack extends DataClass
    implements Insertable<CachedLabelTrack> {
  /// Spotify track ID.
  final String trackId;

  /// Label name (foreign key).
  final String labelName;

  /// Track URI.
  final String uri;

  /// Track name.
  final String name;

  /// Artist names (JSON array).
  final String artistNames;

  /// Album ID (optional).
  final String? albumId;

  /// Album name (optional).
  final String? albumName;

  /// Release date (optional).
  final String? releaseDate;
  const CachedLabelTrack({
    required this.trackId,
    required this.labelName,
    required this.uri,
    required this.name,
    required this.artistNames,
    this.albumId,
    this.albumName,
    this.releaseDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['label_name'] = Variable<String>(labelName);
    map['uri'] = Variable<String>(uri);
    map['name'] = Variable<String>(name);
    map['artist_names'] = Variable<String>(artistNames);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || albumName != null) {
      map['album_name'] = Variable<String>(albumName);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    return map;
  }

  CachedLabelTracksCompanion toCompanion(bool nullToAbsent) {
    return CachedLabelTracksCompanion(
      trackId: Value(trackId),
      labelName: Value(labelName),
      uri: Value(uri),
      name: Value(name),
      artistNames: Value(artistNames),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      albumName: albumName == null && nullToAbsent
          ? const Value.absent()
          : Value(albumName),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
    );
  }

  factory CachedLabelTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLabelTrack(
      trackId: serializer.fromJson<String>(json['trackId']),
      labelName: serializer.fromJson<String>(json['labelName']),
      uri: serializer.fromJson<String>(json['uri']),
      name: serializer.fromJson<String>(json['name']),
      artistNames: serializer.fromJson<String>(json['artistNames']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      albumName: serializer.fromJson<String?>(json['albumName']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'labelName': serializer.toJson<String>(labelName),
      'uri': serializer.toJson<String>(uri),
      'name': serializer.toJson<String>(name),
      'artistNames': serializer.toJson<String>(artistNames),
      'albumId': serializer.toJson<String?>(albumId),
      'albumName': serializer.toJson<String?>(albumName),
      'releaseDate': serializer.toJson<String?>(releaseDate),
    };
  }

  CachedLabelTrack copyWith({
    String? trackId,
    String? labelName,
    String? uri,
    String? name,
    String? artistNames,
    Value<String?> albumId = const Value.absent(),
    Value<String?> albumName = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
  }) => CachedLabelTrack(
    trackId: trackId ?? this.trackId,
    labelName: labelName ?? this.labelName,
    uri: uri ?? this.uri,
    name: name ?? this.name,
    artistNames: artistNames ?? this.artistNames,
    albumId: albumId.present ? albumId.value : this.albumId,
    albumName: albumName.present ? albumName.value : this.albumName,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
  );
  CachedLabelTrack copyWithCompanion(CachedLabelTracksCompanion data) {
    return CachedLabelTrack(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      labelName: data.labelName.present ? data.labelName.value : this.labelName,
      uri: data.uri.present ? data.uri.value : this.uri,
      name: data.name.present ? data.name.value : this.name,
      artistNames: data.artistNames.present
          ? data.artistNames.value
          : this.artistNames,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      albumName: data.albumName.present ? data.albumName.value : this.albumName,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLabelTrack(')
          ..write('trackId: $trackId, ')
          ..write('labelName: $labelName, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('albumId: $albumId, ')
          ..write('albumName: $albumName, ')
          ..write('releaseDate: $releaseDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    labelName,
    uri,
    name,
    artistNames,
    albumId,
    albumName,
    releaseDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLabelTrack &&
          other.trackId == this.trackId &&
          other.labelName == this.labelName &&
          other.uri == this.uri &&
          other.name == this.name &&
          other.artistNames == this.artistNames &&
          other.albumId == this.albumId &&
          other.albumName == this.albumName &&
          other.releaseDate == this.releaseDate);
}

class CachedLabelTracksCompanion extends UpdateCompanion<CachedLabelTrack> {
  final Value<String> trackId;
  final Value<String> labelName;
  final Value<String> uri;
  final Value<String> name;
  final Value<String> artistNames;
  final Value<String?> albumId;
  final Value<String?> albumName;
  final Value<String?> releaseDate;
  final Value<int> rowid;
  const CachedLabelTracksCompanion({
    this.trackId = const Value.absent(),
    this.labelName = const Value.absent(),
    this.uri = const Value.absent(),
    this.name = const Value.absent(),
    this.artistNames = const Value.absent(),
    this.albumId = const Value.absent(),
    this.albumName = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLabelTracksCompanion.insert({
    required String trackId,
    required String labelName,
    required String uri,
    required String name,
    required String artistNames,
    this.albumId = const Value.absent(),
    this.albumName = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       labelName = Value(labelName),
       uri = Value(uri),
       name = Value(name),
       artistNames = Value(artistNames);
  static Insertable<CachedLabelTrack> custom({
    Expression<String>? trackId,
    Expression<String>? labelName,
    Expression<String>? uri,
    Expression<String>? name,
    Expression<String>? artistNames,
    Expression<String>? albumId,
    Expression<String>? albumName,
    Expression<String>? releaseDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (labelName != null) 'label_name': labelName,
      if (uri != null) 'uri': uri,
      if (name != null) 'name': name,
      if (artistNames != null) 'artist_names': artistNames,
      if (albumId != null) 'album_id': albumId,
      if (albumName != null) 'album_name': albumName,
      if (releaseDate != null) 'release_date': releaseDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLabelTracksCompanion copyWith({
    Value<String>? trackId,
    Value<String>? labelName,
    Value<String>? uri,
    Value<String>? name,
    Value<String>? artistNames,
    Value<String?>? albumId,
    Value<String?>? albumName,
    Value<String?>? releaseDate,
    Value<int>? rowid,
  }) {
    return CachedLabelTracksCompanion(
      trackId: trackId ?? this.trackId,
      labelName: labelName ?? this.labelName,
      uri: uri ?? this.uri,
      name: name ?? this.name,
      artistNames: artistNames ?? this.artistNames,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      releaseDate: releaseDate ?? this.releaseDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (labelName.present) {
      map['label_name'] = Variable<String>(labelName.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artistNames.present) {
      map['artist_names'] = Variable<String>(artistNames.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (albumName.present) {
      map['album_name'] = Variable<String>(albumName.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLabelTracksCompanion(')
          ..write('trackId: $trackId, ')
          ..write('labelName: $labelName, ')
          ..write('uri: $uri, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('albumId: $albumId, ')
          ..write('albumName: $albumName, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheMetadataTable extends CacheMetadata
    with TableInfo<$CacheMetadataTable, CacheMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, created, lastUpdated];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetadataData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      ),
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      ),
    );
  }

  @override
  $CacheMetadataTable createAlias(String alias) {
    return $CacheMetadataTable(attachedDatabase, alias);
  }
}

class CacheMetadataData extends DataClass
    implements Insertable<CacheMetadataData> {
  /// Single row ID.
  final int id;

  /// When cache was created.
  final DateTime? created;

  /// When cache was last updated.
  final DateTime? lastUpdated;
  const CacheMetadataData({required this.id, this.created, this.lastUpdated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || created != null) {
      map['created'] = Variable<DateTime>(created);
    }
    if (!nullToAbsent || lastUpdated != null) {
      map['last_updated'] = Variable<DateTime>(lastUpdated);
    }
    return map;
  }

  CacheMetadataCompanion toCompanion(bool nullToAbsent) {
    return CacheMetadataCompanion(
      id: Value(id),
      created: created == null && nullToAbsent
          ? const Value.absent()
          : Value(created),
      lastUpdated: lastUpdated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdated),
    );
  }

  factory CacheMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetadataData(
      id: serializer.fromJson<int>(json['id']),
      created: serializer.fromJson<DateTime?>(json['created']),
      lastUpdated: serializer.fromJson<DateTime?>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'created': serializer.toJson<DateTime?>(created),
      'lastUpdated': serializer.toJson<DateTime?>(lastUpdated),
    };
  }

  CacheMetadataData copyWith({
    int? id,
    Value<DateTime?> created = const Value.absent(),
    Value<DateTime?> lastUpdated = const Value.absent(),
  }) => CacheMetadataData(
    id: id ?? this.id,
    created: created.present ? created.value : this.created,
    lastUpdated: lastUpdated.present ? lastUpdated.value : this.lastUpdated,
  );
  CacheMetadataData copyWithCompanion(CacheMetadataCompanion data) {
    return CacheMetadataData(
      id: data.id.present ? data.id.value : this.id,
      created: data.created.present ? data.created.value : this.created,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataData(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, created, lastUpdated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetadataData &&
          other.id == this.id &&
          other.created == this.created &&
          other.lastUpdated == this.lastUpdated);
}

class CacheMetadataCompanion extends UpdateCompanion<CacheMetadataData> {
  final Value<int> id;
  final Value<DateTime?> created;
  final Value<DateTime?> lastUpdated;
  const CacheMetadataCompanion({
    this.id = const Value.absent(),
    this.created = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  });
  CacheMetadataCompanion.insert({
    this.id = const Value.absent(),
    this.created = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  });
  static Insertable<CacheMetadataData> custom({
    Expression<int>? id,
    Expression<DateTime>? created,
    Expression<DateTime>? lastUpdated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (created != null) 'created': created,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    });
  }

  CacheMetadataCompanion copyWith({
    Value<int>? id,
    Value<DateTime?>? created,
    Value<DateTime?>? lastUpdated,
  }) {
    return CacheMetadataCompanion(
      id: id ?? this.id,
      created: created ?? this.created,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataCompanion(')
          ..write('id: $id, ')
          ..write('created: $created, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }
}

class $SyncTrackMappingsTable extends SyncTrackMappings
    with TableInfo<$SyncTrackMappingsTable, SyncTrackMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTrackMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _spotifyTrackIdMeta = const VerificationMeta(
    'spotifyTrackId',
  );
  @override
  late final GeneratedColumn<String> spotifyTrackId = GeneratedColumn<String>(
    'spotify_track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rekordboxSongIdMeta = const VerificationMeta(
    'rekordboxSongId',
  );
  @override
  late final GeneratedColumn<String> rekordboxSongId = GeneratedColumn<String>(
    'rekordbox_song_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    spotifyTrackId,
    rekordboxSongId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_track_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncTrackMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('spotify_track_id')) {
      context.handle(
        _spotifyTrackIdMeta,
        spotifyTrackId.isAcceptableOrUnknown(
          data['spotify_track_id']!,
          _spotifyTrackIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_spotifyTrackIdMeta);
    }
    if (data.containsKey('rekordbox_song_id')) {
      context.handle(
        _rekordboxSongIdMeta,
        rekordboxSongId.isAcceptableOrUnknown(
          data['rekordbox_song_id']!,
          _rekordboxSongIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rekordboxSongIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {spotifyTrackId};
  @override
  SyncTrackMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTrackMapping(
      spotifyTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spotify_track_id'],
      )!,
      rekordboxSongId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rekordbox_song_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncTrackMappingsTable createAlias(String alias) {
    return $SyncTrackMappingsTable(attachedDatabase, alias);
  }
}

class SyncTrackMapping extends DataClass
    implements Insertable<SyncTrackMapping> {
  /// Spotify track ID.
  final String spotifyTrackId;

  /// Rekordbox song ID.
  final String rekordboxSongId;

  /// When this mapping was created.
  final DateTime createdAt;
  const SyncTrackMapping({
    required this.spotifyTrackId,
    required this.rekordboxSongId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['spotify_track_id'] = Variable<String>(spotifyTrackId);
    map['rekordbox_song_id'] = Variable<String>(rekordboxSongId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncTrackMappingsCompanion toCompanion(bool nullToAbsent) {
    return SyncTrackMappingsCompanion(
      spotifyTrackId: Value(spotifyTrackId),
      rekordboxSongId: Value(rekordboxSongId),
      createdAt: Value(createdAt),
    );
  }

  factory SyncTrackMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTrackMapping(
      spotifyTrackId: serializer.fromJson<String>(json['spotifyTrackId']),
      rekordboxSongId: serializer.fromJson<String>(json['rekordboxSongId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'spotifyTrackId': serializer.toJson<String>(spotifyTrackId),
      'rekordboxSongId': serializer.toJson<String>(rekordboxSongId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncTrackMapping copyWith({
    String? spotifyTrackId,
    String? rekordboxSongId,
    DateTime? createdAt,
  }) => SyncTrackMapping(
    spotifyTrackId: spotifyTrackId ?? this.spotifyTrackId,
    rekordboxSongId: rekordboxSongId ?? this.rekordboxSongId,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncTrackMapping copyWithCompanion(SyncTrackMappingsCompanion data) {
    return SyncTrackMapping(
      spotifyTrackId: data.spotifyTrackId.present
          ? data.spotifyTrackId.value
          : this.spotifyTrackId,
      rekordboxSongId: data.rekordboxSongId.present
          ? data.rekordboxSongId.value
          : this.rekordboxSongId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTrackMapping(')
          ..write('spotifyTrackId: $spotifyTrackId, ')
          ..write('rekordboxSongId: $rekordboxSongId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(spotifyTrackId, rekordboxSongId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTrackMapping &&
          other.spotifyTrackId == this.spotifyTrackId &&
          other.rekordboxSongId == this.rekordboxSongId &&
          other.createdAt == this.createdAt);
}

class SyncTrackMappingsCompanion extends UpdateCompanion<SyncTrackMapping> {
  final Value<String> spotifyTrackId;
  final Value<String> rekordboxSongId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncTrackMappingsCompanion({
    this.spotifyTrackId = const Value.absent(),
    this.rekordboxSongId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTrackMappingsCompanion.insert({
    required String spotifyTrackId,
    required String rekordboxSongId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : spotifyTrackId = Value(spotifyTrackId),
       rekordboxSongId = Value(rekordboxSongId),
       createdAt = Value(createdAt);
  static Insertable<SyncTrackMapping> custom({
    Expression<String>? spotifyTrackId,
    Expression<String>? rekordboxSongId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (spotifyTrackId != null) 'spotify_track_id': spotifyTrackId,
      if (rekordboxSongId != null) 'rekordbox_song_id': rekordboxSongId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTrackMappingsCompanion copyWith({
    Value<String>? spotifyTrackId,
    Value<String>? rekordboxSongId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncTrackMappingsCompanion(
      spotifyTrackId: spotifyTrackId ?? this.spotifyTrackId,
      rekordboxSongId: rekordboxSongId ?? this.rekordboxSongId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (spotifyTrackId.present) {
      map['spotify_track_id'] = Variable<String>(spotifyTrackId.value);
    }
    if (rekordboxSongId.present) {
      map['rekordbox_song_id'] = Variable<String>(rekordboxSongId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTrackMappingsCompanion(')
          ..write('spotifyTrackId: $spotifyTrackId, ')
          ..write('rekordboxSongId: $rekordboxSongId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMissingTracksTable extends SyncMissingTracks
    with TableInfo<$SyncMissingTracksTable, SyncMissingTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMissingTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _spotifyTrackIdMeta = const VerificationMeta(
    'spotifyTrackId',
  );
  @override
  late final GeneratedColumn<String> spotifyTrackId = GeneratedColumn<String>(
    'spotify_track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itunesUrlMeta = const VerificationMeta(
    'itunesUrl',
  );
  @override
  late final GeneratedColumn<String> itunesUrl = GeneratedColumn<String>(
    'itunes_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastInsertedAtMeta = const VerificationMeta(
    'lastInsertedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInsertedAt =
      GeneratedColumn<DateTime>(
        'last_inserted_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    spotifyTrackId,
    artist,
    title,
    itunesUrl,
    lastInsertedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_missing_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMissingTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('spotify_track_id')) {
      context.handle(
        _spotifyTrackIdMeta,
        spotifyTrackId.isAcceptableOrUnknown(
          data['spotify_track_id']!,
          _spotifyTrackIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_spotifyTrackIdMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('itunes_url')) {
      context.handle(
        _itunesUrlMeta,
        itunesUrl.isAcceptableOrUnknown(data['itunes_url']!, _itunesUrlMeta),
      );
    }
    if (data.containsKey('last_inserted_at')) {
      context.handle(
        _lastInsertedAtMeta,
        lastInsertedAt.isAcceptableOrUnknown(
          data['last_inserted_at']!,
          _lastInsertedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastInsertedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {spotifyTrackId};
  @override
  SyncMissingTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMissingTrack(
      spotifyTrackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spotify_track_id'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      itunesUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}itunes_url'],
      ),
      lastInsertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_inserted_at'],
      )!,
    );
  }

  @override
  $SyncMissingTracksTable createAlias(String alias) {
    return $SyncMissingTracksTable(attachedDatabase, alias);
  }
}

class SyncMissingTrack extends DataClass
    implements Insertable<SyncMissingTrack> {
  /// Spotify track ID.
  final String spotifyTrackId;

  /// Artist names.
  final String artist;

  /// Track title.
  final String title;

  /// iTunes URL (nullable).
  final String? itunesUrl;

  /// When this track was last inserted.
  final DateTime lastInsertedAt;
  const SyncMissingTrack({
    required this.spotifyTrackId,
    required this.artist,
    required this.title,
    this.itunesUrl,
    required this.lastInsertedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['spotify_track_id'] = Variable<String>(spotifyTrackId);
    map['artist'] = Variable<String>(artist);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || itunesUrl != null) {
      map['itunes_url'] = Variable<String>(itunesUrl);
    }
    map['last_inserted_at'] = Variable<DateTime>(lastInsertedAt);
    return map;
  }

  SyncMissingTracksCompanion toCompanion(bool nullToAbsent) {
    return SyncMissingTracksCompanion(
      spotifyTrackId: Value(spotifyTrackId),
      artist: Value(artist),
      title: Value(title),
      itunesUrl: itunesUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(itunesUrl),
      lastInsertedAt: Value(lastInsertedAt),
    );
  }

  factory SyncMissingTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMissingTrack(
      spotifyTrackId: serializer.fromJson<String>(json['spotifyTrackId']),
      artist: serializer.fromJson<String>(json['artist']),
      title: serializer.fromJson<String>(json['title']),
      itunesUrl: serializer.fromJson<String?>(json['itunesUrl']),
      lastInsertedAt: serializer.fromJson<DateTime>(json['lastInsertedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'spotifyTrackId': serializer.toJson<String>(spotifyTrackId),
      'artist': serializer.toJson<String>(artist),
      'title': serializer.toJson<String>(title),
      'itunesUrl': serializer.toJson<String?>(itunesUrl),
      'lastInsertedAt': serializer.toJson<DateTime>(lastInsertedAt),
    };
  }

  SyncMissingTrack copyWith({
    String? spotifyTrackId,
    String? artist,
    String? title,
    Value<String?> itunesUrl = const Value.absent(),
    DateTime? lastInsertedAt,
  }) => SyncMissingTrack(
    spotifyTrackId: spotifyTrackId ?? this.spotifyTrackId,
    artist: artist ?? this.artist,
    title: title ?? this.title,
    itunesUrl: itunesUrl.present ? itunesUrl.value : this.itunesUrl,
    lastInsertedAt: lastInsertedAt ?? this.lastInsertedAt,
  );
  SyncMissingTrack copyWithCompanion(SyncMissingTracksCompanion data) {
    return SyncMissingTrack(
      spotifyTrackId: data.spotifyTrackId.present
          ? data.spotifyTrackId.value
          : this.spotifyTrackId,
      artist: data.artist.present ? data.artist.value : this.artist,
      title: data.title.present ? data.title.value : this.title,
      itunesUrl: data.itunesUrl.present ? data.itunesUrl.value : this.itunesUrl,
      lastInsertedAt: data.lastInsertedAt.present
          ? data.lastInsertedAt.value
          : this.lastInsertedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMissingTrack(')
          ..write('spotifyTrackId: $spotifyTrackId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('itunesUrl: $itunesUrl, ')
          ..write('lastInsertedAt: $lastInsertedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(spotifyTrackId, artist, title, itunesUrl, lastInsertedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMissingTrack &&
          other.spotifyTrackId == this.spotifyTrackId &&
          other.artist == this.artist &&
          other.title == this.title &&
          other.itunesUrl == this.itunesUrl &&
          other.lastInsertedAt == this.lastInsertedAt);
}

class SyncMissingTracksCompanion extends UpdateCompanion<SyncMissingTrack> {
  final Value<String> spotifyTrackId;
  final Value<String> artist;
  final Value<String> title;
  final Value<String?> itunesUrl;
  final Value<DateTime> lastInsertedAt;
  final Value<int> rowid;
  const SyncMissingTracksCompanion({
    this.spotifyTrackId = const Value.absent(),
    this.artist = const Value.absent(),
    this.title = const Value.absent(),
    this.itunesUrl = const Value.absent(),
    this.lastInsertedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMissingTracksCompanion.insert({
    required String spotifyTrackId,
    required String artist,
    required String title,
    this.itunesUrl = const Value.absent(),
    required DateTime lastInsertedAt,
    this.rowid = const Value.absent(),
  }) : spotifyTrackId = Value(spotifyTrackId),
       artist = Value(artist),
       title = Value(title),
       lastInsertedAt = Value(lastInsertedAt);
  static Insertable<SyncMissingTrack> custom({
    Expression<String>? spotifyTrackId,
    Expression<String>? artist,
    Expression<String>? title,
    Expression<String>? itunesUrl,
    Expression<DateTime>? lastInsertedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (spotifyTrackId != null) 'spotify_track_id': spotifyTrackId,
      if (artist != null) 'artist': artist,
      if (title != null) 'title': title,
      if (itunesUrl != null) 'itunes_url': itunesUrl,
      if (lastInsertedAt != null) 'last_inserted_at': lastInsertedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMissingTracksCompanion copyWith({
    Value<String>? spotifyTrackId,
    Value<String>? artist,
    Value<String>? title,
    Value<String?>? itunesUrl,
    Value<DateTime>? lastInsertedAt,
    Value<int>? rowid,
  }) {
    return SyncMissingTracksCompanion(
      spotifyTrackId: spotifyTrackId ?? this.spotifyTrackId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      itunesUrl: itunesUrl ?? this.itunesUrl,
      lastInsertedAt: lastInsertedAt ?? this.lastInsertedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (spotifyTrackId.present) {
      map['spotify_track_id'] = Variable<String>(spotifyTrackId.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (itunesUrl.present) {
      map['itunes_url'] = Variable<String>(itunesUrl.value);
    }
    if (lastInsertedAt.present) {
      map['last_inserted_at'] = Variable<DateTime>(lastInsertedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMissingTracksCompanion(')
          ..write('spotifyTrackId: $spotifyTrackId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('itunesUrl: $itunesUrl, ')
          ..write('lastInsertedAt: $lastInsertedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPlaylistsTable extends SyncPlaylists
    with TableInfo<$SyncPlaylistsTable, SyncPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<String> snapshotId = GeneratedColumn<String>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    snapshotId,
    name,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId};
  @override
  SyncPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPlaylist(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $SyncPlaylistsTable createAlias(String alias) {
    return $SyncPlaylistsTable(attachedDatabase, alias);
  }
}

class SyncPlaylist extends DataClass implements Insertable<SyncPlaylist> {
  /// Playlist ID.
  final String playlistId;

  /// Snapshot ID.
  final String snapshotId;

  /// Playlist name.
  final String name;

  /// When this playlist was cached.
  final DateTime cachedAt;
  const SyncPlaylist({
    required this.playlistId,
    required this.snapshotId,
    required this.name,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['snapshot_id'] = Variable<String>(snapshotId);
    map['name'] = Variable<String>(name);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  SyncPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return SyncPlaylistsCompanion(
      playlistId: Value(playlistId),
      snapshotId: Value(snapshotId),
      name: Value(name),
      cachedAt: Value(cachedAt),
    );
  }

  factory SyncPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPlaylist(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      snapshotId: serializer.fromJson<String>(json['snapshotId']),
      name: serializer.fromJson<String>(json['name']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'snapshotId': serializer.toJson<String>(snapshotId),
      'name': serializer.toJson<String>(name),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  SyncPlaylist copyWith({
    String? playlistId,
    String? snapshotId,
    String? name,
    DateTime? cachedAt,
  }) => SyncPlaylist(
    playlistId: playlistId ?? this.playlistId,
    snapshotId: snapshotId ?? this.snapshotId,
    name: name ?? this.name,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  SyncPlaylist copyWithCompanion(SyncPlaylistsCompanion data) {
    return SyncPlaylist(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      name: data.name.present ? data.name.value : this.name,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPlaylist(')
          ..write('playlistId: $playlistId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, snapshotId, name, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPlaylist &&
          other.playlistId == this.playlistId &&
          other.snapshotId == this.snapshotId &&
          other.name == this.name &&
          other.cachedAt == this.cachedAt);
}

class SyncPlaylistsCompanion extends UpdateCompanion<SyncPlaylist> {
  final Value<String> playlistId;
  final Value<String> snapshotId;
  final Value<String> name;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const SyncPlaylistsCompanion({
    this.playlistId = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.name = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPlaylistsCompanion.insert({
    required String playlistId,
    required String snapshotId,
    required String name,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       snapshotId = Value(snapshotId),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<SyncPlaylist> custom({
    Expression<String>? playlistId,
    Expression<String>? snapshotId,
    Expression<String>? name,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (name != null) 'name': name,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPlaylistsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? snapshotId,
    Value<String>? name,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return SyncPlaylistsCompanion(
      playlistId: playlistId ?? this.playlistId,
      snapshotId: snapshotId ?? this.snapshotId,
      name: name ?? this.name,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<String>(snapshotId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPlaylistsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('name: $name, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPlaylistTracksTable extends SyncPlaylistTracks
    with TableInfo<$SyncPlaylistTracksTable, SyncPlaylistTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNamesMeta = const VerificationMeta(
    'artistNames',
  );
  @override
  late final GeneratedColumn<String> artistNames = GeneratedColumn<String>(
    'artist_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    playlistId,
    trackId,
    name,
    artistNames,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPlaylistTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('artist_names')) {
      context.handle(
        _artistNamesMeta,
        artistNames.isAcceptableOrUnknown(
          data['artist_names']!,
          _artistNamesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistNamesMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, trackId, orderIndex};
  @override
  SyncPlaylistTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPlaylistTrack(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      artistNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_names'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $SyncPlaylistTracksTable createAlias(String alias) {
    return $SyncPlaylistTracksTable(attachedDatabase, alias);
  }
}

class SyncPlaylistTrack extends DataClass
    implements Insertable<SyncPlaylistTrack> {
  /// Playlist ID.
  final String playlistId;

  /// Spotify track ID.
  final String trackId;

  /// Track name.
  final String name;

  /// Artist names (JSON array).
  final String artistNames;

  /// Position in the playlist.
  final int orderIndex;
  const SyncPlaylistTrack({
    required this.playlistId,
    required this.trackId,
    required this.name,
    required this.artistNames,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['track_id'] = Variable<String>(trackId);
    map['name'] = Variable<String>(name);
    map['artist_names'] = Variable<String>(artistNames);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  SyncPlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return SyncPlaylistTracksCompanion(
      playlistId: Value(playlistId),
      trackId: Value(trackId),
      name: Value(name),
      artistNames: Value(artistNames),
      orderIndex: Value(orderIndex),
    );
  }

  factory SyncPlaylistTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPlaylistTrack(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      trackId: serializer.fromJson<String>(json['trackId']),
      name: serializer.fromJson<String>(json['name']),
      artistNames: serializer.fromJson<String>(json['artistNames']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'trackId': serializer.toJson<String>(trackId),
      'name': serializer.toJson<String>(name),
      'artistNames': serializer.toJson<String>(artistNames),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  SyncPlaylistTrack copyWith({
    String? playlistId,
    String? trackId,
    String? name,
    String? artistNames,
    int? orderIndex,
  }) => SyncPlaylistTrack(
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    name: name ?? this.name,
    artistNames: artistNames ?? this.artistNames,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  SyncPlaylistTrack copyWithCompanion(SyncPlaylistTracksCompanion data) {
    return SyncPlaylistTrack(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      name: data.name.present ? data.name.value : this.name,
      artistNames: data.artistNames.present
          ? data.artistNames.value
          : this.artistNames,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPlaylistTrack(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(playlistId, trackId, name, artistNames, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPlaylistTrack &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.name == this.name &&
          other.artistNames == this.artistNames &&
          other.orderIndex == this.orderIndex);
}

class SyncPlaylistTracksCompanion extends UpdateCompanion<SyncPlaylistTrack> {
  final Value<String> playlistId;
  final Value<String> trackId;
  final Value<String> name;
  final Value<String> artistNames;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const SyncPlaylistTracksCompanion({
    this.playlistId = const Value.absent(),
    this.trackId = const Value.absent(),
    this.name = const Value.absent(),
    this.artistNames = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPlaylistTracksCompanion.insert({
    required String playlistId,
    required String trackId,
    required String name,
    required String artistNames,
    required int orderIndex,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       trackId = Value(trackId),
       name = Value(name),
       artistNames = Value(artistNames),
       orderIndex = Value(orderIndex);
  static Insertable<SyncPlaylistTrack> custom({
    Expression<String>? playlistId,
    Expression<String>? trackId,
    Expression<String>? name,
    Expression<String>? artistNames,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (name != null) 'name': name,
      if (artistNames != null) 'artist_names': artistNames,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPlaylistTracksCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? trackId,
    Value<String>? name,
    Value<String>? artistNames,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return SyncPlaylistTracksCompanion(
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      name: name ?? this.name,
      artistNames: artistNames ?? this.artistNames,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (artistNames.present) {
      map['artist_names'] = Variable<String>(artistNames.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPlaylistTracksCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('name: $name, ')
          ..write('artistNames: $artistNames, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedPlaylistsTable cachedPlaylists = $CachedPlaylistsTable(
    this,
  );
  late final $CachedPlaylistTracksTable cachedPlaylistTracks =
      $CachedPlaylistTracksTable(this);
  late final $CachedAlbumsTable cachedAlbums = $CachedAlbumsTable(this);
  late final $TrackAlbumMappingsTable trackAlbumMappings =
      $TrackAlbumMappingsTable(this);
  late final $CachedArtistsTable cachedArtists = $CachedArtistsTable(this);
  late final $CachedArtistAlbumListsTable cachedArtistAlbumLists =
      $CachedArtistAlbumListsTable(this);
  late final $ArtistAlbumRelationshipsTable artistAlbumRelationships =
      $ArtistAlbumRelationshipsTable(this);
  late final $CachedLabelSearchesTable cachedLabelSearches =
      $CachedLabelSearchesTable(this);
  late final $CachedLabelTracksTable cachedLabelTracks =
      $CachedLabelTracksTable(this);
  late final $CacheMetadataTable cacheMetadata = $CacheMetadataTable(this);
  late final $SyncTrackMappingsTable syncTrackMappings =
      $SyncTrackMappingsTable(this);
  late final $SyncMissingTracksTable syncMissingTracks =
      $SyncMissingTracksTable(this);
  late final $SyncPlaylistsTable syncPlaylists = $SyncPlaylistsTable(this);
  late final $SyncPlaylistTracksTable syncPlaylistTracks =
      $SyncPlaylistTracksTable(this);
  late final PlaylistsDao playlistsDao = PlaylistsDao(this as AppDatabase);
  late final AlbumsDao albumsDao = AlbumsDao(this as AppDatabase);
  late final TrackAlbumMappingsDao trackAlbumMappingsDao =
      TrackAlbumMappingsDao(this as AppDatabase);
  late final ArtistsDao artistsDao = ArtistsDao(this as AppDatabase);
  late final ArtistAlbumsDao artistAlbumsDao = ArtistAlbumsDao(
    this as AppDatabase,
  );
  late final LabelSearchesDao labelSearchesDao = LabelSearchesDao(
    this as AppDatabase,
  );
  late final MetadataDao metadataDao = MetadataDao(this as AppDatabase);
  late final SyncMappingsDao syncMappingsDao = SyncMappingsDao(
    this as AppDatabase,
  );
  late final SyncMissingTracksDao syncMissingTracksDao = SyncMissingTracksDao(
    this as AppDatabase,
  );
  late final SyncPlaylistsDao syncPlaylistsDao = SyncPlaylistsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedPlaylists,
    cachedPlaylistTracks,
    cachedAlbums,
    trackAlbumMappings,
    cachedArtists,
    cachedArtistAlbumLists,
    artistAlbumRelationships,
    cachedLabelSearches,
    cachedLabelTracks,
    cacheMetadata,
    syncTrackMappings,
    syncMissingTracks,
    syncPlaylists,
    syncPlaylistTracks,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CachedPlaylistsTableCreateCompanionBuilder =
    CachedPlaylistsCompanion Function({
      required String id,
      required String snapshotId,
      required String name,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedPlaylistsTableUpdateCompanionBuilder =
    CachedPlaylistsCompanion Function({
      Value<String> id,
      Value<String> snapshotId,
      Value<String> name,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedPlaylistsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CachedPlaylistsTable, CachedPlaylist> {
  $$CachedPlaylistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedPlaylistTracksTable,
    List<CachedPlaylistTrack>
  >
  _cachedPlaylistTracksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedPlaylistTracks,
        aliasName: $_aliasNameGenerator(
          db.cachedPlaylists.id,
          db.cachedPlaylistTracks.playlistId,
        ),
      );

  $$CachedPlaylistTracksTableProcessedTableManager
  get cachedPlaylistTracksRefs {
    final manager = $$CachedPlaylistTracksTableTableManager(
      $_db,
      $_db.cachedPlaylistTracks,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedPlaylistTracksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPlaylistsTable> {
  $$CachedPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedPlaylistTracksRefs(
    Expression<bool> Function($$CachedPlaylistTracksTableFilterComposer f) f,
  ) {
    final $$CachedPlaylistTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedPlaylistTracks,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPlaylistTracksTableFilterComposer(
            $db: $db,
            $table: $db.cachedPlaylistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPlaylistsTable> {
  $$CachedPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPlaylistsTable> {
  $$CachedPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> cachedPlaylistTracksRefs<T extends Object>(
    Expression<T> Function($$CachedPlaylistTracksTableAnnotationComposer a) f,
  ) {
    final $$CachedPlaylistTracksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedPlaylistTracks,
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedPlaylistTracksTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedPlaylistTracks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPlaylistsTable,
          CachedPlaylist,
          $$CachedPlaylistsTableFilterComposer,
          $$CachedPlaylistsTableOrderingComposer,
          $$CachedPlaylistsTableAnnotationComposer,
          $$CachedPlaylistsTableCreateCompanionBuilder,
          $$CachedPlaylistsTableUpdateCompanionBuilder,
          (CachedPlaylist, $$CachedPlaylistsTableReferences),
          CachedPlaylist,
          PrefetchHooks Function({bool cachedPlaylistTracksRefs})
        > {
  $$CachedPlaylistsTableTableManager(
    _$AppDatabase db,
    $CachedPlaylistsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> snapshotId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPlaylistsCompanion(
                id: id,
                snapshotId: snapshotId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String snapshotId,
                required String name,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPlaylistsCompanion.insert(
                id: id,
                snapshotId: snapshotId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedPlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedPlaylistTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedPlaylistTracksRefs) db.cachedPlaylistTracks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedPlaylistTracksRefs)
                    await $_getPrefetchedData<
                      CachedPlaylist,
                      $CachedPlaylistsTable,
                      CachedPlaylistTrack
                    >(
                      currentTable: table,
                      referencedTable: $$CachedPlaylistsTableReferences
                          ._cachedPlaylistTracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedPlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedPlaylistTracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlistId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPlaylistsTable,
      CachedPlaylist,
      $$CachedPlaylistsTableFilterComposer,
      $$CachedPlaylistsTableOrderingComposer,
      $$CachedPlaylistsTableAnnotationComposer,
      $$CachedPlaylistsTableCreateCompanionBuilder,
      $$CachedPlaylistsTableUpdateCompanionBuilder,
      (CachedPlaylist, $$CachedPlaylistsTableReferences),
      CachedPlaylist,
      PrefetchHooks Function({bool cachedPlaylistTracksRefs})
    >;
typedef $$CachedPlaylistTracksTableCreateCompanionBuilder =
    CachedPlaylistTracksCompanion Function({
      required String trackId,
      required String playlistId,
      required String uri,
      required String name,
      required String artistNames,
      required DateTime addedAt,
      Value<String?> albumId,
      Value<int> rowid,
    });
typedef $$CachedPlaylistTracksTableUpdateCompanionBuilder =
    CachedPlaylistTracksCompanion Function({
      Value<String> trackId,
      Value<String> playlistId,
      Value<String> uri,
      Value<String> name,
      Value<String> artistNames,
      Value<DateTime> addedAt,
      Value<String?> albumId,
      Value<int> rowid,
    });

final class $$CachedPlaylistTracksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedPlaylistTracksTable,
          CachedPlaylistTrack
        > {
  $$CachedPlaylistTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedPlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.cachedPlaylists.createAlias(
        $_aliasNameGenerator(
          db.cachedPlaylistTracks.playlistId,
          db.cachedPlaylists.id,
        ),
      );

  $$CachedPlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$CachedPlaylistsTableTableManager(
      $_db,
      $_db.cachedPlaylists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedPlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPlaylistTracksTable> {
  $$CachedPlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedPlaylistsTableFilterComposer get playlistId {
    final $$CachedPlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.cachedPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.cachedPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPlaylistTracksTable> {
  $$CachedPlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedPlaylistsTableOrderingComposer get playlistId {
    final $$CachedPlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.cachedPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPlaylistTracksTable> {
  $$CachedPlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  $$CachedPlaylistsTableAnnotationComposer get playlistId {
    final $$CachedPlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.cachedPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedPlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedPlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPlaylistTracksTable,
          CachedPlaylistTrack,
          $$CachedPlaylistTracksTableFilterComposer,
          $$CachedPlaylistTracksTableOrderingComposer,
          $$CachedPlaylistTracksTableAnnotationComposer,
          $$CachedPlaylistTracksTableCreateCompanionBuilder,
          $$CachedPlaylistTracksTableUpdateCompanionBuilder,
          (CachedPlaylistTrack, $$CachedPlaylistTracksTableReferences),
          CachedPlaylistTrack,
          PrefetchHooks Function({bool playlistId})
        > {
  $$CachedPlaylistTracksTableTableManager(
    _$AppDatabase db,
    $CachedPlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPlaylistTracksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedPlaylistTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> artistNames = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPlaylistTracksCompanion(
                trackId: trackId,
                playlistId: playlistId,
                uri: uri,
                name: name,
                artistNames: artistNames,
                addedAt: addedAt,
                albumId: albumId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String playlistId,
                required String uri,
                required String name,
                required String artistNames,
                required DateTime addedAt,
                Value<String?> albumId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPlaylistTracksCompanion.insert(
                trackId: trackId,
                playlistId: playlistId,
                uri: uri,
                name: name,
                artistNames: artistNames,
                addedAt: addedAt,
                albumId: albumId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedPlaylistTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlistId,
                                referencedTable:
                                    $$CachedPlaylistTracksTableReferences
                                        ._playlistIdTable(db),
                                referencedColumn:
                                    $$CachedPlaylistTracksTableReferences
                                        ._playlistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedPlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPlaylistTracksTable,
      CachedPlaylistTrack,
      $$CachedPlaylistTracksTableFilterComposer,
      $$CachedPlaylistTracksTableOrderingComposer,
      $$CachedPlaylistTracksTableAnnotationComposer,
      $$CachedPlaylistTracksTableCreateCompanionBuilder,
      $$CachedPlaylistTracksTableUpdateCompanionBuilder,
      (CachedPlaylistTrack, $$CachedPlaylistTracksTableReferences),
      CachedPlaylistTrack,
      PrefetchHooks Function({bool playlistId})
    >;
typedef $$CachedAlbumsTableCreateCompanionBuilder =
    CachedAlbumsCompanion Function({
      required String id,
      required String name,
      Value<String?> releaseDate,
      Value<String?> label,
      Value<String?> artistNames,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedAlbumsTableUpdateCompanionBuilder =
    CachedAlbumsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> releaseDate,
      Value<String?> label,
      Value<String?> artistNames,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedAlbumsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedAlbumsTable, CachedAlbum> {
  $$CachedAlbumsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackAlbumMappingsTable, List<TrackAlbumMapping>>
  _trackAlbumMappingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.trackAlbumMappings,
        aliasName: $_aliasNameGenerator(
          db.cachedAlbums.id,
          db.trackAlbumMappings.albumId,
        ),
      );

  $$TrackAlbumMappingsTableProcessedTableManager get trackAlbumMappingsRefs {
    final manager = $$TrackAlbumMappingsTableTableManager(
      $_db,
      $_db.trackAlbumMappings,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _trackAlbumMappingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ArtistAlbumRelationshipsTable,
    List<ArtistAlbumRelationship>
  >
  _artistAlbumRelationshipsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.artistAlbumRelationships,
        aliasName: $_aliasNameGenerator(
          db.cachedAlbums.id,
          db.artistAlbumRelationships.albumId,
        ),
      );

  $$ArtistAlbumRelationshipsTableProcessedTableManager
  get artistAlbumRelationshipsRefs {
    final manager = $$ArtistAlbumRelationshipsTableTableManager(
      $_db,
      $_db.artistAlbumRelationships,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _artistAlbumRelationshipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedAlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAlbumsTable> {
  $$CachedAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> trackAlbumMappingsRefs(
    Expression<bool> Function($$TrackAlbumMappingsTableFilterComposer f) f,
  ) {
    final $$TrackAlbumMappingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackAlbumMappings,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackAlbumMappingsTableFilterComposer(
            $db: $db,
            $table: $db.trackAlbumMappings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> artistAlbumRelationshipsRefs(
    Expression<bool> Function($$ArtistAlbumRelationshipsTableFilterComposer f)
    f,
  ) {
    final $$ArtistAlbumRelationshipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.artistAlbumRelationships,
          getReferencedColumn: (t) => t.albumId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ArtistAlbumRelationshipsTableFilterComposer(
                $db: $db,
                $table: $db.artistAlbumRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedAlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAlbumsTable> {
  $$CachedAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAlbumsTable> {
  $$CachedAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> trackAlbumMappingsRefs<T extends Object>(
    Expression<T> Function($$TrackAlbumMappingsTableAnnotationComposer a) f,
  ) {
    final $$TrackAlbumMappingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.trackAlbumMappings,
          getReferencedColumn: (t) => t.albumId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TrackAlbumMappingsTableAnnotationComposer(
                $db: $db,
                $table: $db.trackAlbumMappings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> artistAlbumRelationshipsRefs<T extends Object>(
    Expression<T> Function($$ArtistAlbumRelationshipsTableAnnotationComposer a)
    f,
  ) {
    final $$ArtistAlbumRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.artistAlbumRelationships,
          getReferencedColumn: (t) => t.albumId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ArtistAlbumRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.artistAlbumRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedAlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAlbumsTable,
          CachedAlbum,
          $$CachedAlbumsTableFilterComposer,
          $$CachedAlbumsTableOrderingComposer,
          $$CachedAlbumsTableAnnotationComposer,
          $$CachedAlbumsTableCreateCompanionBuilder,
          $$CachedAlbumsTableUpdateCompanionBuilder,
          (CachedAlbum, $$CachedAlbumsTableReferences),
          CachedAlbum,
          PrefetchHooks Function({
            bool trackAlbumMappingsRefs,
            bool artistAlbumRelationshipsRefs,
          })
        > {
  $$CachedAlbumsTableTableManager(_$AppDatabase db, $CachedAlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> artistNames = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAlbumsCompanion(
                id: id,
                name: name,
                releaseDate: releaseDate,
                label: label,
                artistNames: artistNames,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> artistNames = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedAlbumsCompanion.insert(
                id: id,
                name: name,
                releaseDate: releaseDate,
                label: label,
                artistNames: artistNames,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedAlbumsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                trackAlbumMappingsRefs = false,
                artistAlbumRelationshipsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackAlbumMappingsRefs) db.trackAlbumMappings,
                    if (artistAlbumRelationshipsRefs)
                      db.artistAlbumRelationships,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackAlbumMappingsRefs)
                        await $_getPrefetchedData<
                          CachedAlbum,
                          $CachedAlbumsTable,
                          TrackAlbumMapping
                        >(
                          currentTable: table,
                          referencedTable: $$CachedAlbumsTableReferences
                              ._trackAlbumMappingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedAlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).trackAlbumMappingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (artistAlbumRelationshipsRefs)
                        await $_getPrefetchedData<
                          CachedAlbum,
                          $CachedAlbumsTable,
                          ArtistAlbumRelationship
                        >(
                          currentTable: table,
                          referencedTable: $$CachedAlbumsTableReferences
                              ._artistAlbumRelationshipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedAlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).artistAlbumRelationshipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAlbumsTable,
      CachedAlbum,
      $$CachedAlbumsTableFilterComposer,
      $$CachedAlbumsTableOrderingComposer,
      $$CachedAlbumsTableAnnotationComposer,
      $$CachedAlbumsTableCreateCompanionBuilder,
      $$CachedAlbumsTableUpdateCompanionBuilder,
      (CachedAlbum, $$CachedAlbumsTableReferences),
      CachedAlbum,
      PrefetchHooks Function({
        bool trackAlbumMappingsRefs,
        bool artistAlbumRelationshipsRefs,
      })
    >;
typedef $$TrackAlbumMappingsTableCreateCompanionBuilder =
    TrackAlbumMappingsCompanion Function({
      required String trackId,
      required String albumId,
      Value<int> rowid,
    });
typedef $$TrackAlbumMappingsTableUpdateCompanionBuilder =
    TrackAlbumMappingsCompanion Function({
      Value<String> trackId,
      Value<String> albumId,
      Value<int> rowid,
    });

final class $$TrackAlbumMappingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TrackAlbumMappingsTable,
          TrackAlbumMapping
        > {
  $$TrackAlbumMappingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedAlbumsTable _albumIdTable(_$AppDatabase db) =>
      db.cachedAlbums.createAlias(
        $_aliasNameGenerator(db.trackAlbumMappings.albumId, db.cachedAlbums.id),
      );

  $$CachedAlbumsTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<String>('album_id')!;

    final manager = $$CachedAlbumsTableTableManager(
      $_db,
      $_db.cachedAlbums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackAlbumMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackAlbumMappingsTable> {
  $$TrackAlbumMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedAlbumsTableFilterComposer get albumId {
    final $$CachedAlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableFilterComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackAlbumMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackAlbumMappingsTable> {
  $$TrackAlbumMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedAlbumsTableOrderingComposer get albumId {
    final $$CachedAlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackAlbumMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackAlbumMappingsTable> {
  $$TrackAlbumMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  $$CachedAlbumsTableAnnotationComposer get albumId {
    final $$CachedAlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackAlbumMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackAlbumMappingsTable,
          TrackAlbumMapping,
          $$TrackAlbumMappingsTableFilterComposer,
          $$TrackAlbumMappingsTableOrderingComposer,
          $$TrackAlbumMappingsTableAnnotationComposer,
          $$TrackAlbumMappingsTableCreateCompanionBuilder,
          $$TrackAlbumMappingsTableUpdateCompanionBuilder,
          (TrackAlbumMapping, $$TrackAlbumMappingsTableReferences),
          TrackAlbumMapping,
          PrefetchHooks Function({bool albumId})
        > {
  $$TrackAlbumMappingsTableTableManager(
    _$AppDatabase db,
    $TrackAlbumMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackAlbumMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackAlbumMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackAlbumMappingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> albumId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrackAlbumMappingsCompanion(
                trackId: trackId,
                albumId: albumId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String albumId,
                Value<int> rowid = const Value.absent(),
              }) => TrackAlbumMappingsCompanion.insert(
                trackId: trackId,
                albumId: albumId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackAlbumMappingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable:
                                    $$TrackAlbumMappingsTableReferences
                                        ._albumIdTable(db),
                                referencedColumn:
                                    $$TrackAlbumMappingsTableReferences
                                        ._albumIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackAlbumMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackAlbumMappingsTable,
      TrackAlbumMapping,
      $$TrackAlbumMappingsTableFilterComposer,
      $$TrackAlbumMappingsTableOrderingComposer,
      $$TrackAlbumMappingsTableAnnotationComposer,
      $$TrackAlbumMappingsTableCreateCompanionBuilder,
      $$TrackAlbumMappingsTableUpdateCompanionBuilder,
      (TrackAlbumMapping, $$TrackAlbumMappingsTableReferences),
      TrackAlbumMapping,
      PrefetchHooks Function({bool albumId})
    >;
typedef $$CachedArtistsTableCreateCompanionBuilder =
    CachedArtistsCompanion Function({
      required String id,
      required String name,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedArtistsTableUpdateCompanionBuilder =
    CachedArtistsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedArtistsTableReferences
    extends BaseReferences<_$AppDatabase, $CachedArtistsTable, CachedArtist> {
  $$CachedArtistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedArtistAlbumListsTable,
    List<CachedArtistAlbumList>
  >
  _cachedArtistAlbumListsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedArtistAlbumLists,
        aliasName: $_aliasNameGenerator(
          db.cachedArtists.id,
          db.cachedArtistAlbumLists.artistId,
        ),
      );

  $$CachedArtistAlbumListsTableProcessedTableManager
  get cachedArtistAlbumListsRefs {
    final manager = $$CachedArtistAlbumListsTableTableManager(
      $_db,
      $_db.cachedArtistAlbumLists,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedArtistAlbumListsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $ArtistAlbumRelationshipsTable,
    List<ArtistAlbumRelationship>
  >
  _artistAlbumRelationshipsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.artistAlbumRelationships,
        aliasName: $_aliasNameGenerator(
          db.cachedArtists.id,
          db.artistAlbumRelationships.artistId,
        ),
      );

  $$ArtistAlbumRelationshipsTableProcessedTableManager
  get artistAlbumRelationshipsRefs {
    final manager = $$ArtistAlbumRelationshipsTableTableManager(
      $_db,
      $_db.artistAlbumRelationships,
    ).filter((f) => f.artistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _artistAlbumRelationshipsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedArtistsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedArtistsTable> {
  $$CachedArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedArtistAlbumListsRefs(
    Expression<bool> Function($$CachedArtistAlbumListsTableFilterComposer f) f,
  ) {
    final $$CachedArtistAlbumListsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedArtistAlbumLists,
          getReferencedColumn: (t) => t.artistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedArtistAlbumListsTableFilterComposer(
                $db: $db,
                $table: $db.cachedArtistAlbumLists,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> artistAlbumRelationshipsRefs(
    Expression<bool> Function($$ArtistAlbumRelationshipsTableFilterComposer f)
    f,
  ) {
    final $$ArtistAlbumRelationshipsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.artistAlbumRelationships,
          getReferencedColumn: (t) => t.artistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ArtistAlbumRelationshipsTableFilterComposer(
                $db: $db,
                $table: $db.artistAlbumRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedArtistsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedArtistsTable> {
  $$CachedArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedArtistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedArtistsTable> {
  $$CachedArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> cachedArtistAlbumListsRefs<T extends Object>(
    Expression<T> Function($$CachedArtistAlbumListsTableAnnotationComposer a) f,
  ) {
    final $$CachedArtistAlbumListsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedArtistAlbumLists,
          getReferencedColumn: (t) => t.artistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedArtistAlbumListsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedArtistAlbumLists,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> artistAlbumRelationshipsRefs<T extends Object>(
    Expression<T> Function($$ArtistAlbumRelationshipsTableAnnotationComposer a)
    f,
  ) {
    final $$ArtistAlbumRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.artistAlbumRelationships,
          getReferencedColumn: (t) => t.artistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ArtistAlbumRelationshipsTableAnnotationComposer(
                $db: $db,
                $table: $db.artistAlbumRelationships,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedArtistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedArtistsTable,
          CachedArtist,
          $$CachedArtistsTableFilterComposer,
          $$CachedArtistsTableOrderingComposer,
          $$CachedArtistsTableAnnotationComposer,
          $$CachedArtistsTableCreateCompanionBuilder,
          $$CachedArtistsTableUpdateCompanionBuilder,
          (CachedArtist, $$CachedArtistsTableReferences),
          CachedArtist,
          PrefetchHooks Function({
            bool cachedArtistAlbumListsRefs,
            bool artistAlbumRelationshipsRefs,
          })
        > {
  $$CachedArtistsTableTableManager(_$AppDatabase db, $CachedArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedArtistsCompanion(
                id: id,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedArtistsCompanion.insert(
                id: id,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedArtistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cachedArtistAlbumListsRefs = false,
                artistAlbumRelationshipsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cachedArtistAlbumListsRefs) db.cachedArtistAlbumLists,
                    if (artistAlbumRelationshipsRefs)
                      db.artistAlbumRelationships,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cachedArtistAlbumListsRefs)
                        await $_getPrefetchedData<
                          CachedArtist,
                          $CachedArtistsTable,
                          CachedArtistAlbumList
                        >(
                          currentTable: table,
                          referencedTable: $$CachedArtistsTableReferences
                              ._cachedArtistAlbumListsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).cachedArtistAlbumListsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (artistAlbumRelationshipsRefs)
                        await $_getPrefetchedData<
                          CachedArtist,
                          $CachedArtistsTable,
                          ArtistAlbumRelationship
                        >(
                          currentTable: table,
                          referencedTable: $$CachedArtistsTableReferences
                              ._artistAlbumRelationshipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedArtistsTableReferences(
                                db,
                                table,
                                p0,
                              ).artistAlbumRelationshipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.artistId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedArtistsTable,
      CachedArtist,
      $$CachedArtistsTableFilterComposer,
      $$CachedArtistsTableOrderingComposer,
      $$CachedArtistsTableAnnotationComposer,
      $$CachedArtistsTableCreateCompanionBuilder,
      $$CachedArtistsTableUpdateCompanionBuilder,
      (CachedArtist, $$CachedArtistsTableReferences),
      CachedArtist,
      PrefetchHooks Function({
        bool cachedArtistAlbumListsRefs,
        bool artistAlbumRelationshipsRefs,
      })
    >;
typedef $$CachedArtistAlbumListsTableCreateCompanionBuilder =
    CachedArtistAlbumListsCompanion Function({
      required String artistId,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedArtistAlbumListsTableUpdateCompanionBuilder =
    CachedArtistAlbumListsCompanion Function({
      Value<String> artistId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedArtistAlbumListsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedArtistAlbumListsTable,
          CachedArtistAlbumList
        > {
  $$CachedArtistAlbumListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.cachedArtists.createAlias(
        $_aliasNameGenerator(
          db.cachedArtistAlbumLists.artistId,
          db.cachedArtists.id,
        ),
      );

  $$CachedArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<String>('artist_id')!;

    final manager = $$CachedArtistsTableTableManager(
      $_db,
      $_db.cachedArtists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedArtistAlbumListsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedArtistAlbumListsTable> {
  $$CachedArtistAlbumListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedArtistsTableFilterComposer get artistId {
    final $$CachedArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableFilterComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedArtistAlbumListsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedArtistAlbumListsTable> {
  $$CachedArtistAlbumListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedArtistsTableOrderingComposer get artistId {
    final $$CachedArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedArtistAlbumListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedArtistAlbumListsTable> {
  $$CachedArtistAlbumListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  $$CachedArtistsTableAnnotationComposer get artistId {
    final $$CachedArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedArtistAlbumListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedArtistAlbumListsTable,
          CachedArtistAlbumList,
          $$CachedArtistAlbumListsTableFilterComposer,
          $$CachedArtistAlbumListsTableOrderingComposer,
          $$CachedArtistAlbumListsTableAnnotationComposer,
          $$CachedArtistAlbumListsTableCreateCompanionBuilder,
          $$CachedArtistAlbumListsTableUpdateCompanionBuilder,
          (CachedArtistAlbumList, $$CachedArtistAlbumListsTableReferences),
          CachedArtistAlbumList,
          PrefetchHooks Function({bool artistId})
        > {
  $$CachedArtistAlbumListsTableTableManager(
    _$AppDatabase db,
    $CachedArtistAlbumListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedArtistAlbumListsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedArtistAlbumListsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedArtistAlbumListsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> artistId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedArtistAlbumListsCompanion(
                artistId: artistId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String artistId,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedArtistAlbumListsCompanion.insert(
                artistId: artistId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedArtistAlbumListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artistId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (artistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artistId,
                                referencedTable:
                                    $$CachedArtistAlbumListsTableReferences
                                        ._artistIdTable(db),
                                referencedColumn:
                                    $$CachedArtistAlbumListsTableReferences
                                        ._artistIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedArtistAlbumListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedArtistAlbumListsTable,
      CachedArtistAlbumList,
      $$CachedArtistAlbumListsTableFilterComposer,
      $$CachedArtistAlbumListsTableOrderingComposer,
      $$CachedArtistAlbumListsTableAnnotationComposer,
      $$CachedArtistAlbumListsTableCreateCompanionBuilder,
      $$CachedArtistAlbumListsTableUpdateCompanionBuilder,
      (CachedArtistAlbumList, $$CachedArtistAlbumListsTableReferences),
      CachedArtistAlbumList,
      PrefetchHooks Function({bool artistId})
    >;
typedef $$ArtistAlbumRelationshipsTableCreateCompanionBuilder =
    ArtistAlbumRelationshipsCompanion Function({
      required String artistId,
      required String albumId,
      required int orderIndex,
      Value<int> rowid,
    });
typedef $$ArtistAlbumRelationshipsTableUpdateCompanionBuilder =
    ArtistAlbumRelationshipsCompanion Function({
      Value<String> artistId,
      Value<String> albumId,
      Value<int> orderIndex,
      Value<int> rowid,
    });

final class $$ArtistAlbumRelationshipsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ArtistAlbumRelationshipsTable,
          ArtistAlbumRelationship
        > {
  $$ArtistAlbumRelationshipsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedArtistsTable _artistIdTable(_$AppDatabase db) =>
      db.cachedArtists.createAlias(
        $_aliasNameGenerator(
          db.artistAlbumRelationships.artistId,
          db.cachedArtists.id,
        ),
      );

  $$CachedArtistsTableProcessedTableManager get artistId {
    final $_column = $_itemColumn<String>('artist_id')!;

    final manager = $$CachedArtistsTableTableManager(
      $_db,
      $_db.cachedArtists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_artistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CachedAlbumsTable _albumIdTable(_$AppDatabase db) =>
      db.cachedAlbums.createAlias(
        $_aliasNameGenerator(
          db.artistAlbumRelationships.albumId,
          db.cachedAlbums.id,
        ),
      );

  $$CachedAlbumsTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<String>('album_id')!;

    final manager = $$CachedAlbumsTableTableManager(
      $_db,
      $_db.cachedAlbums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ArtistAlbumRelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $ArtistAlbumRelationshipsTable> {
  $$ArtistAlbumRelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedArtistsTableFilterComposer get artistId {
    final $$CachedArtistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableFilterComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedAlbumsTableFilterComposer get albumId {
    final $$CachedAlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableFilterComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistAlbumRelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArtistAlbumRelationshipsTable> {
  $$ArtistAlbumRelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedArtistsTableOrderingComposer get artistId {
    final $$CachedArtistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedAlbumsTableOrderingComposer get albumId {
    final $$CachedAlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistAlbumRelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArtistAlbumRelationshipsTable> {
  $$ArtistAlbumRelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  $$CachedArtistsTableAnnotationComposer get artistId {
    final $$CachedArtistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.artistId,
      referencedTable: $db.cachedArtists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedArtistsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedArtists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedAlbumsTableAnnotationComposer get albumId {
    final $$CachedAlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.cachedAlbums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedAlbums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ArtistAlbumRelationshipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArtistAlbumRelationshipsTable,
          ArtistAlbumRelationship,
          $$ArtistAlbumRelationshipsTableFilterComposer,
          $$ArtistAlbumRelationshipsTableOrderingComposer,
          $$ArtistAlbumRelationshipsTableAnnotationComposer,
          $$ArtistAlbumRelationshipsTableCreateCompanionBuilder,
          $$ArtistAlbumRelationshipsTableUpdateCompanionBuilder,
          (ArtistAlbumRelationship, $$ArtistAlbumRelationshipsTableReferences),
          ArtistAlbumRelationship,
          PrefetchHooks Function({bool artistId, bool albumId})
        > {
  $$ArtistAlbumRelationshipsTableTableManager(
    _$AppDatabase db,
    $ArtistAlbumRelationshipsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistAlbumRelationshipsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ArtistAlbumRelationshipsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ArtistAlbumRelationshipsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> artistId = const Value.absent(),
                Value<String> albumId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistAlbumRelationshipsCompanion(
                artistId: artistId,
                albumId: albumId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String artistId,
                required String albumId,
                required int orderIndex,
                Value<int> rowid = const Value.absent(),
              }) => ArtistAlbumRelationshipsCompanion.insert(
                artistId: artistId,
                albumId: albumId,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ArtistAlbumRelationshipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({artistId = false, albumId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (artistId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.artistId,
                                referencedTable:
                                    $$ArtistAlbumRelationshipsTableReferences
                                        ._artistIdTable(db),
                                referencedColumn:
                                    $$ArtistAlbumRelationshipsTableReferences
                                        ._artistIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable:
                                    $$ArtistAlbumRelationshipsTableReferences
                                        ._albumIdTable(db),
                                referencedColumn:
                                    $$ArtistAlbumRelationshipsTableReferences
                                        ._albumIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ArtistAlbumRelationshipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArtistAlbumRelationshipsTable,
      ArtistAlbumRelationship,
      $$ArtistAlbumRelationshipsTableFilterComposer,
      $$ArtistAlbumRelationshipsTableOrderingComposer,
      $$ArtistAlbumRelationshipsTableAnnotationComposer,
      $$ArtistAlbumRelationshipsTableCreateCompanionBuilder,
      $$ArtistAlbumRelationshipsTableUpdateCompanionBuilder,
      (ArtistAlbumRelationship, $$ArtistAlbumRelationshipsTableReferences),
      ArtistAlbumRelationship,
      PrefetchHooks Function({bool artistId, bool albumId})
    >;
typedef $$CachedLabelSearchesTableCreateCompanionBuilder =
    CachedLabelSearchesCompanion Function({
      required String labelName,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedLabelSearchesTableUpdateCompanionBuilder =
    CachedLabelSearchesCompanion Function({
      Value<String> labelName,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedLabelSearchesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedLabelSearchesTable,
          CachedLabelSearche
        > {
  $$CachedLabelSearchesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CachedLabelTracksTable, List<CachedLabelTrack>>
  _cachedLabelTracksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedLabelTracks,
        aliasName: $_aliasNameGenerator(
          db.cachedLabelSearches.labelName,
          db.cachedLabelTracks.labelName,
        ),
      );

  $$CachedLabelTracksTableProcessedTableManager get cachedLabelTracksRefs {
    final manager =
        $$CachedLabelTracksTableTableManager(
          $_db,
          $_db.cachedLabelTracks,
        ).filter(
          (f) => f.labelName.labelName.sqlEquals(
            $_itemColumn<String>('label_name')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _cachedLabelTracksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedLabelSearchesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLabelSearchesTable> {
  $$CachedLabelSearchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get labelName => $composableBuilder(
    column: $table.labelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedLabelTracksRefs(
    Expression<bool> Function($$CachedLabelTracksTableFilterComposer f) f,
  ) {
    final $$CachedLabelTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelName,
      referencedTable: $db.cachedLabelTracks,
      getReferencedColumn: (t) => t.labelName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedLabelTracksTableFilterComposer(
            $db: $db,
            $table: $db.cachedLabelTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedLabelSearchesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLabelSearchesTable> {
  $$CachedLabelSearchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get labelName => $composableBuilder(
    column: $table.labelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLabelSearchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLabelSearchesTable> {
  $$CachedLabelSearchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get labelName =>
      $composableBuilder(column: $table.labelName, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> cachedLabelTracksRefs<T extends Object>(
    Expression<T> Function($$CachedLabelTracksTableAnnotationComposer a) f,
  ) {
    final $$CachedLabelTracksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.labelName,
          referencedTable: $db.cachedLabelTracks,
          getReferencedColumn: (t) => t.labelName,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedLabelTracksTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedLabelTracks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedLabelSearchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedLabelSearchesTable,
          CachedLabelSearche,
          $$CachedLabelSearchesTableFilterComposer,
          $$CachedLabelSearchesTableOrderingComposer,
          $$CachedLabelSearchesTableAnnotationComposer,
          $$CachedLabelSearchesTableCreateCompanionBuilder,
          $$CachedLabelSearchesTableUpdateCompanionBuilder,
          (CachedLabelSearche, $$CachedLabelSearchesTableReferences),
          CachedLabelSearche,
          PrefetchHooks Function({bool cachedLabelTracksRefs})
        > {
  $$CachedLabelSearchesTableTableManager(
    _$AppDatabase db,
    $CachedLabelSearchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLabelSearchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLabelSearchesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedLabelSearchesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> labelName = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLabelSearchesCompanion(
                labelName: labelName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String labelName,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedLabelSearchesCompanion.insert(
                labelName: labelName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedLabelSearchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedLabelTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedLabelTracksRefs) db.cachedLabelTracks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedLabelTracksRefs)
                    await $_getPrefetchedData<
                      CachedLabelSearche,
                      $CachedLabelSearchesTable,
                      CachedLabelTrack
                    >(
                      currentTable: table,
                      referencedTable: $$CachedLabelSearchesTableReferences
                          ._cachedLabelTracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedLabelSearchesTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedLabelTracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.labelName == item.labelName,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedLabelSearchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedLabelSearchesTable,
      CachedLabelSearche,
      $$CachedLabelSearchesTableFilterComposer,
      $$CachedLabelSearchesTableOrderingComposer,
      $$CachedLabelSearchesTableAnnotationComposer,
      $$CachedLabelSearchesTableCreateCompanionBuilder,
      $$CachedLabelSearchesTableUpdateCompanionBuilder,
      (CachedLabelSearche, $$CachedLabelSearchesTableReferences),
      CachedLabelSearche,
      PrefetchHooks Function({bool cachedLabelTracksRefs})
    >;
typedef $$CachedLabelTracksTableCreateCompanionBuilder =
    CachedLabelTracksCompanion Function({
      required String trackId,
      required String labelName,
      required String uri,
      required String name,
      required String artistNames,
      Value<String?> albumId,
      Value<String?> albumName,
      Value<String?> releaseDate,
      Value<int> rowid,
    });
typedef $$CachedLabelTracksTableUpdateCompanionBuilder =
    CachedLabelTracksCompanion Function({
      Value<String> trackId,
      Value<String> labelName,
      Value<String> uri,
      Value<String> name,
      Value<String> artistNames,
      Value<String?> albumId,
      Value<String?> albumName,
      Value<String?> releaseDate,
      Value<int> rowid,
    });

final class $$CachedLabelTracksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedLabelTracksTable,
          CachedLabelTrack
        > {
  $$CachedLabelTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedLabelSearchesTable _labelNameTable(_$AppDatabase db) =>
      db.cachedLabelSearches.createAlias(
        $_aliasNameGenerator(
          db.cachedLabelTracks.labelName,
          db.cachedLabelSearches.labelName,
        ),
      );

  $$CachedLabelSearchesTableProcessedTableManager get labelName {
    final $_column = $_itemColumn<String>('label_name')!;

    final manager = $$CachedLabelSearchesTableTableManager(
      $_db,
      $_db.cachedLabelSearches,
    ).filter((f) => f.labelName.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labelNameTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedLabelTracksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLabelTracksTable> {
  $$CachedLabelTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumName => $composableBuilder(
    column: $table.albumName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedLabelSearchesTableFilterComposer get labelName {
    final $$CachedLabelSearchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labelName,
      referencedTable: $db.cachedLabelSearches,
      getReferencedColumn: (t) => t.labelName,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedLabelSearchesTableFilterComposer(
            $db: $db,
            $table: $db.cachedLabelSearches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedLabelTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLabelTracksTable> {
  $$CachedLabelTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumName => $composableBuilder(
    column: $table.albumName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedLabelSearchesTableOrderingComposer get labelName {
    final $$CachedLabelSearchesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.labelName,
          referencedTable: $db.cachedLabelSearches,
          getReferencedColumn: (t) => t.labelName,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedLabelSearchesTableOrderingComposer(
                $db: $db,
                $table: $db.cachedLabelSearches,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CachedLabelTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLabelTracksTable> {
  $$CachedLabelTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => column,
  );

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get albumName =>
      $composableBuilder(column: $table.albumName, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  $$CachedLabelSearchesTableAnnotationComposer get labelName {
    final $$CachedLabelSearchesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.labelName,
          referencedTable: $db.cachedLabelSearches,
          getReferencedColumn: (t) => t.labelName,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedLabelSearchesTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedLabelSearches,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CachedLabelTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedLabelTracksTable,
          CachedLabelTrack,
          $$CachedLabelTracksTableFilterComposer,
          $$CachedLabelTracksTableOrderingComposer,
          $$CachedLabelTracksTableAnnotationComposer,
          $$CachedLabelTracksTableCreateCompanionBuilder,
          $$CachedLabelTracksTableUpdateCompanionBuilder,
          (CachedLabelTrack, $$CachedLabelTracksTableReferences),
          CachedLabelTrack,
          PrefetchHooks Function({bool labelName})
        > {
  $$CachedLabelTracksTableTableManager(
    _$AppDatabase db,
    $CachedLabelTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLabelTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLabelTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLabelTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> labelName = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> artistNames = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumName = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLabelTracksCompanion(
                trackId: trackId,
                labelName: labelName,
                uri: uri,
                name: name,
                artistNames: artistNames,
                albumId: albumId,
                albumName: albumName,
                releaseDate: releaseDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String labelName,
                required String uri,
                required String name,
                required String artistNames,
                Value<String?> albumId = const Value.absent(),
                Value<String?> albumName = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLabelTracksCompanion.insert(
                trackId: trackId,
                labelName: labelName,
                uri: uri,
                name: name,
                artistNames: artistNames,
                albumId: albumId,
                albumName: albumName,
                releaseDate: releaseDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedLabelTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({labelName = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (labelName) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labelName,
                                referencedTable:
                                    $$CachedLabelTracksTableReferences
                                        ._labelNameTable(db),
                                referencedColumn:
                                    $$CachedLabelTracksTableReferences
                                        ._labelNameTable(db)
                                        .labelName,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedLabelTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedLabelTracksTable,
      CachedLabelTrack,
      $$CachedLabelTracksTableFilterComposer,
      $$CachedLabelTracksTableOrderingComposer,
      $$CachedLabelTracksTableAnnotationComposer,
      $$CachedLabelTracksTableCreateCompanionBuilder,
      $$CachedLabelTracksTableUpdateCompanionBuilder,
      (CachedLabelTrack, $$CachedLabelTracksTableReferences),
      CachedLabelTrack,
      PrefetchHooks Function({bool labelName})
    >;
typedef $$CacheMetadataTableCreateCompanionBuilder =
    CacheMetadataCompanion Function({
      Value<int> id,
      Value<DateTime?> created,
      Value<DateTime?> lastUpdated,
    });
typedef $$CacheMetadataTableUpdateCompanionBuilder =
    CacheMetadataCompanion Function({
      Value<int> id,
      Value<DateTime?> created,
      Value<DateTime?> lastUpdated,
    });

class $$CacheMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetadataTable> {
  $$CacheMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$CacheMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheMetadataTable,
          CacheMetadataData,
          $$CacheMetadataTableFilterComposer,
          $$CacheMetadataTableOrderingComposer,
          $$CacheMetadataTableAnnotationComposer,
          $$CacheMetadataTableCreateCompanionBuilder,
          $$CacheMetadataTableUpdateCompanionBuilder,
          (
            CacheMetadataData,
            BaseReferences<
              _$AppDatabase,
              $CacheMetadataTable,
              CacheMetadataData
            >,
          ),
          CacheMetadataData,
          PrefetchHooks Function()
        > {
  $$CacheMetadataTableTableManager(_$AppDatabase db, $CacheMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
              }) => CacheMetadataCompanion(
                id: id,
                created: created,
                lastUpdated: lastUpdated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                Value<DateTime?> lastUpdated = const Value.absent(),
              }) => CacheMetadataCompanion.insert(
                id: id,
                created: created,
                lastUpdated: lastUpdated,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheMetadataTable,
      CacheMetadataData,
      $$CacheMetadataTableFilterComposer,
      $$CacheMetadataTableOrderingComposer,
      $$CacheMetadataTableAnnotationComposer,
      $$CacheMetadataTableCreateCompanionBuilder,
      $$CacheMetadataTableUpdateCompanionBuilder,
      (
        CacheMetadataData,
        BaseReferences<_$AppDatabase, $CacheMetadataTable, CacheMetadataData>,
      ),
      CacheMetadataData,
      PrefetchHooks Function()
    >;
typedef $$SyncTrackMappingsTableCreateCompanionBuilder =
    SyncTrackMappingsCompanion Function({
      required String spotifyTrackId,
      required String rekordboxSongId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SyncTrackMappingsTableUpdateCompanionBuilder =
    SyncTrackMappingsCompanion Function({
      Value<String> spotifyTrackId,
      Value<String> rekordboxSongId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SyncTrackMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncTrackMappingsTable> {
  $$SyncTrackMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rekordboxSongId => $composableBuilder(
    column: $table.rekordboxSongId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncTrackMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncTrackMappingsTable> {
  $$SyncTrackMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rekordboxSongId => $composableBuilder(
    column: $table.rekordboxSongId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncTrackMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncTrackMappingsTable> {
  $$SyncTrackMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rekordboxSongId => $composableBuilder(
    column: $table.rekordboxSongId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncTrackMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncTrackMappingsTable,
          SyncTrackMapping,
          $$SyncTrackMappingsTableFilterComposer,
          $$SyncTrackMappingsTableOrderingComposer,
          $$SyncTrackMappingsTableAnnotationComposer,
          $$SyncTrackMappingsTableCreateCompanionBuilder,
          $$SyncTrackMappingsTableUpdateCompanionBuilder,
          (
            SyncTrackMapping,
            BaseReferences<
              _$AppDatabase,
              $SyncTrackMappingsTable,
              SyncTrackMapping
            >,
          ),
          SyncTrackMapping,
          PrefetchHooks Function()
        > {
  $$SyncTrackMappingsTableTableManager(
    _$AppDatabase db,
    $SyncTrackMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTrackMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTrackMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTrackMappingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> spotifyTrackId = const Value.absent(),
                Value<String> rekordboxSongId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncTrackMappingsCompanion(
                spotifyTrackId: spotifyTrackId,
                rekordboxSongId: rekordboxSongId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String spotifyTrackId,
                required String rekordboxSongId,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncTrackMappingsCompanion.insert(
                spotifyTrackId: spotifyTrackId,
                rekordboxSongId: rekordboxSongId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncTrackMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncTrackMappingsTable,
      SyncTrackMapping,
      $$SyncTrackMappingsTableFilterComposer,
      $$SyncTrackMappingsTableOrderingComposer,
      $$SyncTrackMappingsTableAnnotationComposer,
      $$SyncTrackMappingsTableCreateCompanionBuilder,
      $$SyncTrackMappingsTableUpdateCompanionBuilder,
      (
        SyncTrackMapping,
        BaseReferences<
          _$AppDatabase,
          $SyncTrackMappingsTable,
          SyncTrackMapping
        >,
      ),
      SyncTrackMapping,
      PrefetchHooks Function()
    >;
typedef $$SyncMissingTracksTableCreateCompanionBuilder =
    SyncMissingTracksCompanion Function({
      required String spotifyTrackId,
      required String artist,
      required String title,
      Value<String?> itunesUrl,
      required DateTime lastInsertedAt,
      Value<int> rowid,
    });
typedef $$SyncMissingTracksTableUpdateCompanionBuilder =
    SyncMissingTracksCompanion Function({
      Value<String> spotifyTrackId,
      Value<String> artist,
      Value<String> title,
      Value<String?> itunesUrl,
      Value<DateTime> lastInsertedAt,
      Value<int> rowid,
    });

class $$SyncMissingTracksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMissingTracksTable> {
  $$SyncMissingTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itunesUrl => $composableBuilder(
    column: $table.itunesUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInsertedAt => $composableBuilder(
    column: $table.lastInsertedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMissingTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMissingTracksTable> {
  $$SyncMissingTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itunesUrl => $composableBuilder(
    column: $table.itunesUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInsertedAt => $composableBuilder(
    column: $table.lastInsertedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMissingTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMissingTracksTable> {
  $$SyncMissingTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get spotifyTrackId => $composableBuilder(
    column: $table.spotifyTrackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get itunesUrl =>
      $composableBuilder(column: $table.itunesUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInsertedAt => $composableBuilder(
    column: $table.lastInsertedAt,
    builder: (column) => column,
  );
}

class $$SyncMissingTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMissingTracksTable,
          SyncMissingTrack,
          $$SyncMissingTracksTableFilterComposer,
          $$SyncMissingTracksTableOrderingComposer,
          $$SyncMissingTracksTableAnnotationComposer,
          $$SyncMissingTracksTableCreateCompanionBuilder,
          $$SyncMissingTracksTableUpdateCompanionBuilder,
          (
            SyncMissingTrack,
            BaseReferences<
              _$AppDatabase,
              $SyncMissingTracksTable,
              SyncMissingTrack
            >,
          ),
          SyncMissingTrack,
          PrefetchHooks Function()
        > {
  $$SyncMissingTracksTableTableManager(
    _$AppDatabase db,
    $SyncMissingTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMissingTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMissingTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMissingTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> spotifyTrackId = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> itunesUrl = const Value.absent(),
                Value<DateTime> lastInsertedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMissingTracksCompanion(
                spotifyTrackId: spotifyTrackId,
                artist: artist,
                title: title,
                itunesUrl: itunesUrl,
                lastInsertedAt: lastInsertedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String spotifyTrackId,
                required String artist,
                required String title,
                Value<String?> itunesUrl = const Value.absent(),
                required DateTime lastInsertedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMissingTracksCompanion.insert(
                spotifyTrackId: spotifyTrackId,
                artist: artist,
                title: title,
                itunesUrl: itunesUrl,
                lastInsertedAt: lastInsertedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMissingTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMissingTracksTable,
      SyncMissingTrack,
      $$SyncMissingTracksTableFilterComposer,
      $$SyncMissingTracksTableOrderingComposer,
      $$SyncMissingTracksTableAnnotationComposer,
      $$SyncMissingTracksTableCreateCompanionBuilder,
      $$SyncMissingTracksTableUpdateCompanionBuilder,
      (
        SyncMissingTrack,
        BaseReferences<
          _$AppDatabase,
          $SyncMissingTracksTable,
          SyncMissingTrack
        >,
      ),
      SyncMissingTrack,
      PrefetchHooks Function()
    >;
typedef $$SyncPlaylistsTableCreateCompanionBuilder =
    SyncPlaylistsCompanion Function({
      required String playlistId,
      required String snapshotId,
      required String name,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$SyncPlaylistsTableUpdateCompanionBuilder =
    SyncPlaylistsCompanion Function({
      Value<String> playlistId,
      Value<String> snapshotId,
      Value<String> name,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$SyncPlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPlaylistsTable> {
  $$SyncPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPlaylistsTable> {
  $$SyncPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPlaylistsTable> {
  $$SyncPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshotId => $composableBuilder(
    column: $table.snapshotId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$SyncPlaylistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPlaylistsTable,
          SyncPlaylist,
          $$SyncPlaylistsTableFilterComposer,
          $$SyncPlaylistsTableOrderingComposer,
          $$SyncPlaylistsTableAnnotationComposer,
          $$SyncPlaylistsTableCreateCompanionBuilder,
          $$SyncPlaylistsTableUpdateCompanionBuilder,
          (
            SyncPlaylist,
            BaseReferences<_$AppDatabase, $SyncPlaylistsTable, SyncPlaylist>,
          ),
          SyncPlaylist,
          PrefetchHooks Function()
        > {
  $$SyncPlaylistsTableTableManager(_$AppDatabase db, $SyncPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> snapshotId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPlaylistsCompanion(
                playlistId: playlistId,
                snapshotId: snapshotId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String snapshotId,
                required String name,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncPlaylistsCompanion.insert(
                playlistId: playlistId,
                snapshotId: snapshotId,
                name: name,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPlaylistsTable,
      SyncPlaylist,
      $$SyncPlaylistsTableFilterComposer,
      $$SyncPlaylistsTableOrderingComposer,
      $$SyncPlaylistsTableAnnotationComposer,
      $$SyncPlaylistsTableCreateCompanionBuilder,
      $$SyncPlaylistsTableUpdateCompanionBuilder,
      (
        SyncPlaylist,
        BaseReferences<_$AppDatabase, $SyncPlaylistsTable, SyncPlaylist>,
      ),
      SyncPlaylist,
      PrefetchHooks Function()
    >;
typedef $$SyncPlaylistTracksTableCreateCompanionBuilder =
    SyncPlaylistTracksCompanion Function({
      required String playlistId,
      required String trackId,
      required String name,
      required String artistNames,
      required int orderIndex,
      Value<int> rowid,
    });
typedef $$SyncPlaylistTracksTableUpdateCompanionBuilder =
    SyncPlaylistTracksCompanion Function({
      Value<String> playlistId,
      Value<String> trackId,
      Value<String> name,
      Value<String> artistNames,
      Value<int> orderIndex,
      Value<int> rowid,
    });

class $$SyncPlaylistTracksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPlaylistTracksTable> {
  $$SyncPlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPlaylistTracksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPlaylistTracksTable> {
  $$SyncPlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPlaylistTracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPlaylistTracksTable> {
  $$SyncPlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get artistNames => $composableBuilder(
    column: $table.artistNames,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$SyncPlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPlaylistTracksTable,
          SyncPlaylistTrack,
          $$SyncPlaylistTracksTableFilterComposer,
          $$SyncPlaylistTracksTableOrderingComposer,
          $$SyncPlaylistTracksTableAnnotationComposer,
          $$SyncPlaylistTracksTableCreateCompanionBuilder,
          $$SyncPlaylistTracksTableUpdateCompanionBuilder,
          (
            SyncPlaylistTrack,
            BaseReferences<
              _$AppDatabase,
              $SyncPlaylistTracksTable,
              SyncPlaylistTrack
            >,
          ),
          SyncPlaylistTrack,
          PrefetchHooks Function()
        > {
  $$SyncPlaylistTracksTableTableManager(
    _$AppDatabase db,
    $SyncPlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPlaylistTracksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> artistNames = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPlaylistTracksCompanion(
                playlistId: playlistId,
                trackId: trackId,
                name: name,
                artistNames: artistNames,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String trackId,
                required String name,
                required String artistNames,
                required int orderIndex,
                Value<int> rowid = const Value.absent(),
              }) => SyncPlaylistTracksCompanion.insert(
                playlistId: playlistId,
                trackId: trackId,
                name: name,
                artistNames: artistNames,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPlaylistTracksTable,
      SyncPlaylistTrack,
      $$SyncPlaylistTracksTableFilterComposer,
      $$SyncPlaylistTracksTableOrderingComposer,
      $$SyncPlaylistTracksTableAnnotationComposer,
      $$SyncPlaylistTracksTableCreateCompanionBuilder,
      $$SyncPlaylistTracksTableUpdateCompanionBuilder,
      (
        SyncPlaylistTrack,
        BaseReferences<
          _$AppDatabase,
          $SyncPlaylistTracksTable,
          SyncPlaylistTrack
        >,
      ),
      SyncPlaylistTrack,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedPlaylistsTableTableManager get cachedPlaylists =>
      $$CachedPlaylistsTableTableManager(_db, _db.cachedPlaylists);
  $$CachedPlaylistTracksTableTableManager get cachedPlaylistTracks =>
      $$CachedPlaylistTracksTableTableManager(_db, _db.cachedPlaylistTracks);
  $$CachedAlbumsTableTableManager get cachedAlbums =>
      $$CachedAlbumsTableTableManager(_db, _db.cachedAlbums);
  $$TrackAlbumMappingsTableTableManager get trackAlbumMappings =>
      $$TrackAlbumMappingsTableTableManager(_db, _db.trackAlbumMappings);
  $$CachedArtistsTableTableManager get cachedArtists =>
      $$CachedArtistsTableTableManager(_db, _db.cachedArtists);
  $$CachedArtistAlbumListsTableTableManager get cachedArtistAlbumLists =>
      $$CachedArtistAlbumListsTableTableManager(
        _db,
        _db.cachedArtistAlbumLists,
      );
  $$ArtistAlbumRelationshipsTableTableManager get artistAlbumRelationships =>
      $$ArtistAlbumRelationshipsTableTableManager(
        _db,
        _db.artistAlbumRelationships,
      );
  $$CachedLabelSearchesTableTableManager get cachedLabelSearches =>
      $$CachedLabelSearchesTableTableManager(_db, _db.cachedLabelSearches);
  $$CachedLabelTracksTableTableManager get cachedLabelTracks =>
      $$CachedLabelTracksTableTableManager(_db, _db.cachedLabelTracks);
  $$CacheMetadataTableTableManager get cacheMetadata =>
      $$CacheMetadataTableTableManager(_db, _db.cacheMetadata);
  $$SyncTrackMappingsTableTableManager get syncTrackMappings =>
      $$SyncTrackMappingsTableTableManager(_db, _db.syncTrackMappings);
  $$SyncMissingTracksTableTableManager get syncMissingTracks =>
      $$SyncMissingTracksTableTableManager(_db, _db.syncMissingTracks);
  $$SyncPlaylistsTableTableManager get syncPlaylists =>
      $$SyncPlaylistsTableTableManager(_db, _db.syncPlaylists);
  $$SyncPlaylistTracksTableTableManager get syncPlaylistTracks =>
      $$SyncPlaylistTracksTableTableManager(_db, _db.syncPlaylistTracks);
}
