import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:mc_launcher/console.dart';
import 'package:mc_launcher/minecraft/authorization.dart';
import 'package:mc_launcher/utils.dart';
import 'package:merge_map/merge_map.dart';
import 'package:path/path.dart' as path;


abstract class MinecraftClient {

  String get rootDir;
  MinecraftClientPreparer get handler;
  String get version;
  int get maxRam;
  int get minRam;
  Authorization get auth;
  bool get running;

  Process get process;

  Future<MinecraftClient> start();
  void kill();
}

class MinecraftClientPreparer {

  String root;

  Map<String,dynamic> version_manifest;
  Map<String,dynamic> version;
  String version_name;

  MinecraftClientPreparer parent;

  MinecraftClientPreparer(this.root);

  Future<MinecraftClientPreparer> setup(String version) async {
    this.version_name = version;
    http.Response response = await http.get('https://launchermeta.mojang.com/mc/game/version_manifest.json');
    this.version_manifest = json.decode(response.body);

    if(await File("$root/versions/$version/$version.json").exists()) {
      this.version = json.decode(await new File("$root/versions/$version/$version.json").readAsString());
    }

    else {
      for(Map<String,dynamic> value in version_manifest["versions"]) {
        if(value["id"] != version) continue;
        this.version = json.decode((await http.get(value["url"])).body);
        break;
      }
      if(this.version == null) throw("Version $version does not exist!");
    }

    if(this.version["inheritsFrom"] != null) {
      print("Version $version inerhits from version ${this.version["inheritsFrom"]}, needing to get this version first!");
      MinecraftClientPreparer preparer = await new MinecraftClientPreparer(root).install(this.version["inheritsFrom"]);
      this.parent = preparer;
      Map<String, dynamic> tmp = this.version;
      this.version = mergeMap([json.decode(json.encode(preparer.version)),tmp]);
      this.version["arguments"]["game"].addAll(preparer.version["arguments"]["game"]);
      this.version["libraries"].addAll(preparer.version["libraries"]);
      
    }
    
    return this;
  }

  Future<String> getJar() async {
    String dir = path.join(root,'versions/$version_name');
    await createDirIfNotExists(dir);
    if(!await File('$dir/$version_name.jar').exists()) await downloadFile(this.version["downloads"]["client"]["url"], '$dir/$version_name.jar');
    if(!await File('$dir/$version_name.json').exists()) await File('$dir/$version_name.json').writeAsString(JsonEncoder.withIndent('  ').convert(this.version));
    return resolvePath('$dir/$version_name.jar');
  }

  Future getAssets() async {

    String dir = path.join(root, 'assets', 'indexes').replaceAll("\\", "/");
    await createDirIfNotExists(dir);
    String assetIndex = path.join(dir, "${this.version["assetIndex"]["id"]}.json");

    if(!File(assetIndex).existsSync()) {
      await downloadFile(this.version["assetIndex"]["url"], path.join(root, 'assets', 'indexes', "${this.version["assetIndex"]["id"]}.json"));
    }

    Map<String,dynamic> index = json.decode(File(assetIndex).readAsStringSync());
    
    List<void Function()> funcs = [];
    List<Map<String,String>> infos = [];

    index["objects"].forEach((key, value) {
      String hash = value["hash"];
      String subhash = hash.substring(0,2);
      String assetDirectory = path.join(root, 'assets');
      String subAsset = path.join(assetDirectory, 'objects', subhash);
      if(!File(path.join(subAsset, hash)).existsSync()) {
        funcs.add(() async {
          await createDirIfNotExists(subAsset);
          await downloadFile('https://resources.download.minecraft.net/${subhash}/${hash}', path.join(subAsset,hash));
        });
        infos.add({"file": key, "hash": hash, "subhash": subhash});
      };
    });
    if(funcs.length > 0) {
      AdvancedProgressBar progress = AdvancedProgressBar(max: funcs.length, value: 0);
      progress.update(value: 0);

      for(int i=0;i<funcs.length;i++) {
        progress.update(actual: "| downloading asset asset: ${infos[i]["subhash"]}/${infos[i]["hash"]}: (${infos[i]["file"]})...");
        await funcs[i]();
        progress.update(value: i + 1);
      }

      progress.kill();
    }
  }

