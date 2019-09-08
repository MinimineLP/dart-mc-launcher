import 'dart:async';

import 'package:console/console.dart';


class AdvancedProgressBar {

  int max = 100;
  int value = 0;
  int percentage_decimal_places = 2;
  String actual;
  DateTime started;
  Timer timer;
  int startline;

  AdvancedProgressBar({this.max = 100, this.value = 0,this.percentage_decimal_places = 2, this.started, this.actual}) {
    if(max == 0) return;
    if(this.started == null) this.started = DateTime.now();
    this.timer = new Timer.periodic(Duration(milliseconds: 125), (timer) {
      this.render();
    });
    Console.hideCursor();
  }

  void update({int value, int max, String actual}) {

    if ((value == this.value || value == null) && (max == this.max || max == null) && (actual == this.actual || actual == null)) {
      return;
    }

    this.max = max ?? this.max;
    this.value = value ?? this.value;
    this.actual = actual ?? this.actual;
    
    this.render();
  }

  AdvancedProgressBar render() {
    if(this.max == 0) return this;

    Duration difference = DateTime.now().difference(this.started);
    int x = int.parse((difference.inMilliseconds / 1000).toString().split(".")[1]);

    String percent = ((this.value / this.max) * 100).toStringAsFixed(2) + "%";

    if(percentage_decimal_places < 1) while(percent.length < 4) percent = " " + percent;
    else while(percent.length < 5 + percentage_decimal_places) percent = " " + percent;

    int m = 10;
    int symbols = ((this.value / this.max) * m).toInt();

    var out = StringBuffer("[");

    for (int x = 0; x < symbols; x++) out.write("=");

    out.write(">");

    for (int x = symbols; x < m; x++) out.write(" ");
    out.write("] ${(x < 250 ? "-" : x < 500 ? "\\" : x < 750 ? "|" : "/")} $percent ${(difference.inSeconds + 1).toString()} seconds ${this.actual != null && this.actual != "" ? this.actual : ""}");

    Console.overwriteLine(out.toString());

    return this;
  }

  AdvancedProgressBar kill() {
    Console.write(" - ready\n");
    if(this.timer != null) this.timer.cancel();
    Console.showCursor();
    return this;
  }
}