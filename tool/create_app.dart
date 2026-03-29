import 'dart:io';

class AppInitConfig {
  AppInitConfig({
    required this.appName,
    required this.bundleId,
    required this.googleAuth,
    required this.googleDrive,
    required this.gemini,
    required this.driftDb,
    required this.dioNetwork,
    required this.demoMode,
    required this.dryRun,
  });

  final String appName;
  final String bundleId;
  final bool googleAuth;
  final bool googleDrive;
  final bool gemini;
  final bool driftDb;
  final bool dioNetwork;
  final bool demoMode;
  final bool dryRun;
}

class CurrentTemplateState {
  CurrentTemplateState({
    required this.appName,
    required this.bundleId,
    required this.googleAuth,
    required this.googleDrive,
    required this.gemini,
    required this.driftDb,
    required this.dioNetwork,
    required this.demoMode,
  });

  final String appName;
  final String bundleId;
  final bool googleAuth;
  final bool googleDrive;
  final bool gemini;
  final bool driftDb;
  final bool dioNetwork;
  final bool demoMode;
}

Future<void> main(List<String> args) async {
  try {
    if (args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return;
    }

    final repoRoot = Directory.current;
    final manifestFile = File('${repoRoot.path}/app_manifest.yaml');
    final appFeaturesFile = File(
      '${repoRoot.path}/lib/app/config/app_features.dart',
    );

    if (!manifestFile.existsSync() || !appFeaturesFile.existsSync()) {
      stderr.writeln('필수 파일이 없습니다. 저장소 루트에서 실행했는지 확인하세요.');
      exitCode = 2;
      return;
    }

    final flags = _parseArgs(args);
    final currentState = _readCurrentState(
      manifestFile.readAsStringSync(),
      appFeaturesFile.readAsStringSync(),
    );

    final config = AppInitConfig(
      appName: _resolveString(
        flagValue: flags['app-name'],
        prompt: '앱 이름',
        currentValue: currentState.appName,
      ),
      bundleId: _resolveString(
        flagValue: flags['bundle-id'],
        prompt: 'Bundle/Application ID',
        currentValue: currentState.bundleId,
      ),
      googleAuth: _resolveBool(
        flags: flags,
        name: 'google-auth',
        prompt: 'googleAuth 사용',
        currentValue: currentState.googleAuth,
      ),
      googleDrive: _resolveBool(
        flags: flags,
        name: 'google-drive',
        prompt: 'googleDrive 사용',
        currentValue: currentState.googleDrive,
      ),
      gemini: _resolveBool(
        flags: flags,
        name: 'gemini',
        prompt: 'gemini 사용',
        currentValue: currentState.gemini,
      ),
      driftDb: _resolveBool(
        flags: flags,
        name: 'drift-db',
        prompt: 'driftDb 사용',
        currentValue: currentState.driftDb,
      ),
      dioNetwork: _resolveBool(
        flags: flags,
        name: 'dio-network',
        prompt: 'dioNetwork 사용',
        currentValue: currentState.dioNetwork,
      ),
      demoMode: _resolveBool(
        flags: flags,
        name: 'demo-mode',
        prompt: 'demoMode 메타데이터 기록',
        currentValue: currentState.demoMode,
      ),
      dryRun: flags['dry-run'] == 'true',
    );

    if (!_isValidBundleId(config.bundleId)) {
      stderr.writeln(
        '유효하지 않은 bundle id 입니다: ${config.bundleId}\n예: com.example.myapp',
      );
      exitCode = 2;
      return;
    }

    stdout.writeln('''
초기화 예정:
- app name: ${config.appName}
- bundle id: ${config.bundleId}
- googleAuth: ${config.googleAuth}
- googleDrive: ${config.googleDrive}
- gemini: ${config.gemini}
- driftDb: ${config.driftDb}
- dioNetwork: ${config.dioNetwork}
- demoMode(metadata only): ${config.demoMode}
- dryRun: ${config.dryRun}
''');

    if (config.dryRun) {
      _printSummary(config, dryRun: true);
      return;
    }

    await _runRenameFlow(config);
    _updateManifest(manifestFile, config);
    _updateAppFeatures(appFeaturesFile, config);

    _printSummary(config, dryRun: false);
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  } on ProcessException catch (error) {
    stderr.writeln(error.message);
    exitCode = error.errorCode;
  }
}

