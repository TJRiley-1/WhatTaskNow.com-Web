/// Parse imported text into task names
List<String> parseImportText(String text) {
  final lines = text.split('\n');
  final tasks = <String>[];

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    // Remove common list markers: bullets, numbers, checkboxes
    line = line.replaceAll(RegExp(r'^[-*•◦▪️◾️✓✔☐☑□■●○]\s*'), '');
    line = line.replaceAll(RegExp(r'^\d+[.)]\s*'), '');
    line = line.replaceAll(RegExp(r'^\[[ xX]?\]\s*'), '');

    line = line.trim();
    if (line.isNotEmpty && line.length <= 100) {
      tasks.add(line);
    }
  }

  return tasks;
}

/// Parse CSV text into task names
List<String> parseCSV(String text) {
  final lines = text.split('\n');
  if (lines.length < 2) return [];

  final headers = lines[0].split(',').map((h) => h.trim().toLowerCase()).toList();
  final nameIndex = headers.indexWhere(
    (h) => h == 'name' || h == 'task' || h == 'title',
  );

  if (nameIndex == -1) {
    // No name column, treat first column of each row as task name
    return lines.skip(1).map((l) => l.split(',')[0].trim()).where((n) => n.isNotEmpty).toList();
  }

  final tasks = <String>[];
  for (var i = 1; i < lines.length; i++) {
    final values = lines[i].split(',');
    if (nameIndex < values.length) {
      final name = values[nameIndex].trim();
      if (name.isNotEmpty) {
        tasks.add(name);
      }
    }
  }

  return tasks;
}
