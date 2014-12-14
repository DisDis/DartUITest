library config;

import 'dart:io';
import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import 'dart:convert';

class Config {
  static Config instance;
  final _log = new Logger("Config");
  Map _config;
  Config._internal() {
    File config = new File(Platform.script.resolve('.' + Platform.pathSeparator
        + 'resources' + Platform.pathSeparator + 'config.json').toFilePath());
    if (!config.existsSync()) {
      _log.config("Not found '${config.path}'");
      throw new Exception("Not found '${config.path}'");
    }
    _log.config("loading '${config.path}'...");
    String contents = config.readAsStringSync();
    _config = JSON.decoder.convert(contents);
    _log.config("config loaded");
  }

  Object get(String key) {
    return _config[key];
  }

  Map getMap(String key) {
    return _config[key];
  }

  factory Config() {
    if (instance == null) {
      instance = new Config._internal();
    }
    return instance;
  }
}
