import 'dart:io';

class CSVCache {
  /// The currently pending lines.
  List<String> lines;

  /// The file reference.
  File file;

  /// The maximum number of lines to cache.
  int maxLines;

  /// The maximum number of lines in the file.
  /// When this limit is reached, the file is rotated.
  int? maxFileLines;

  CSVCache({
    required String header,
    required this.file,
    required this.maxLines,
    this.maxFileLines,
  }) : lines = [header];

  /// Add a line to the cache.
  Future<void> add(String line) async {
    lines.add(line);
    if (lines.length >= maxLines) await flush();
  }

  /// Flush the cache.
  Future<void> flush() async {
    if (lines.isEmpty) return;
    // Create the file if it does not exist.
    var fileIsNew = false;
    if (!await file.exists()) {
      await file.create(recursive: true);
      fileIsNew = true;
    }
    // Flush the cache and write the data to the file.
    final csv = lines.join("\n");
    lines.clear();
    // If the file is not new, append a newline.
    if (!fileIsNew) await file.writeAsString("\n", mode: FileMode.append, flush: true);
    await file.writeAsString(csv, mode: FileMode.append, flush: true);
    // Truncate the file if we have reached the maximum number of lines.
    if (maxFileLines != null) {
      final lines = await file.readAsLines();
      if (lines.length > maxFileLines!) {
        final newLines = lines.sublist(lines.length - maxFileLines!);
        // Keep the header.
        newLines.insert(0, lines.first);
        await file.writeAsString(newLines.join("\n"));
      }
    }
  }

  /// Get the file contents.
  Future<String> read() async {
    if (!await file.exists()) return '';
    return await file.readAsString();
  }
}
