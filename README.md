# Dart Task Manager CLI

A command-line task manager built in pure Dart demonstrating OOP principles: abstract classes, interfaces, generics, inheritance, custom exceptions, and JSON persistence.

## Requirements

- Dart SDK ≥ 3.0.0

## Setup

```bash
dart pub get
```

## Usage

```bash
# Add a regular task
dart run bin/main.dart add "Fix login bug" -p medium -d 2026-06-01

# Add an urgent task (auto-upgrades when -n or -p high is used)
dart run bin/main.dart add "Deploy hotfix" -n "Server is down"

# List pending tasks sorted by priority (default)
dart run bin/main.dart list

# List all tasks (including completed), sorted by creation date
dart run bin/main.dart list --sort date --all

# Mark a task done
dart run bin/main.dart done <id>

# Update task fields
dart run bin/main.dart update <id> --title "Updated title" -p high

# Delete a task
dart run bin/main.dart delete <id>

# Help
dart run bin/main.dart --help
```

## Commands

| Command | Description |
|---------|-------------|
| `add <title>` | Add a new task |
| `list` | List tasks |
| `done <id>` | Mark a task as done |
| `update <id>` | Update task fields |
| `delete <id>` | Delete a task |

### `add` options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--priority` | `-p` | `medium` | `low`, `medium`, or `high` |
| `--deadline` | `-d` | — | Due date as `YYYY-MM-DD` |
| `--note` | `-n` | — | Urgency note — auto-upgrades to `UrgentTask` |

### `list` options

| Flag | Short | Default | Description |
|------|-------|---------|-------------|
| `--sort` | `-s` | `priority` | `priority` or `date` |
| `--all` | `-a` | false | Include completed tasks |

### `update` options

| Flag | Short | Description |
|------|-------|-------------|
| `--title` | `-t` | New title |
| `--priority` | `-p` | New priority (`low`, `medium`, `high`) — `RegularTask` only |
| `--deadline` | `-d` | New due date (`YYYY-MM-DD`) |
| `--note` | `-n` | New urgency note — `UrgentTask` only |

## Running Tests

```bash
dart test
```

Tests are split across multiple files:

```
test/
├── task_test.dart                        # Integration tests
├── models/
│   ├── priority_test.dart
│   ├── regular_task_test.dart
│   └── urgent_task_test.dart
├── repository/
│   └── task_repository_test.dart
└── cli/
    └── cli_runner_test.dart
```

## Architecture

```
lib/
├── cli/
│   └── cli_runner.dart         # Args parsing + command dispatch
├── exceptions/
│   └── task_exceptions.dart    # TaskNotFoundException, InvalidPriorityException, StorageException
├── interfaces/
│   ├── displayable.dart        # Displayable interface  →  String display()
│   └── serializable.dart       # Serializable interface →  Map<String,dynamic> toJson()
├── models/
│   ├── priority.dart           # Priority enum (low / medium / high)
│   ├── task.dart               # abstract Task implements Displayable, Serializable
│   ├── regular_task.dart       # RegularTask extends Task
│   └── urgent_task.dart        # UrgentTask extends Task (always Priority.high)
└── repository/
    ├── repository.dart         # abstract Repository<T> (generic CRUD interface)
    └── task_repository.dart    # TaskRepository extends Repository<Task>
bin/
└── main.dart                   # Entry point — persists to ~/.dart_task_manager.json
```

## Data Storage

Tasks are persisted to `~/.dart_task_manager.json` as a JSON array. The `type` field distinguishes `RegularTask` from `UrgentTask` during deserialization.

