library test.content_shell;

import 'package:logging/logging.dart' show Logger;
import "dart:io";
import "dart:convert";
import 'Config.dart';
import 'global_config.dart';
import 'dart:async';
import 'pub_serve_service.dart';

class ContentShellService {
  static final Logger _log = new Logger('ContentShellService');
  static final Map _config = new Config().getMap("content_shell");
  final PubServeService pub;
  Process _process;
  StreamController<int> _onDone = new StreamController.broadcast();
  Future<int> get onDone =>_onDone.stream.first;
  StringBuffer _resultLog = new StringBuffer();


  ContentShellService(PubServeService this.pub) {
  }

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
    _log.info("Waiting pub build");
    return pub.onBuildResult.first.then((_) {
      _log.info("pub build");
      List<String> params = ["--dump-render-tree"];

      List<String> options = _config["options"];
      if (options != null && options.isNotEmpty) {
        params.addAll(options);
      }

      String target = _config["target"];
      if (target != null && target.isNotEmpty) {
        params.add(target);
      }
      String exec = "${_config["cs_path"]+Platform.pathSeparator+'content_shell'}";
      _initResultLog();
      return Process.start(exec, params, workingDirectory: GlobalConfig.APPLICATION_PATH, includeParentEnvironment: true, runInShell: false).then((process) {
        process.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
          _log.finest("[${process.pid}]:$line");
          _resultLog.writeln(line);
        });
        process.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
          _log.severe("[${process.pid}]:$line");
        });
        _log.info('content_shell[${process.pid}] start');
        _process = process;
        process.exitCode.then((exitCode) {
          _log.info('content_shell[${process.pid}] exit code: $exitCode'); // Prints 'exit code: 0'.
          _process = null;
          _saveTestLog().then((_){
            _onDone.add(_analyzeTestLog(exitCode));            
          });
        });
      });
    });
  }
  
  void _initResultLog() {
    _resultLog.writeln("Date: ${new DateTime.now().toIso8601String()}");
  }

  Future _saveTestLog(){
    return new File("test.log").writeAsString(_resultLog.toString()).then((file){
      _log.info("Result saved to: ${file.absolute.path}");
    });
  }
  
  int _analyzeTestLog(int exitCode) {
    if (exitCode ==0){
      if (_resultLog.toString().indexOf("FAIL")!=-1){
        _log.severe("Tests FAIL");
        return -1;
      }
    }else{
      _log.severe("content_shell return $exitCode, tests FAIL");
    }
    return exitCode;
  }
}