  Future<List<String>> getClasses() async {
    Map<String,String> libs = {};

    List<Function> tasks = [];
    List<Map<String,dynamic>> artifacts = [];
    Map<String,Version> libEntrys = {};

    for(int i = 0; i < this.version["libraries"].length; i++) {

      Map<String, dynamic> library = this.version["libraries"][i];

      String libraryPath = "", libraryUrl, libraryDirectory, lib;
      Version version;

      if(library["downloads"] == null) {
        libraryUrl = library["url"];
        List<String> pathParts = [];
        library["name"].split(":").forEach((e) {
          if(!new RegExp(r'''^(alpha|beta|release|snapshot)?[0-9]''', caseSensitive: false).hasMatch(e)) {
            e.split(".").forEach((e) {
              pathParts.add(e);
            });
          }
          else {
            pathParts.add(e);
          }
        });
        libraryPath = pathParts.join("/") + "/${pathParts[pathParts.length - 2]}-${pathParts[pathParts.length - 1]}.jar";
        libraryUrl += libraryPath;
        libraryDirectory = resolvePath(path.join(root, 'libraries', libraryPath).replaceAll("\\", "/"));

        lib = library["name"].substring(0, library["name"].lastIndexOf(":") - 1);

        libs[lib] = libraryDirectory;

      } else {

        lib = library["name"].substring(0, library["name"].lastIndexOf(":") - 1);
        version = Version.parse(library["name"].substring(library["name"].lastIndexOf(":") + 1));

        libraryPath = library["downloads"]["artifact"]["path"];
        libraryUrl = library["downloads"]["artifact"]["url"];
        libraryDirectory = resolvePath(path.join(root, 'libraries', libraryPath).replaceAll("\\", "/"));

        if(!libEntrys.containsKey(lib) || version > libEntrys[lib]) {
          libEntrys[lib] = version;
          libs[lib] = libraryDirectory;
        }
      }

      artifacts.add({"path": libraryPath, "url": libraryUrl});

      if(!await File(libraryDirectory).exists()) {
        tasks.add(() async {
          await createDirIfNotExists(libraryDirectory.substring(0,libraryDirectory.replaceAll("\\", "/").lastIndexOf("/")));
          await downloadFile(libraryUrl, libraryDirectory);
        });
      }
    }
    if(tasks.length > 0) {
      AdvancedProgressBar progress = AdvancedProgressBar(max: tasks.length);
      progress.update(value: 0);
      for(int i = 0; i < tasks.length; i++) {
        progress.update(actual: "| downloading library: ${artifacts[i]["url"]}");
        await tasks[i]();
        progress.update(value: i + 1);
      }

      progress.kill();
    }

    List<String> list = libs.values.toList();
    
    for(int i = 0; i < list.length; i++) {
      if(list[i].contains("lwjgl")) {
        list[i] = list[i].replaceAll("3.2.1", "3.2.2");
      }
    }

    return list;
  }
  
  Future<void> getNatives() async {
    String nativeDirectory = path.join(root, 'natives', this.version["id"]);

    if(!await File(nativeDirectory).exists()) {
      await createDirIfNotExists(nativeDirectory);
      List<Future Function()> funcs = [];
        
      this.version["libraries"].forEach((lib) {
        funcs.add(() async {
          
          if (lib["downloads"] == null || lib["downloads"]["classifiers"] == null ||this.parseRule(lib)) { return; }
          Map native = this.getOS() == 'osx'
              ? lib["downloads"]["classifiers"]['natives-osx'] || lib["downloads"]["classifiers"]['natives-macos']
              : lib["downloads"]["classifiers"]['natives-${this.getOS()}'];

          if (native != null) {
            String name = native["path"].substring(native["path"].lastIndexOf("/") + 1);
            await createDirIfNotExists(nativeDirectory);
            await downloadFile(native["url"], path.join(nativeDirectory,name));

            try {
              List<int> bytes = File(path.join(nativeDirectory, name)).readAsBytesSync();

              Archive archive = ZipDecoder().decodeBytes(bytes);

              for (ArchiveFile file in archive) {
                String filename = file.name;
                if (file.isFile) {
                  List<int> data = file.content;
                  File('$nativeDirectory/' + filename)
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(data);
                } else {
                  Directory('$nativeDirectory/' + filename)
                    ..create(recursive: true);
                }
              }
            } catch(e) {
            }
           await File(path.join(nativeDirectory, name)).delete();
          }
        });
      });
      for(Function f in funcs) {
        await f();
      }
    }
  }

