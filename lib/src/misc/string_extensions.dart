extension StringExtensions on String {
  String? get contentOrNull => switch (trim()) {
    '' => null,
    final content => content,
  };

  bool get hasContent => contentOrNull != null;
}
