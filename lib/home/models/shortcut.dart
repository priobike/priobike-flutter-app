
/// The shortcut represents a saved route with a name.
class Shortcut {
  /// The name of the shortcut.
  final String name;

  /// Get the linebreaked name of the shortcut. The name is split into at most 2 lines, by a limit of 15 characters.
  String get linebreakedName {
    var result = name;
    var insertedLinebreaks = 0;
    for (var i = 0; i < name.length; i++) {
      if (i % 15 == 0 && i != 0) {
        if (insertedLinebreaks == 1) {
          // Truncate the name if it is too long
          result = result.substring(0, i);
          result += '...';
          break;
        }
        result = result.replaceRange(i, i + 1, '${result[i]}\n');
        insertedLinebreaks++;
      }
    }
    return result;
  }

  const Shortcut({required this.name});
}
