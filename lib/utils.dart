import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<Directory> createDirIfNotExists(path,{bool temporary = false, bool recursive = true}) {
  var completer = new Completer<Directory>();

  Directory directory = new Directory(path);
  directory.exists().then((bool exists) {
    if(exists) { completer.complete(directory); }
    else if (temporary) {
      directory.createTemp().then((Directory directory) {
        completer.complete(directory);
      });
    }
    else {
      directory.create(recursive: recursive).then((Directory directory) {
        completer.complete(directory);
      });
    }
  });

  return completer.future;
}


Future<String> readLine() {
  Completer<String> c = new Completer<String>();
  stdin
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(c.complete);
  return c.future;
}

Future<String> downloadFile(String uri, String file) {
  Completer<String> c = new Completer<String>();
  new HttpClient().getUrl(Uri.parse(uri))
    .then((HttpClientRequest request) => request.close())
    .then((HttpClientResponse response) {
      response.pipe(new File(file).openWrite()).then((a) {
        c.complete(file);
      });
    });
  return c.future;
}

String resolvePath(String path) {
  File f = File(path);
  if(!f.isAbsolute) {
    path = f.absolute.path;
  }

  path = path.replaceAll("\\", "/").replaceAll("/./", "/");

  if(Platform.isWindows) {
    path = path.replaceAll("/", "\\");
  }

  return path;
}

Map concatMaps(List<Map> objects) {
  if(objects.length == 0) return null;
  if(objects.length == 1) return objects[0];
  Map o = objects[0];
  for(int i = 1; i < objects.length; i++) {
    objects[i].forEach((k, v) {
      if(o.containsKey(k)) {
        if(o[k] is Map && v is Map) o[k] = concatMaps([o[k],v]);
        if(o[k] is List && v is List) o[k] = concatLists([o[k],v]);
      } else {
        o[k] = v;
      }
    });
  }
  return o;
}

List concatLists(List<List> objects) {
  if(objects.length == 0) return null;
  if(objects.length == 1) return objects[0];
  List o = objects[0];
  for(int i = 1; i < objects.length; i++) {
    for(int c = 0; c < objects[i].length; c++) {
      if(o.length > c) {
        if(o[c] is Map && objects[i][c] is Map) o[c] = concatMaps([o[c],objects[i][c]]);
        if(o[c] is List && objects[i][c] is List) o[c] = concatLists([o[c],objects[i][c]]);
      } else {
        o[c].add(objects[i][c]);
      }
    };
  }
  return o;
}

class Version {
  int part1;
  int part2;
  int part3;
  int part4;
  
  String versionString;

  bool alpha = false;
  bool beta = false;
  bool snapshot = false;
  bool release = false;
  

  Version({
    this.part1,
    this.part2,
    this.part3,
    this.part4,
    this.alpha = false,
    this.beta = false,
    this.snapshot = false,
    this.release = false,
    this.versionString
  });
  
  

  Version.parse(this.versionString) {
    if(this.versionString.contains("alpha")) { this.alpha = true; }
    if(this.versionString.contains("beta")) { this.beta = true; }
    if(this.versionString.contains("snapshot")) { this.snapshot = true; }
    else { this.release = true; }
    List<String> verid = versionString.substring(versionString.indexOf(new RegExp(r'''[0-9]''')), versionString.lastIndexOf(new RegExp(r'''[0-9]'''))).split(".");
    part1 = verid.length > 0 ? num.tryParse(verid[0]) : null;
    part2 = verid.length > 1 ? num.tryParse(verid[1]) : null;
    part3 = verid.length > 2 ? num.tryParse(verid[2]) : null;
    part4 = verid.length > 3 ? num.tryParse(verid[3]) : null;
  }

  operator == (dynamic version) {
    if(version is String) { return version == this.toString(); }
    if(version is Version) {
      return version.toString() == this.toString() || (
        this.part1 == version.part1 &&
        this.part2 == version.part2 &&
        this.part3 == version.part3 &&
        this.part4 == version.part4 &&
        this.alpha == version.alpha &&
        this.beta == version.beta &&
        this.snapshot == version.snapshot &&
        this.release == version.release
      );
    }

    return false;
  }

  operator > (dynamic version) {
    if(version is String) { version = version.parse(version); }
    if(version is Version) {
      return 
        part1 == null ? false : this.part1 > version.part1 ? true : this.part1 < version.part1 ? false :
        part2 == null ? false : this.part2 > version.part2 ? true : this.part2 < version.part2 ? false :
        part3 == null ? false : this.part3 > version.part3 ? true : this.part3 < version.part3 ? false :
        part4 == null ? false : this.part4 > version.part4 ? true : false;
    }

    return false;
  }

  operator < (dynamic version) {
    if(version is String) { version = version.parse(version); }
    if(version is Version) {
      return 
        part1 == null ? false : this.part1 < version.part1 ? true : this.part1 > version.part1 ? false :
        part2 == null ? false : this.part2 < version.part2 ? true : this.part2 > version.part2 ? false :
        part3 == null ? false : this.part3 < version.part3 ? true : this.part3 > version.part3 ? false :
        part4 == null ? false : this.part4 < version.part4 ? true : false;
    }

    return false;
  }

  operator >= (dynamic version) {
    return this > version || this == version;
  }

  operator <= (dynamic version) {
    return this < version || this == version;
  }

  @override
  String toString() {
    return this.versionString;
  }
  
}