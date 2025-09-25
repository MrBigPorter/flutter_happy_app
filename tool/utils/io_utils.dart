import 'dart:io';

// if the file at [path] exists and its content is identical to [content], do nothing.
void writeFileIfChanged(String path, String content) {
  final file = File(path);
  if (file.existsSync()) {
    final existing = file.readAsStringSync();
    if (existing == content) {
      stdout.writeln('No changes to $path');
      return;
    }
  }
  file.writeAsStringSync(content);
  stdout.write("✍️ Updated $path");
}