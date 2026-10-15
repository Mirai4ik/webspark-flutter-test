import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/path_task.dart';
import '../domain/task_result.dart';

class TaskApiException implements Exception {
  const TaskApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TaskApi {
  TaskApi({
    required SharedPreferences preferences,
    http.Client? client,
  })  : _preferences = preferences,
        _client = client ?? http.Client();

  static const String _urlKey = 'webspark_api_url';

  final SharedPreferences _preferences;
  final http.Client _client;

  String? get savedUrl => _preferences.getString(_urlKey);

  Future<void> saveUrl(String url) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      throw const TaskApiException(
        'Введіть коректний HTTP або HTTPS URL.',
      );
    }

    await _preferences.setString(_urlKey, uri.toString());
  }

  Uri _uri() {
    final value = savedUrl;

    if (value == null || value.trim().isEmpty) {
      throw const TaskApiException(
        'Спочатку вкажіть URL API.',
      );
    }

    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      throw const TaskApiException(
        'Збережений URL некоректний.',
      );
    }

    return uri;
  }

  Future<List<PathTask>> fetchTasks() async {
    late final http.Response response;

    try {
      response = await _client.get(
        _uri(),
        headers: const {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
    } catch (error) {
      throw TaskApiException(
        'Не вдалося отримати завдання з API: $error',
      );
    }

    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TaskApiException(
        _messageFrom(body) ??
            'Помилка завантаження завдань '
                '(HTTP ${response.statusCode}).',
      );
    }

    if (body is Map && body['error'] == true) {
      throw TaskApiException(
        _messageFrom(body) ??
            'Сервер повернув помилку під час отримання завдань.',
      );
    }

    final taskList = _extractTaskList(body);

    if (taskList.isEmpty) {
      throw const TaskApiException(
        'API не повернув жодного завдання.',
      );
    }

    return [
      for (var i = 0; i < taskList.length; i++)
        PathTask.fromJson(taskList[i], index: i),
    ];
  }

  Future<void> submitResults(List<TaskResult> results) async {
    if (results.isEmpty) {
      throw const TaskApiException(
        'Немає результатів для відправлення.',
      );
    }

    final resultsWithoutPath =
        results.where((result) => result.path.isEmpty).toList(growable: false);

    if (resultsWithoutPath.isNotEmpty) {
      final ids = resultsWithoutPath.map((result) => result.task.id).join(', ');

      throw TaskApiException(
        'Не вдалося знайти шлях для завдань: $ids.',
      );
    }

    final payload =
        results.map((result) => result.toApiJson()).toList(growable: false);

    late final http.Response response;

    try {
      response = await _client
          .post(
            _uri(),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      throw TaskApiException(
        'Не вдалося відправити результати: $error',
      );
    }

    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TaskApiException(
        _messageFrom(body) ??
            'Сервер відхилив результати '
                '(HTTP ${response.statusCode}).'
                '${_rawResponseSuffix(response)}',
      );
    }

    if (body is Map) {
      final serverMessage = _messageFrom(body);
      final data = body['data'];

      if (body['error'] == true) {
        throw TaskApiException(
          serverMessage ?? 'Сервер повернув помилку.',
        );
      }

      if (body['success'] == false) {
        throw TaskApiException(
          serverMessage ??
              'Сервер не підтвердив успішне надсилання результатів.',
        );
      }

      if (data is List) {
        final incorrectIds = <String>[];
        final unknownResults = <String>[];
        final confirmedIds = <String>{};

        for (final item in data) {
          if (item is! Map) {
            continue;
          }

          final id = (item['id'] ?? 'unknown').toString();
          final correct = item['correct'];

          if (correct == false) {
            incorrectIds.add(id);
          } else if (correct != true) {
            unknownResults.add(id);
          } else {
            confirmedIds.add(id);
          }
        }

        if (incorrectIds.isNotEmpty) {
          throw TaskApiException(
            'Сервер не зарахував результати для завдань: '
            '${incorrectIds.join(', ')}.'
            '${serverMessage == null ? '' : '\n$serverMessage'}'
            '${_rawResponseSuffix(response)}',
          );
        }

        if (unknownResults.isNotEmpty) {
          throw TaskApiException(
            'Сервер не повернув статус correct для завдань: '
            '${unknownResults.join(', ')}.'
            '${_rawResponseSuffix(response)}',
          );
        }

        if (results.every((result) => confirmedIds.contains(result.task.id))) {
          return;
        }
      }
    }

    throw const TaskApiException(
      'Сервер не підтвердив правильність усіх результатів.',
    );
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final text = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );

    if (text.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  List<dynamic> _extractTaskList(dynamic body) {
    if (body is List) {
      return body;
    }

    if (body is Map) {
      final data = body['data'];

      if (data is List) {
        return data;
      }

      for (final key in ['tasks', 'items', 'results']) {
        final value = body[key];

        if (value is List) {
          return value;
        }
      }

      if (data is Map) {
        for (final key in ['tasks', 'items']) {
          final value = data[key];

          if (value is List) {
            return value;
          }
        }
      }

      if (body['task'] is Map) {
        return [body['task']];
      }

      if (body.containsKey('field') ||
          body.containsKey('grid') ||
          body.containsKey('matrix')) {
        return [body];
      }

      final message = _messageFrom(body);

      if (message != null &&
          (body['error'] == true || body['success'] == false)) {
        throw TaskApiException(message);
      }
    }

    throw const TaskApiException(
      'Не вдалося знайти список завдань у відповіді API.',
    );
  }

  String? _messageFrom(dynamic body) {
    if (body is Map) {
      final value = body['message'] ?? body['detail'];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      final error = body['error'];

      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    return null;
  }

  String _rawResponseSuffix(http.Response response) {
    final text = utf8
        .decode(
          response.bodyBytes,
          allowMalformed: true,
        )
        .trim();

    if (text.isEmpty) {
      return '';
    }

    final shortened = text.length > 500 ? '${text.substring(0, 500)}…' : text;

    return '\nВідповідь сервера: $shortened';
  }
}
