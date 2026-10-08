import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layering of the module, as a test.
///
/// With `domain/ data/ presentation/` folders the layers are visible in the
/// tree. With `models/ services/ providers/ pages/ widgets/` they are a
/// convention about which folder may import which, and a convention that
/// nothing checks erodes. This is the check.
///
///     pages, widgets  →  providers  →  services  →  models
///       (UI layer)      (UI logic)   (data layer)  (shared types)
void main() {
  const module = 'lib/src/modules/price_audit';
  const prefix = 'package:project_lab/src/modules/price_audit/';

  /// folder → the module folders its files may import from.
  const allowed = {
    'models': {'models'},
    'services': {'models', 'services'},
    'providers': {'models', 'services', 'providers'},
    'pages': {'models', 'providers', 'widgets', 'services'},
    'widgets': {'models', 'widgets'},
  };

  /// Pages and widgets reach services only through the contract.
  const contract = '${prefix}services/price_audit_repository.dart';

  Iterable<({String file, String folder, String import})> imports() sync* {
    for (final folder in allowed.keys) {
      final files = Directory('$module/$folder').listSync().whereType<File>();
      for (final file in files) {
        for (final line in file.readAsLinesSync()) {
          final match = RegExp(r"^import '([^']+)';").firstMatch(line);
          if (match == null) continue;
          yield (file: file.path, folder: folder, import: match[1]!);
        }
      }
    }
  }

  test('each folder imports only the folders below it', () {
    for (final (:file, :folder, :import) in imports()) {
      if (!import.startsWith(prefix)) continue;
      final target = import.substring(prefix.length).split('/').first;

      expect(allowed[folder], contains(target), reason: '$file → $import');
    }
  });

  test('pages see the repository contract, never an implementation', () {
    for (final (:file, :folder, :import) in imports()) {
      if (folder != 'pages' || !import.startsWith('${prefix}services/')) {
        continue;
      }

      expect(import, contract, reason: file);
    }
  });

  test('models and services are plain Dart: no Flutter, no Riverpod', () {
    for (final (:file, :folder, :import) in imports()) {
      if (folder != 'models' && folder != 'services') continue;

      expect(import, isNot(contains('flutter')), reason: file);
      expect(import, isNot(contains('riverpod')), reason: file);
    }
  });

  test('the module does not know the lab or the lessons exist', () {
    for (final (:file, folder: _, :import) in imports()) {
      expect(import, isNot(contains('/modules/lab/')), reason: file);
      expect(import, isNot(contains('/lessons/')), reason: file);
    }
  });
}
