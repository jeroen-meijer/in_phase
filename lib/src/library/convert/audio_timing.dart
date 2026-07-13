/// Sample timing helpers for converting Rekordbox positions to Engine DJ.
double rekordboxFrameToSamples(int frame, double sampleRate) =>
    frame * sampleRate / 150;

/// Converts Rekordbox milliseconds to PCM sample offsets for Engine.
///
/// [encoderDelaySamples] is subtracted for lossy formats so grid/cue markers
/// line up with Engine's waveform display.
double rekordboxMsToSamples(
  int ms,
  double sampleRate, {
  double encoderDelaySamples = 0,
}) => ms * sampleRate / 1000 - encoderDelaySamples;

/// Estimated encoder priming at the start of lossy files, in PCM samples.
///
/// AAC/m4a typically has 2112 samples of delay at 44.1 kHz (~48 ms). MP3
/// varies; 529 samples is a common LAME offset.
double estimatedEncoderDelaySamples(String? fileType, double sampleRate) {
  switch (fileType?.toLowerCase()) {
    case 'm4a':
    case 'aac':
    case 'mp4':
      return 2112 * sampleRate / 44100;
    case 'mp3':
      return 529 * sampleRate / 44100;
    default:
      return 0;
  }
}

/// Preferred sample offset for a Rekordbox cue.
///
/// Uses [inFrame] when present (more accurate for CDJ-style storage), falling
/// back to [inMsec] with optional encoder delay compensation.
double rekordboxCueToSamples({
  required int inMsec,
  required double sampleRate,
  int? inFrame,
  double encoderDelaySamples = 0,
}) {
  if (inFrame != null && inFrame > 0) {
    return rekordboxFrameToSamples(inFrame, sampleRate) - encoderDelaySamples;
  }
  return rekordboxMsToSamples(
    inMsec,
    sampleRate,
    encoderDelaySamples: encoderDelaySamples,
  );
}
