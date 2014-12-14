library test;

import 'package:unittest/unittest.dart';
import 'dart:html';
import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';

createElement(String html) =>
  new Element.html(html, treeSanitizer: new NullTreeSanitizer());

class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(node) {}
}


main() {
  useHtmlConfiguration(true);
  initPolymer();
  Polymer.onReady.then((_){
  _tests();
  });
}

void _tests() {
  var _el, _container;
  setUp((){
    
  });
  group("Test main-app", (){
    setUp((){
      _container = createElement('<div></div>');
      _el = createElement('<main-app></main-app>');
  
      _container.append(_el);
      document.body.append(_container);
    });
  
    tearDown((){
      _container.remove();
    });
  
    group('main-app', (){
      setUp((){
        _el.input = '12345';
  
        var completer = new Completer();
        _el.async(completer.complete);
        return completer.future;
      });
  
      test('revert test', (){
        expect(_el.reversed, '54321'); // Doubled by <x-double>
      });
      
      test('error test',(){
        expect("12","34"); // Error
        //expect("12","12"); // Ok
      });
      // ...
    });
  
  });
}