library test.analyzer;

import 'package:logging/logging.dart' show Logger;
import "dart:io";
import 'Config.dart';
import 'global_config.dart';
import 'dart:async';
import "dart:convert";
import "package:path/path.dart" as path;

class DartAnalyzerService {
  static final Logger _log = new Logger('DartAnalyzer');
  static Map _config = new Config().getMap("analyzer");
  bool isAllOk = false;
  StringBuffer _resultLog = new StringBuffer();
  Process _process;
  Future stop() {
    _log.info("stop");
    if (_process != null) {
      if (_process.kill(ProcessSignal.SIGINT)) {
        return _process.exitCode.timeout(new Duration(seconds: 2));
      }
    }
    return new Future.value(null);
  }
  
  void _initResultLog() {
     _resultLog.writeln("Date: ${new DateTime.now().toIso8601String()}");
   }

   Future _saveTestLog(){
     return new File("analyzer.log").writeAsString(_resultLog.toString()).then((file){
       _log.info("Result saved to: ${file.absolute.path}");
     });
   }
  Future start() {
    _log.info("start");
    _initResultLog();
    
    List<String> params = [];
    List<String> dirs = _config["directories"];
    dirs.forEach((dir){
    var files = new Directory(  path.join(GlobalConfig.APPLICATION_PATH,dir)).listSync()
        .where((item)=>
            item is File && item.existsSync() &&
            path.extension(item.path)=='.dart'
            )
    .map((item)=>item.path).toList(growable: false);
      params.addAll(files);
    });
    
    return Process.start("${GlobalConfig.DART_SDK_BIN_PATH+Platform.pathSeparator+'dartanalyzer'}", params, workingDirectory: GlobalConfig.APPLICATION_PATH, includeParentEnvironment: true, runInShell: false).then((process) {
      process.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
        _log.finest("analyzer[${process.pid}]:$line");
        _resultLog.writeln(line);
        if (line == "No issues found"){
          isAllOk = true;
        }
      });
      process.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen((line) {
        _log.severe("analyzer[${process.pid}]:$line");
      });
      _log.info('analyzer[${process.pid}] start');
      _process = process;
      process.exitCode.then((exitCode) {
        _log.info('analyzer[${process.pid}] exit code: $exitCode'); // Prints 'exit code: 0'.
        _saveTestLog();
        if (isAllOk){
          _log.info("Code OK");
        } else{
          _log.severe("Please fix code!");
        }
        _process = null;
      });

    });
  }
}
