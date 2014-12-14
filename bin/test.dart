import 'package:logging/logging.dart' show Logger, Level, LogRecord;
import "dart:io";
import 'Config.dart';
import 'global_config.dart';
import 'dart:async';
import 'dartanalyzer_service.dart';
import 'pub_serve_service.dart';
import 'content_shell_service.dart';

_configureLogger() {
  var config = new Config();
  try {
    String levelStr = config.get("Log")["Level"];

    if (!Level.LEVELS.any((level) {
      if (level.name == levelStr) {
        Logger.root.level = level;
        return true;
      }
      return false;
    })) {
      Logger.root.config("Unknown value Log->Level : $levelStr");
    }
  } catch (e) {
    Logger.root.config(e.toString());
  }
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    var msg = '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}';
    print(msg);
    //stdout.writeln(msg);
  });
  _configureLogger();
  runZoned(() {
    var app = new Application();
    ProcessSignal.SIGINT.watch().listen((_) {
      app.stop();
    });
    app.start();
  }, onError: () {
    return stdout.flush().then((_) {
      exit(-1);
    });
  });
}


class Application {
  static final Logger _log = new Logger('Application');
  static final VERSION = "0.1 2014-12-13";
  static final DateTime START_DATETIME = new DateTime.now();

  DartAnalyzerService _analyzer;
  PubServeService _pub;
  ContentShellService _contentShell;

  void start() {
    _log.info("");
    _log.info("---== Starting Application v$VERSION ==---");
    _log.info("      Date: ${START_DATETIME}");
    GlobalConfig.init();
    _showEnvironment();
    _showConfig();
    if (GlobalConfig.hasRunAnalyzer) {
      _runAnalyzer();
    }
    _runPubServe();
    _runContentShell();
  }

  void _runContentShell() {
    _contentShell = new ContentShellService(_pub)..start();
    _contentShell.onDone.then((exitCode) {
      stop(exitCode);
    });
  }

  void _runPubServe() {
    _pub = new PubServeService()..start();
  }

  void _runAnalyzer() {
    _analyzer = new DartAnalyzerService()..start();
  }

  void _showConfig() {
    _log.info("");
    _log.info("Config");
    GlobalConfig.outputToLog();
  }

  void _showEnvironment() {
    _log.info("");
    _log.info("Environment:");
    _log.info("Dart: ${Platform.version}");
    _log.info("Host: ${Platform.localHostname}, CPU: ${Platform.numberOfProcessors}, OS: ${Platform.operatingSystem}");
    _log.info("Current folder: ${Directory.current.path}");
  }

  void stop([int exitCode]) {
    _log.info("Stoping application");
    List<Future> futures = [];
    if (_contentShell != null) {
      futures.add(_contentShell.stop());
      _contentShell = null;
    }
    if (_analyzer != null) {
      futures.add(_analyzer.stop());
      _analyzer = null;
    }
    if (_pub != null) {
      futures.add(_pub.stop());
      _pub = null;
    }

    Future.wait(futures).then((_) {
      _log.info("Shutdown application");
      return stdout.flush().then((_) {
        if (exitCode is int) {
          exit(exitCode);
        } else {
          exit(0);
        }
      });
    }).timeout(new Duration(seconds: 5), onTimeout: () {
      Logger.root.info("Shutdown timeout");
      Logger.root.info("Shutdown force");
      return stdout.flush().then((_) {
        if (exitCode is int && exitCode != 0) {
          exit(exitCode);
        } else {
          exit(1);
        }
      });
    });
  }
}
