/// One-line preview of a task description for the task list: its first
/// non-empty line, with "…" when further lines follow.
///
/// Flutter's TextOverflow.ellipsis only fires when a line runs out of width.
/// A short first line followed by a line break gets cut silently, so the
/// hint that more text exists has to be added here.
String descriptionPreview(String description) {
  final lines = description
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return '';
  return lines.length > 1 ? '${lines.first}…' : lines.first;
}
