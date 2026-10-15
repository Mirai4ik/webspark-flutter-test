import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:webspark_test_task/domain/path_task.dart';
import 'package:webspark_test_task/domain/shortest_path_solver.dart';
import 'package:webspark_test_task/domain/task_result.dart';

/// Run manually: dart run tool/verify_api.dart [API_URL]
Future<void> main(List<String> arguments) async {
  final uri = Uri.parse(arguments.isEmpty
      ? 'https://flutter.webspark.dev/flutter/api'
      : arguments.single);
  final client = http.Client();
  try {
    final response = await client.get(uri).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw HttpException('GET ${response.statusCode}: ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['error'] != false) throw StateError(response.body);
    final tasks = (body['data'] as List).map(PathTask.fromJson).toList();
    final results = [
      for (final task in tasks)
        TaskResult(task: task, path: const ShortestPathSolver().solve(task)),
    ];
    if (results.isEmpty || results.any((result) => result.path.isEmpty)) {
      throw StateError('No solution for one or more tasks.');
    }
    final payload = results.map((result) => result.toApiJson()).toList();
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
    final submission = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 45));
    stdout.writeln('POST ${submission.statusCode}: ${submission.body}');
    final confirmation = jsonDecode(submission.body) as Map<String, dynamic>;
    final statuses = confirmation['data'];
    if (submission.statusCode != 200 ||
        confirmation['error'] != false ||
        statuses is! List ||
        statuses.length != tasks.length ||
        results.any((result) => !statuses.any((status) =>
            status is Map &&
            status['id'] == result.task.id &&
            status['correct'] == true))) {
      throw StateError('The server did not accept every result.');
    }
    stdout.writeln('Verified: all ${tasks.length} results are correct.');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    client.close();
  }
}
