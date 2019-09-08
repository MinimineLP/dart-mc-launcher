import 'dart:convert';
import 'dart:io';

import 'package:gson/gson.dart';
import 'package:gson/parsable.dart';

class PropertiesParser {
  static RegExp _KEY_CHARACTERS = new RegExp(r"[\w-\.]");
  static RegExp _IGNORED = new RegExp(r"[ \t]");
  static RegExp _IGNORED2 = new RegExp(r"[ \t\r\n]");
  static RegExp _PURE_STRING = new RegExp(r"[^\n\r]");

  /// gson decoder (if you want to use it use the instance from gson.decoder)
  PropertiesParser();

  /// Insert gson to decode
  Properties decode(dynamic properties) {
    return decodeMap(properties);
  }

  /// Decode a map
  Properties decodeMap(dynamic src) {
    GsonParsable p = src is GsonParsable
        ? src
        : src is String
            ? new GsonParsable(src)
            : throw ("The src is not a valid input to decode an Array from");

    Properties map = new Properties([]);
    int lastpos = -1;

    while (p.hasNext()) {

      if(p.position == lastpos) {
        throw p.error("Ooups, nothing is happening");
      }

      lastpos = p.position;

      map.contents.addAll(parseIgnoredIncludingComments(p));
      String key = "";

      if (p.actual() == "\"" || p.actual() == "'") {
        key = decodeString(src).toString();
      } else {
        while (_KEY_CHARACTERS.hasMatch(p.actual())) {
          key += p.actual();
          if(p.hasNext()) {
            p.skip();
          }
          else {
            break;
          }
        }
      }

      if(key == "") {
        throw p.error('Key must not be ""');
      }

      _skipIgnored(p);

      if (p.actual() != "=") {
        throw p.error('Expected "="');
      }

      p.skip();

      _skipIgnored(p);
      if (p.actual() == "\"" || p.actual() == "'" || _PURE_STRING.hasMatch(p.actual())) {

          dynamic value = decodeString(p);
          map.contents.add(new PropertiesEntry(key, value));

      } else if (p.actual() == "\r" || p.actual() == "\n") {

        map.contents.add(new PropertiesEntry(key, null));

      } else {
        throw p.error('Expected "\\"", "\\\'" or a number');
      }

      map.contents.addAll(parseIgnoredIncludingComments(p));
    }
    if (!p.ended) p.skip();
    return map;
  }

  /// Decode a String
  dynamic decodeString(dynamic src) {
    GsonParsable p = src is GsonParsable
        ? src
        : src is String
            ? new GsonParsable(src)
            : throw ("The src is not a valid input to decode an Array from");

    String str = '"';

    if (p.actual() == "\"" || p.actual() == "\'") {
      String search = p.next();
      while (p.actual() != search) {
        if (p.actual() == "\\") {
          str += p.next();
        } else if (p.actual() == "\"") {
          str += "\\" + p.next();
          continue;
        }
        str += p.next();
      }
      if (!p.ended) {
        p.skip();
      }
    } else if (_PURE_STRING.hasMatch(p.actual())) {
      while (_PURE_STRING.hasMatch(p.actual())) {
        if (p.actual() == "\\") {
          str += p.next();
        }
        str += p.actual();
        if(p.hasNext()) {
          p.skip();
        }
        else {
          break;
        }
      }
    } else {
      throw p.error(
          "String has to start with a \"\\\"\" or \"\\\'\" when it contains some characters");
    }
    str = json.decode(str + '"');
    return new RegExp(r'''^[ \t]*(true)[ \t]*$''').hasMatch(str) ? true : RegExp(r'''^[ \t]*(false)[ \t]*$''').hasMatch(str) ? false : num.tryParse(str) ?? str;
  }
  

  void _skipIgnored(GsonParsable p) {
    while (_IGNORED.hasMatch(p.actual()) && p.hasNext()) {
      p.skip();
    }
  }

