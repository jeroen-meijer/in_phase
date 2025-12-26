/// Musical key and Camelot key mapping utilities.
///
/// Maps between natural/chromatic keys (e.g., "F#", "Am") and Camelot keys
/// (e.g., "4A", "8B").
///
/// Camelot wheel mapping:
/// - Major keys (B): 1B=B, 2B=F#, 3B=Db, 4B=Ab, 5B=Eb, 6B=Bb, 7B=F, 8B=C,
///   9B=G, 10B=D, 11B=A, 12B=E
/// - Minor keys (A): 1A=G#m, 2A=D#m, 3A=Bbm, 4A=Fm, 5A=Cm, 6A=Gm, 7A=Dm,
///   8A=Am, 9A=Em, 10A=Bm, 11A=F#m, 12A=C#m
enum MusicalKey {
  majAb('Ab', isMaj: true),
  majA('A', isMaj: true),
  majBb('Bb', isMaj: true),
  majB('B', isMaj: true),
  majC('C', isMaj: true),
  majDb('Db', isMaj: true),
  majD('D', isMaj: true),
  majEb('Eb', isMaj: true),
  majE('E', isMaj: true),
  majF('F', isMaj: true),
  majFSharp('F#', isMaj: true),
  majG('G', isMaj: true),

  minAb('Abm', isMaj: false),
  minA('Am', isMaj: false),
  minBb('Bbm', isMaj: false),
  minB('Bm', isMaj: false),
  minC('Cm', isMaj: false),
  minDb('C#m', isMaj: false),
  minD('Dm', isMaj: false),
  minEb('D#m', isMaj: false),
  minE('Em', isMaj: false),
  minF('Fm', isMaj: false),
  minFSharp('F#m', isMaj: false),
  minG('Gm', isMaj: false)
  ;

  const MusicalKey(this.title, {required this.isMaj});

  final String title;
  final bool isMaj;

  bool get isMin => !isMaj;

  CamelotKey get camelotKey {
    return switch (this) {
      MusicalKey.majAb => CamelotKey.b4,
      MusicalKey.majA => CamelotKey.b11,
      MusicalKey.majBb => CamelotKey.b6,
      MusicalKey.majB => CamelotKey.b1,
      MusicalKey.majC => CamelotKey.b8,
      MusicalKey.majDb => CamelotKey.b3,
      MusicalKey.majD => CamelotKey.b10,
      MusicalKey.majEb => CamelotKey.b5,
      MusicalKey.majE => CamelotKey.b12,
      MusicalKey.majF => CamelotKey.b7,
      MusicalKey.majFSharp => CamelotKey.b2,
      MusicalKey.majG => CamelotKey.b9,
      MusicalKey.minAb => CamelotKey.a1,
      MusicalKey.minA => CamelotKey.a8,
      MusicalKey.minBb => CamelotKey.a3,
      MusicalKey.minB => CamelotKey.a10,
      MusicalKey.minC => CamelotKey.a5,
      MusicalKey.minDb => CamelotKey.a12,
      MusicalKey.minD => CamelotKey.a7,
      MusicalKey.minEb => CamelotKey.a2,
      MusicalKey.minE => CamelotKey.a9,
      MusicalKey.minF => CamelotKey.a4,
      MusicalKey.minFSharp => CamelotKey.a11,
      MusicalKey.minG => CamelotKey.a6,
    };
  }

  /// Attempts to parse a key string into a MusicalKey.
  ///
  /// Returns null if the key cannot be parsed.
  static MusicalKey? fromString(String key) {
    final normalized = key.trim();
    try {
      return values.firstWhere(
        (element) => element.title.toLowerCase() == normalized.toLowerCase(),
      );
    } catch (_) {
      // Try alternative spellings
      final altMap = {
        'G#': 'Ab',
        'G♯': 'Ab',
        'A#': 'Bb',
        'A♯': 'Bb',
        'C#': 'Db',
        'C♯': 'Db',
        'D#': 'Eb',
        'D♯': 'Eb',
        'F#': 'F#',
        'F♯': 'F#',
        'G#m': 'Abm',
        'G♯m': 'Abm',
        'A#m': 'Bbm',
        'A♯m': 'Bbm',
        'C#m': 'C#m',
        'C♯m': 'C#m',
        'D#m': 'D#m',
        'D♯m': 'D#m',
        'F#m': 'F#m',
        'F♯m': 'F#m',
        'Gbm': 'F#m',
        'G♭m': 'F#m',
        'Ebm': 'D#m',
        'E♭m': 'D#m',
        'Bbm': 'Bbm',
        'B♭m': 'Bbm',
        'Abm': 'Abm',
        'A♭m': 'Abm',
        'Dbm': 'C#m',
        'D♭m': 'C#m',
        'Gb': 'F#',
        'G♭': 'F#',
        'Eb': 'Eb',
        'E♭': 'Eb',
        'Bb': 'Bb',
        'B♭': 'Bb',
        'Ab': 'Ab',
        'A♭': 'Ab',
        'Db': 'Db',
        'D♭': 'Db',
      };

      final altKey = altMap[normalized] ?? normalized;
      try {
        return values.firstWhere(
          (element) => element.title.toLowerCase() == altKey.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }
  }
}

enum CamelotKey {
  a1('1A', isMaj: false),
  a2('2A', isMaj: false),
  a3('3A', isMaj: false),
  a4('4A', isMaj: false),
  a5('5A', isMaj: false),
  a6('6A', isMaj: false),
  a7('7A', isMaj: false),
  a8('8A', isMaj: false),
  a9('9A', isMaj: false),
  a10('10A', isMaj: false),
  a11('11A', isMaj: false),
  a12('12A', isMaj: false),
  b1('1B', isMaj: true),
  b2('2B', isMaj: true),
  b3('3B', isMaj: true),
  b4('4B', isMaj: true),
  b5('5B', isMaj: true),
  b6('6B', isMaj: true),
  b7('7B', isMaj: true),
  b8('8B', isMaj: true),
  b9('9B', isMaj: true),
  b10('10B', isMaj: true),
  b11('11B', isMaj: true),
  b12('12B', isMaj: true)
  ;

  const CamelotKey(this.title, {required this.isMaj});

  final String title;
  final bool isMaj;

  bool get isMin => !isMaj;

  MusicalKey get musicalKey {
    return MusicalKey.values.firstWhere(
      (e) => e.camelotKey == this,
    );
  }

  /// Attempts to parse a Camelot key string (e.g., "4A", "12B").
  ///
  /// Returns null if the key cannot be parsed.
  static CamelotKey? fromString(String camelotKey) {
    final normalized = camelotKey.trim();
    try {
      return values.firstWhere(
        (element) => element.title == normalized,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Converts a key string to Camelot format.
///
/// If the input is already in Camelot format (e.g., "4A", "12B"), returns it
/// unchanged.
/// If the input is a natural/chromatic key (e.g., "F#", "Am"), converts it to
/// Camelot.
///
/// Returns `null` if the key cannot be parsed.
String? mapKeyToCamelot(String? key) {
  if (key == null) return null;

  final normalized = key.trim();

  // Check if already in Camelot format
  if (CamelotKey.fromString(normalized) != null) {
    return normalized;
  }

  // Try to parse as a musical key and convert to Camelot
  final musicalKey = MusicalKey.fromString(normalized);
  if (musicalKey != null) {
    return musicalKey.camelotKey.title;
  }

  // If no match found, return original key
  return key;
}