void _printHelp() {
  stdout.writeln('''
사용법:
  dart run tool/create_app.dart

비대화형 예시:
  dart run tool/create_app.dart \\
    --app-name "PlanB" \\
    --bundle-id "com.example.planb" \\
    --google-auth true \\
    --google-drive true \\
    --gemini false \\
    --drift-db true \\
    --dio-network true \\
    --demo-mode false

옵션:
  --app-name <name>
  --bundle-id <id>
  --google-auth <true|false>
  --google-drive <true|false>
  --gemini <true|false>
  --drift-db <true|false>
  --dio-network <true|false>
  --demo-mode <true|false>
  --dry-run
''');
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) continue;

    final key = arg.substring(2);
    if (key == 'dry-run') {
      map[key] = 'true';
      continue;
    }

    if (i + 1 >= args.length) {
      throw ArgumentError('값이 없는 인자입니다: $arg');
    }

    map[key] = args[i + 1];
    i++;
  }

  return map;
}

CurrentTemplateState _readCurrentState(
  String manifestContent,
  String appFeaturesContent,
) {
  return CurrentTemplateState(
    appName: _readQuotedYamlValue(manifestContent, 'name') ?? 'Your App Name',
    bundleId:
        _readQuotedYamlValue(manifestContent, 'bundle_id') ??
        'com.yourcompany.yourapp',
    googleAuth: _readConstBool(appFeaturesContent, 'googleAuth') ?? true,
    googleDrive: _readConstBool(appFeaturesContent, 'googleDrive') ?? true,
    gemini: _readConstBool(appFeaturesContent, 'gemini') ?? true,
    driftDb: _readConstBool(appFeaturesContent, 'driftDb') ?? true,
    dioNetwork: _readConstBool(appFeaturesContent, 'dioNetwork') ?? true,
    demoMode: _readYamlBool(manifestContent, 'demo_mode') ?? false,
  );
}