  List<PropertiesComment> parseIgnoredIncludingComments(GsonParsable p) {
    List<PropertiesComment> comments = [];
    while (_IGNORED2.hasMatch(p.actual()) || p.actual() == "#" ) {
      if(p.actual() == "#") {
        String comment = "";
        while(p.actual() != "\n" && p.hasNext()) {
          comment += p.actual();
          if(p.hasNext()) {
            p.skip();
          }
          else {
            break;
          }
        }
        comments.add(new PropertiesComment(comment.substring(1)));
      }
      if(p.hasNext()) {
        p.skip();
      }
      else {break;
      }
    }
    return comments;
  }
}

class Properties {

  static PropertiesParser parser = new PropertiesParser();

  List<PropertiesContent> contents;
  
  Properties(this.contents);

  static Properties parse(String properties) {
    return parser.decode(properties);
  }
  static Properties decode(String properties) {
    return parser.decode(properties);
  }

  @override
  String toString() {
    String ret = "";
    contents.forEach((e) {
      ret += "\n" + e.toString();
    });
    return ret.substring(1);
  }

  Map<String,dynamic> toMap() {
    Map<String,dynamic> ret = {};
    contents.forEach((e) {
      if(e is PropertiesEntry) {
        ret[e.key] = e.value;
      }
    });
    return ret;
  }

  PropertiesTemplate toTemplate() {
    return new PropertiesTemplate.fromProperties(this);
  }

  Future<File> saveToFile(String file) {
    return File(file).writeAsString(this.toString());
  }

  void saveToFileSync(String file) {
    File(file).writeAsStringSync(this.toString());
  }
}

class PropertiesTemplate {

  List<PropertiesTemplateContent> contents = [];
  PropertiesTemplate(this.contents);

  PropertiesTemplate.fromProperties(Properties p) {
    p.contents.forEach((e) {
      if(e is PropertiesComment) {
        this.contents.add(e);
      }
      if(e is PropertiesEntry) {
        this.contents.add(PropertiesTemplateEntry(e.key));
      }
    });
  }

  @override
  String toString() {
    String ret = "";
    contents.forEach((e) {
      ret += "\n" + e.toString();
    });
    return ret.substring(1);
  }

  Properties create(Map<String,dynamic> values,{bool addNonExisting = true}) {
    Properties properties = new Properties([]);
    List<String> added = [];
    this.contents.forEach((e) {
      if(e is PropertiesComment) {
        properties.contents.add(e);
      }
      else if(e is PropertiesTemplateEntry) {
        properties.contents.add(new PropertiesEntry(e.key, values[e.key]));
        added.add(e.key);
      }
    });

    if(addNonExisting) {
      values.forEach((k,v) {
        properties.contents.add(new PropertiesEntry(k, v));
      });
    }

    return properties;
  }
}

abstract class PropertiesContent {
  @override
  String toString();
}

abstract class PropertiesTemplateContent {
  @override
  String toString();
}

class PropertiesEntry implements PropertiesContent {

  String key;
  dynamic value;

  PropertiesEntry(this.key,this.value);

  @override
  String toString() {
    return key + "=" + (value != null ? (value is num ? value.toString() : value.toString().replaceAll(":", "\\:").replaceAll("=", "\\=").replaceAll(":", "\\:").replaceAll("\"", "\\\"").replaceAll("\"", "\\\'")) : "");
  }
}

class PropertiesComment implements PropertiesContent, PropertiesTemplateContent {
  String comment;
  PropertiesComment(this.comment);

  @override
  String toString() {
    return "#" + comment;
  }
}

class PropertiesTemplateEntry implements PropertiesTemplateContent {

  String key;

  PropertiesTemplateEntry(this.key);

  PropertiesEntry generateEntry(dynamic value, {bool controlValueType}) {
    return new PropertiesEntry(key, value);
  }

  @override
  String toString() {
    return key + "=(unset)";
  }
}