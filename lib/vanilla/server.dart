import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mc_launcher/java.dart';
import 'package:mc_launcher/minecraft/file_creator.dart';
import 'package:mc_launcher/minecraft/server.dart';
import 'package:mc_launcher/minecraft/server_properties.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:mc_launcher/properties_format.dart';
import 'package:mc_launcher/utils.dart';
import 'package:path/path.dart' as path;

class VanillaServer implements MinecraftServer {
  
  final String serverdir;
  final DartMcLauncherProperties properties;
  final ServerProperties server_properties;
  Process process;
  bool get running => _running;

  List<void Function(String)> onStdOut = [
    (data) { 
      stdout.write(data);
    }
  ];

  List<void Function(String)> onStdErr = [
    (data) { 
      stderr.write(data);
    }
  ];

  bool _running = false;

  VanillaServer._init(this.serverdir, this.properties, this.server_properties);
  
  static Future<VanillaServer> install(String serverdir, {String version, bool eula = false}) async {
  
    await createDirIfNotExists(serverdir);
  
    http.Response response = await http.get('https://launchermeta.mojang.com/mc/game/version_manifest.json');
    Map<String,dynamic> version_manifest = json.decode(response.body);
    if(version == null) version = version_manifest["latest"]["release"];
      
    _VersionInformations informations;
  
    for(Map<String,dynamic> value in version_manifest["versions"]) {
      if(value["id"] != version) continue;
      http.Response response = await http.get(value["url"]);
      Map<String,dynamic> versioninformation = json.decode(response.body);
      informations = _VersionInformations(id: value["id"],releaseTime: value["releaseTime"], time: value["time"], type: value["time"], url: value["url"], download: versioninformation["downloads"]["server"]["url"]);
      break;
    }
  
    DartMcLauncherVanillaProperties properties = new DartMcLauncherVanillaProperties(jar_file: "server.jar", maxram: 1024, minram: 512, minecraft_version: version, gui: false, file: "$serverdir/dart-mc-launcher.properties");
    ServerProperties serverProperties = new ServerProperties(file: '$serverdir/server.properties');
    List<Future> futures = [
      properties.save(),
      downloadFile(informations.download, '$serverdir/server.jar'),
      createEula(serverdir, eula),
      serverProperties.save()
    ];
    futures.addAll(create_start_files(serverdir, 'server.jar'));
  
    await Future.wait(futures);
    return VanillaServer._init(serverdir, properties, serverProperties);
  }
  
  static Future<VanillaServer> create(String serverdir, {String version, bool defaultEula = false}) async {
  
    DartMcLauncherVanillaProperties properties;
  
    if(!(await new Directory(serverdir).existsSync())
      || !(await new File(path.join(serverdir,"server.properties")).exists())) {
      return await install(serverdir, version: version, eula: defaultEula);
    } 
    else if(await new File(path.join(serverdir,"dart-mc-launcher.properties")).exists()) {
      properties = await DartMcLauncherVanillaProperties.loadFile(path.join(serverdir,"dart-mc-launcher.properties"));
    }
    else {
      throw("The server you are trying to load has no \"dart-mc-launcher.properties\" file, for that reason it can't be read by dart-mc-launcher. If you wanna create a new Server at this directory delete all contents, in other case you have to create a file manually");
    }
  
    return new VanillaServer._init(serverdir, properties, await ServerProperties.loadFile(path.join(serverdir,"server.properties")));
  }

  @override
  Future<VanillaServer> start() async {
    if(this.running) throw("Server already running!");
    this._running = true;

    List<String> args = ["-Xms${properties.minram}", "-Xmx${properties.maxram}", "-jar",properties.jar_file];
    if(!properties.gui) args.add("nogui");

    //print('$JAVA ' + args.join(" "));

    Completer<VanillaServer> completer = new Completer<VanillaServer>();

    this.process = await Process.start('$JAVA', args, workingDirectory: this.serverdir);

    process.stdout.transform(utf8.decoder).listen((data) { 
      this.onStdOut.forEach((e) {
        e(data);
      });
      if((!completer.isCompleted) && new RegExp(r'''Done \([1-9]+\.[1-9]+\w\)! For help, type "help"''').hasMatch(data)) {
        completer.complete(this);
      }
    });
    
    process.exitCode.then((v) {
      this._running = false;
      this.process = null;
    });

    process.stderr.transform(utf8.decoder).listen((data) { stderr.write(data); });

    return await completer.future;
  }

  @override
  Future<VanillaServer> stop() async {
    if(!this.running) throw("Server is not running!");
    executeCommand("stop");
    await process.exitCode;
    this._running = false;
    this.process = null;
    return this;
  }
  
  @override
  Future<VanillaServer> executeCommand(String cmd) async {
    if(!this.running) throw("Server is not running!");
    print("> $cmd");
    process.stdin.writeln(cmd);
    return this;
  }
}

class _VersionInformations {
  final String id;
  final String type;
  final String url;
  final String time;
  final String releaseTime;
  final String download;
  _VersionInformations({this.id,this.time, this.releaseTime,this.type,this.url,this.download});
}

class DartMcLauncherVanillaProperties implements DartMcLauncherProperties {
  PropertiesTemplate template = null;
  String minecraft_version;
  String jar_file;
  int minram;
  int maxram;
  bool gui = false;
  String file;

  DartMcLauncherVanillaProperties({
    @required this.minecraft_version,
    @required this.jar_file,
    @required this.maxram,
    @required this.minram,
    this.gui = false,

    /// The properies's file path
    @required this.file
  });

  DartMcLauncherVanillaProperties.loadMap(Map<String,dynamic> map) {
    this._loadMap(map);
  }

  DartMcLauncherVanillaProperties.loadProperties(Properties properties, this.file) {
    this._loadMap(properties.toMap());
    this.template = properties.toTemplate();
  }

  DartMcLauncherVanillaProperties.loadFile(String file): this.loadProperties(Properties.decode(File(file).readAsStringSync()), file);

  void _loadMap(Map<String,dynamic> map) {
      if(map["type"] != "vanilla") throw("Loading non-vanilla configuration with vanilla, type is \"${map["type"]}\"");
      this.minecraft_version = map["minecraft-version"];
      this.jar_file = map["jar-file"];
      this.minram = map["min-ram"];
      this.maxram = map["max-ram"];
      this.gui = map["gui"];
  }

  @override
  Map<String,dynamic> toMap() {
    return {
      "type": "vanilla",
      "minecraft-version": minecraft_version,
      "jar-file": jar_file,
      "min-ram": minram,
      "max-ram": maxram,
      "gui": gui,
    };
  }

  @override
  Properties toProperties() {
    return (template ?? new PropertiesTemplate([])).create(toMap());
  }

  @override
  Future<File> saveToFile(String file) {
    return toProperties().saveToFile(file);
  }

  @override
  void saveToFileSync(String file) {
    toProperties().saveToFileSync(file);
  }

  @override
  Future<File> save() {
    return saveToFile(file);
  }

  @override
  void saveSync() {
    saveToFileSync(file);
  }

  @override
  String toString() {
    return toProperties().toString();
  }
}