  String getOS() {
    if(Platform.isWindows) {
      return "windows";
    }
    if(Platform.isLinux) {
      return "linux";
    }
    if(Platform.isMacOS) {
      return "osx";
    }
    if(Platform.isIOS) {
      return "ios";
    }
    if(Platform.isAndroid) {
      return "android";
     }
    if(Platform.isFuchsia) {
      return "fuchsia";
    }
    return null;
  }

  bool parseRule(Map<String,dynamic> lib) {
    if(lib["rules"] != null) {
      if (lib["rules"].length > 1) {
        if (lib["rules"][0]["action"] == 'allow' && lib["rules"][1]["action"] == 'disallow' && lib["rules"][1]["os"]["name"] == 'osx') {
          return this.getOS() == 'osx';
        } else {
          return true;
        }
      } else {
        if (lib["rules"][0]["action"] == 'allow' && lib["rules"][0]["os"] != null) return this.getOS() != 'osx';
      }
    }
    return false;
  }

  Future<MinecraftClientPreparer> install(String version) async {
    await this.setup(version);
    await this.getAssets();
    await this.getJar();
    await this.getClasses();
    await this.getNatives();
    return this;
  }
  

    List getLaunchOptions({@required Authorization auth, modification}) {
      Map type = modification ?? this.version;

      List args = type["minecraftArguments"] != null ? type["minecraftArguments"].split(' ') : type["arguments"]["game"];
      String assetRoot = path.join(this.root, 'assets');
      String assetPath = this.version["assets"] == "legacy" || this.version["assets"] == "pre-1.6" ? path.join(assetRoot, 'legacy') : assetRoot;

      int minArgs =  5;
      if(args.length < minArgs) args.addAll(type["minecraftArguments"] != null ? type["minecraftArguments"].split(' ') : type["arguments"]["game"]);

      Map<String,String> fields = {
        '\${auth_access_token}': auth.access_token, //this.options.authorization.access_token,
        '\${auth_session}': auth.access_token, //this.options.authorization.access_token,
        '\${auth_player_name}': auth.name, //this.options.authorization.name,
        '\${auth_uuid}': auth.uuid, //this.options.authorization.uuid,
        '\${user_properties}': auth.user_properties, //this.options.authorization.user_properties,
        '\${user_type}': 'mojang',
        '\${version_name}': this.version["id"],
        '\${assets_index_name}': this.version["assetIndex"]["id"],
        '\${game_directory}': resolvePath(root),
        '\${assets_root}':  resolvePath(assetPath),
        '\${game_assets}': resolvePath(assetPath),
        '\${version_type}': this.version["type"],
      };

      for (int index = 0; index < args.length; index++) {
        if (fields.keys.contains(args[index])) {
          args[index] = fields[args[index]];
        }
        else if(args[index] is Map) {
          args.removeAt(index);
          index--;
        }
        else if(args[index] == "") {
          args.removeAt(index);
          index--;
        }
      }
      return args;
      
    }

  String getJVM() {
   const opts = {
      "windows": "-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump",
      "osx": "-XstartOnFirstThread",
      "linux": "-Xss1M"
    };
    return opts[this.getOS()];
  }
}

class VersionInformations {
  final String id;
  final String type;
  final String url;
  final String time;
  final String releaseTime;
  final String download;
  VersionInformations({this.id,this.time, this.releaseTime,this.type,this.url,this.download});
}