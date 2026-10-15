import 'coordinate.dart';

class PathTask {
  const PathTask({
    required this.id,
    required this.field,
    required this.start,
    required this.end,
    this.raw = const {},
  });

  final String id;

  /// field[y][x]:
  /// '.' — вільна комірка;
  /// 'X' — заблокована комірка.
  final List<List<String>> field;

  final Coordinate start;
  final Coordinate end;

  final Map<String, dynamic> raw;

  int get size => field.length;

  int get width => field.isEmpty ? 0 : field.first.length;

  bool isInside(Coordinate point) {
    return point.y >= 0 &&
        point.y < field.length &&
        point.x >= 0 &&
        point.x < field[point.y].length;
  }

  bool isBlocked(Coordinate point) {
    if (!isInside(point)) {
      return true;
    }

    return field[point.y][point.x].toUpperCase() == 'X';
  }

  factory PathTask.fromJson(
    dynamic value, {
    int index = 0,
  }) {
    if (value is! Map) {
      throw const FormatException(
        'Завдання повинно бути JSON-об’єктом.',
      );
    }

    final map = Map<String, dynamic>.from(value);

    final rawField = map['field'] ?? map['grid'] ?? map['matrix'] ?? map['map'];

    if (rawField is! List || rawField.isEmpty) {
      throw FormatException(
        'У завданні ${map['id'] ?? index} відсутня сітка.',
      );
    }

    final parsedField = <List<String>>[];

    for (final row in rawField) {
      if (row is List) {
        parsedField.add(
          row.map((cell) => cell.toString()).toList(),
        );
      } else if (row is String) {
        parsedField.add(row.split(''));
      } else {
        throw const FormatException(
          'Рядок сітки повинен бути рядком або масивом.',
        );
      }
    }

    final width = parsedField.first.length;
    final height = parsedField.length;

    if (width < 2 || width >= 100 || height < 2 || height >= 100) {
      throw const FormatException(
        'Розміри сітки повинні бути від 2 до 99.',
      );
    }

    if (parsedField.any((row) => row.length != width)) {
      throw const FormatException(
        'Усі рядки сітки повинні мати однакову довжину.',
      );
    }

    if (width != height) {
      throw const FormatException('Сітка повинна бути квадратною.');
    }

    for (final row in parsedField) {
      for (final cell in row) {
        if (cell != '.' && cell.toUpperCase() != 'X') {
          throw FormatException(
            'Невідомий тип комірки: $cell',
          );
        }
      }
    }

    final startValue =
        map['start'] ?? map['start_position'] ?? map['startPosition'];

    final endValue = map['end'] ??
        map['finish'] ??
        map['end_position'] ??
        map['endPosition'];

    if (startValue == null || endValue == null) {
      throw FormatException(
        'У завданні ${map['id'] ?? index} '
        'не задані початкова та кінцева позиції.',
      );
    }

    final start = Coordinate.fromJson(startValue);
    final end = Coordinate.fromJson(endValue);

    final task = PathTask(
      id: (map['id'] ?? map['task_id'] ?? index).toString(),
      field: parsedField,
      start: start,
      end: end,
      raw: map,
    );

    if (!task.isInside(start) || !task.isInside(end)) {
      throw FormatException(
        'Завдання ${task.id}: початок або кінець '
        'знаходиться поза сіткою.',
      );
    }

    if (task.isBlocked(start) || task.isBlocked(end)) {
      throw FormatException(
        'Завдання ${task.id}: початкова або кінцева '
        'комірка заблокована.',
      );
    }

    return task;
  }
}