String _resolveString({
  required String? flagValue,
  required String prompt,
  required String currentValue,
}) {
  if (flagValue != null && flagValue.trim().isNotEmpty) {
    return flagValue.trim();
  }

  stdout.write('$prompt [$currentValue]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  return input.isEmpty ? currentValue : input;
}

bool _resolveBool({
  required Map<String, String> flags,
  required String name,
  required String prompt,
  required bool currentValue,
}) {
  final flagValue = flags[name];
  if (flagValue != null) {
    final parsed = _parseBool(flagValue);
    if (parsed == null) {
      throw ArgumentError('bool 값이 잘못되었습니다: --$name $flagValue');
    }
    return parsed;
  }

  stdout.write('$prompt [${currentValue ? 'Y/n' : 'y/N'}]: ');
  final input = stdin.readLineSync()?.trim() ?? '';
  if (input.isEmpty) return currentValue;

  final parsed = _parseBool(input);
  if (parsed == null) {
    throw ArgumentError('bool 값이 잘못되었습니다: $input');
  }
  return parsed;
}

bool? _parseBool(String value) {
  switch (value.toLowerCase()) {
    case 'true':
    case 't':
    case 'yes':
    case 'y':
    case '1':
      return true;
    case 'false':
    case 'f':
    case 'no':
    case 'n':
    case '0':
      return false;
    default:
      return null;
  }
}

String? _readQuotedYamlValue(String content, String key) {
  final match = RegExp(
    '^\\s*$key:\\s*"([^"]*)"',
    multiLine: true,
  ).firstMatch(content);
  return match?.group(1);
}

bool? _readYamlBool(String content, String key) {
  final match = RegExp(
    '^\\s*$key:\\s*(true|false)',
    multiLine: true,
  ).firstMatch(content);
  return match == null ? null : match.group(1) == 'true';
}

bool? _readConstBool(String content, String key) {
  final match = RegExp(
    'static const bool $key = (true|false);',
  ).firstMatch(content);
  return match == null ? null : match.group(1) == 'true';
}

bool _isValidBundleId(String value) {
  return RegExp(
    r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$',
  ).hasMatch(value);
}

Future<void> _runRenameFlow(AppInitConfig config) async {
  stdout.writeln('rename 패키지 활성화 중...');
  final activate = await Process.run('dart', [
    'pub',
    'global',
    'activate',
    'rename',
  ]);
  if (activate.exitCode != 0) {
    stderr.writeln(activate.stderr);
    throw ProcessException(
      'dart',
      ['pub', 'global', 'activate', 'rename'],
      'rename 패키지 활성화 실패',
      activate.exitCode,
    );
  }

  stdout.writeln('앱 이름 변경 중...');
  final renameApp = await Process.run('dart', [
    'pub',
    'global',
    'run',
    'rename',
    'setAppName',
    '--targets',
    'ios,android',
    '--value',
    config.appName,
  ]);
  if (renameApp.exitCode != 0) {
    stderr.writeln(renameApp.stderr);
    throw ProcessException(
      'dart',
      ['pub', 'global', 'run', 'rename', 'setAppName'],
      '앱 이름 변경 실패',
      renameApp.exitCode,
    );
  }

  stdout.writeln('Bundle/Application ID 변경 중...');
  final renameBundle = await Process.run('dart', [
    'pub',
    'global',
    'run',
    'rename',
    'setBundleId',
    '--targets',
    'ios,android',
    '--value',
    config.bundleId,
  ]);
  if (renameBundle.exitCode != 0) {
    stderr.writeln(renameBundle.stderr);
    throw ProcessException(
      'dart',
      ['pub', 'global', 'run', 'rename', 'setBundleId'],
      'Bundle ID 변경 실패',
      renameBundle.exitCode,
    );
  }
}

void _updateManifest(File file, AppInitConfig config) {
  var content = file.readAsStringSync();

  content = _replaceQuotedYamlValue(content, 'name', config.appName);
  content = _replaceQuotedYamlValue(content, 'bundle_id', config.bundleId);
  content = _replaceQuotedYamlValue(content, 'application_id', config.bundleId);
  content = _replaceBoolYamlValue(content, 'google_auth', config.googleAuth);
  content = _replaceBoolYamlValue(content, 'google_drive', config.googleDrive);
  content = _replaceBoolYamlValue(content, 'gemini', config.gemini);
  content = _replaceBoolYamlValue(content, 'drift_db', config.driftDb);
  content = _replaceBoolYamlValue(content, 'dio_network', config.dioNetwork);
  content = _replaceBoolYamlValue(content, 'demo_mode', config.demoMode);

  file.writeAsStringSync(content);
}

void _updateAppFeatures(File file, AppInitConfig config) {
  var content = file.readAsStringSync();

  content = _replaceConstBool(content, 'googleAuth', config.googleAuth);
  content = _replaceConstBool(content, 'googleDrive', config.googleDrive);
  content = _replaceConstBool(content, 'gemini', config.gemini);
  content = _replaceConstBool(content, 'driftDb', config.driftDb);
  content = _replaceConstBool(content, 'dioNetwork', config.dioNetwork);

  file.writeAsStringSync(content);
}

String _replaceQuotedYamlValue(String content, String key, String value) {
  return content.replaceFirst(
    RegExp('(^\\s*$key:\\s*)"([^"]*)"', multiLine: true),
    '\$1"$value"',
  );
}

String _replaceBoolYamlValue(String content, String key, bool value) {
  return content.replaceFirst(
    RegExp('(^\\s*$key:\\s*)(true|false)', multiLine: true),
    '\$1$value',
  );
}

String _replaceConstBool(String content, String key, bool value) {
  return content.replaceFirst(
    RegExp('static const bool $key = (true|false);'),
    'static const bool $key = $value;',
  );
}

void _printSummary(AppInitConfig config, {required bool dryRun}) {
  stdout.writeln('');
  stdout.writeln('- app name set: ${config.appName}');
  stdout.writeln('- bundle id set: ${config.bundleId}');
  stdout.writeln('- feature flags updated: ${dryRun ? 'dry-run only' : 'yes'}');
  stdout.writeln('- manifest updated: ${dryRun ? 'dry-run only' : 'yes'}');
  stdout.writeln('- rename flow: ${dryRun ? 'skipped (dry-run)' : 'done'}');
  stdout.writeln('- demoMode: 현재 템플릿 코드에는 없어서 manifest metadata로만 기록됩니다.');
  stdout.writeln('');
  stdout.writeln('## Next manual steps');
  stdout.writeln('- replace app icon');
  stdout.writeln('- configure secrets');
  stdout.writeln('- verify OAuth settings');
  stdout.writeln('- check ios/ExportOptions.plist');
  stdout.writeln('- run flutter analyze');
  stdout.writeln('- run build verification');
}
