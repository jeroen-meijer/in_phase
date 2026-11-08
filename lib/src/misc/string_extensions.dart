extension StringExtensions on String {
  String? get contentOrNull => switch (trim()) {
    '' => null,
    final content => content,
  };
}
