library global.config;

import 'package:logging/logging.dart' show Logger;
import "Config.dart";
import "dart:io";
import "package:path/path.dart" as path;

class GlobalConfig {
  static final Logger _log = new Logger('GConfig');
  static Map _config = new Config().getMap("override");
  static String _DART_SDK_PATH;
  static String get DART_SDK_BIN_PATH => _DART_SDK_PATH;
  static String _APPLICATION_PATH;
  static String get APPLICATION_PATH => _APPLICATION_PATH;
  static final String _ANALYZER_RUN_KEY = "analyzer";
  static bool _hasRunAnalyzer = true;
  static bool get hasRunAnalyzer => _hasRunAnalyzer;

  static init() {
    if (_config == null) {
      _config = {};
    }
    var dartFile = new File(Platform.executable);
    var sdkBin = new File(dartFile.resolveSymbolicLinksSync()).parent;
    _DART_SDK_PATH = sdkBin.path;
    _initApplicationPath();
    _hasRunAnalyzer = Platform.environment[_ANALYZER_RUN_KEY] != "false";
    if (_config.containsKey(_ANALYZER_RUN_KEY)) {
      _hasRunAnalyzer = _config[_ANALYZER_RUN_KEY] != false;
    }
  }

  static void _initApplicationPath() {
    var tmp = Directory.current.absolute;
    File app_yaml;
    do {
      app_yaml = new File(path.join(tmp.path, "pubspec.yaml"));
      var tmp2 = tmp.parent;

      if (tmp == tmp2) {
        throw new Exception("Application not found");
      }
      tmp = tmp2;
    } while (!app_yaml.existsSync());
    _APPLICATION_PATH = app_yaml.parent.path;
  }

  static void outputToLog() {
    _log.info("DART_SDK_BIN_PATH: ${DART_SDK_BIN_PATH}");
    _log.info("APPLICATION_PATH: ${APPLICATION_PATH}");
    _log.info("Run analyzer: ${hasRunAnalyzer}");
  }
}
