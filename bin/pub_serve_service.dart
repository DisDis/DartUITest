library test.pub;

import 'package:logging/logging.dart' show Logger;
import "dart:io";
import "dart:convert";
import 'Config.dart';
import 'global_config.dart';
import 'dart:async';

class PubServeService {
  static final Logger _log = new Logger('PubServe');
  static final Map _config = new Config().getMap("pub");
  Process _process;
  StreamController<bool> _onBuildResult = new StreamController.broadcast();
  Stream<bool> get onBuildResult => _onBuildResult.stream;
  static final String buildSuccessfullyLine = 'Build completed successfully';
  Future stop() {
    _log.info("stop");
    if (_process != null) {
      if (_process.kill(ProcessSignal.SIGINT)) {
        return _process.exitCode.timeout(new Duration(seconds: 2));
      }
    }
    return new Future.value(null);
  }
  Future start() {
    _log.info("start");
    List<String> params = ["serve"];
    List<String> directories = _config["directories"];
    if (directories != null && directories.isNotEmpty) {
      params.addAll(directories);
    }
    int port = _config["port"];
    if (port != null) {
      params
          ..add("--port")
          ..add("$port");
    }
    String hostname = _config["hostname"];
    if (port != null) {
      params
          ..add("--hostname")
          ..add("$hostname");
    }
    List<String> options = _config["options"];
    if (options != null && options.isNotEmpty) {
      params.addAll(options);
    }

    return Process.start("${GlobalConfig.DART_SDK_BIN_PATH+Platform.pathSeparator+'pub'}", params, workingDirectory: GlobalConfig.APPLICATION_PATH, includeParentEnvironment: true, runInShell: false).then((process) {
      process.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
        _log.finest("pub[${process.pid}]:$line");
        if (line == buildSuccessfullyLine){
          _log.info("pub[${process.pid}] - build targets");
          _onBuildResult.add(true);
        }
      });
      process.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
        _log.severe("pub[${process.pid}]:$line");
      });
      _log.info('pub[${process.pid}] start');
      _process = process;
      process.exitCode.then((exitCode) {
        _log.info('pub[${process.pid}] exit code: $exitCode'); // Prints 'exit code: 0'.
        _process = null;
      });
    });
  }
}
