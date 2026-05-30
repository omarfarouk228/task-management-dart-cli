import 'dart:io';

import 'package:dart_task_cli/cli/cli_runner.dart';
import 'package:dart_task_cli/repository/task_repository.dart';

void main(List<String> args) async {
  final home = Platform.environment['HOME'] ?? '.';
  final filePath = '$home/.dart_task_manager.json';

  final repo = TaskRepository(filePath);
  await repo.load();

  final cli = CliRunner(repo);
  await cli.run(args);
}
