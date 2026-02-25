/// ANSI escape code for bold (no color).
const _ansiBold = '\x1B[1m';

/// ANSI escape code to reset all attributes.
const _ansiReset = '\x1B[0m';

/// Wraps [text] with ANSI bold. Does not change color.
String bold(String text) => '$_ansiBold$text$_ansiReset';
