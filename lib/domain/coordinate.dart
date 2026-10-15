class Coordinate {
  const Coordinate({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;

  factory Coordinate.fromJson(dynamic value) {
    if (value is Map) {
      final x = value['x'] ?? value['column'] ?? value['col'];
      final y = value['y'] ?? value['row'];

      return Coordinate(
        x: _toInt(x),
        y: _toInt(y),
      );
    }

    if (value is List && value.length >= 2) {
      return Coordinate(
        x: _toInt(value[0]),
        y: _toInt(value[1]),
      );
    }

    if (value is String) {
      final match = RegExp(
        r'^\s*\(?\s*(\d+)[.,]\s*(\d+)\s*\)?\s*$',
      ).firstMatch(value);

      if (match != null) {
        return Coordinate(
          x: int.parse(match.group(1)!),
          y: int.parse(match.group(2)!),
        );
      }
    }

    throw FormatException(
      'Некоректний формат координати: $value',
    );
  }

  Map<String, int> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is Coordinate && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '($x.$y)';
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    if (!value.isFinite || value != value.truncateToDouble()) {
      throw FormatException(
        'Координата має бути цілим числом: $value',
      );
    }

    return value.toInt();
  }

  if (value is String) {
    final parsed = int.tryParse(value.trim());

    if (parsed != null) {
      return parsed;
    }
  }

  throw FormatException(
    'Неможливо перетворити значення на координату: $value',
  );
}
