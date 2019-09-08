import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mc_launcher/fabric/fabricutils.dart';
import 'package:mc_launcher/java.dart';
import 'package:mc_launcher/minecraft/file_creator.dart';
import 'package:mc_launcher/minecraft/minecraft.dart';
import 'package:mc_launcher/minecraft/server.dart';
import 'package:meta/meta.dart';
import 'package:mc_launcher/properties_format.dart';
import 'package:path/path.dart' as path;

class FabricManager {

  const FabricManager();

  Future<FabricServer> createServer(String serverdir) {
    return FabricServer.create(serverdir);
  }

  Future<FabricServer> installServer(serverdir, {String fabric_version, String minecraft_version, String installer_version, bool downloadMinecraft = true}) async {
    return FabricServer.install(serverdir, fabric_version: fabric_version, minecraft_version: minecraft_version, installer_version: installer_version, downloadMinecraft: downloadMinecraft);
  }

}

class FabricServer implements MinecraftServer {
  String serverdir;

  DartMcLauncherFabricProperties properties;

  bool _running = false;
  Process process;
  ServerProperties server_properties;

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

  /// Is the server running at the moment?
  bool get running => _running;

  FabricServer._init(this.serverdir, this.properties, this.server_properties) {
    _running = false;
  }

  static Future<FabricServer> create(String serverdir, {String fabric_version, String minecraft_version, bool defaultEula = false}) async {

    DartMcLauncherFabricProperties properties;

    if(!(await new Directory(serverdir).existsSync())
      || !(await new File(path.join(serverdir,"server.properties")).exists())) {
      return await install(serverdir, fabric_version: fabric_version, minecraft_version: minecraft_version, eula: defaultEula);
    } 
    else if(await new File(path.join(serverdir,"dart-mc-launcher.properties")).exists()) {
      properties = await DartMcLauncherFabricProperties.loadFile(path.join(serverdir,"dart-mc-launcher.properties"));
    }
    else {
      throw("The server you are trying to load has no \"dart-mc-launcher.properties\" file, for that reason it can't be read by dart-mc-launcher. If you wanna create a new Server at this directory delete all contents, in other case you have to create a file manually");
    }

    return new FabricServer._init(serverdir, properties, await ServerProperties.loadFile(path.join(serverdir,"server.properties")));
  }

  /// Install a fabric server instance
  static Future<FabricServer> install(String serverdir, {String fabric_version, String minecraft_version, String installer_version, bool downloadMinecraft = true, bool eula = false}) async {
    String jarfile = await downloadInstaller(serverdir, installer_version: installer_version);
    List<String> args = ["-jar", jarfile, "server", "-dir", serverdir];

    if(downloadMinecraft) args.add("-downloadMinecraft");
    if(minecraft_version != null) args.addAll(["-version", minecraft_version]);
    if(fabric_version != null) args.addAll(["-loader", fabric_version]);

    Completer installerFinished = new Completer<String>();
    Process.start(JAVA, args).then((Process process) {
      process.stdout
          .transform(utf8.decoder)
          .listen((data) { 
            stdout.write(data); 
          });
      process.exitCode.then((code) {
        new Directory("$serverdir/tmp").delete(recursive: true);
        installerFinished.complete();
      });
    }).catchError((e) {print(e);});

    ServerProperties server_properties = new ServerProperties(file: "$serverdir/server.properties");

    List<Future> futures = [
      installerFinished.future,
      server_properties.save(),
      createEula(serverdir,eula),
    ];

    futures.addAll(create_start_files(serverdir, "fabric-server-launch.jar"));

    if(fabric_version == null || minecraft_version == null) {

      Completer helpFinished = new Completer<String>();

      Process.run(JAVA, ["-jar", jarfile, "help"]).then((ProcessResult process) {
        List<String> out = process.stdout.toString().split("\n");
        if(minecraft_version == null) {
          minecraft_version = out[out.length-3].substring(out[out.length-3].indexOf(RegExp(r'''[0-9]''')));
        }
        if(fabric_version == null) {
          fabric_version = out[out.length-2].substring(out[out.length-2].indexOf(RegExp(r'''[0-9]''')));
        }
        helpFinished.complete();
      }).catchError((e) {print(e);});
      
      futures.add(helpFinished.future);
    }

    DartMcLauncherFabricProperties properties = new DartMcLauncherFabricProperties(
      minecraft_version: minecraft_version,
      fabric_version: fabric_version,
      jar_file: "fabric-server-launch.jar",
      minram: 512,
      maxram: 1024,
      gui: false,
      file: path.join(serverdir,"dart-mc-launcher.properties")
    );

    futures.add(properties.save());
    await Future.wait(futures);

    return new FabricServer._init(serverdir, properties, server_properties);
  }

  @override
  Future<FabricServer> start() async {
    if(this.running) throw("Server already running!");
    this._running = true;

    List<String> args = ["-Xms${properties.minram}", "-Xmx${properties.maxram}", "-jar",properties.jar_file];
    if(!properties.gui) args.add("nogui");

    //print('$JAVA ' + args.join(" "));

    Completer<FabricServer> completer = new Completer<FabricServer>();

    this.process = await Process.start(JAVA, args, workingDirectory: this.serverdir);

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
  Future<FabricServer> stop() async {
    executeCommand("stop");
    await process.exitCode;
    this._running = false;
    return this;
  }
  
  @override
  Future<FabricServer> executeCommand(String cmd) async {
    print("> $cmd");
    process.stdin.writeln(cmd);
    return this;
  }
}

class DartMcLauncherFabricProperties extends DartMcLauncherProperties {
  PropertiesTemplate template = null;
  String fabric_version;
  String minecraft_version;
  String jar_file;
  int minram;
  int maxram;
  bool gui = false;
  String file;

  DartMcLauncherFabricProperties({
    @required this.fabric_version,
    @required this.minecraft_version,
    @required this.jar_file,
    @required this.maxram,
    @required this.minram,
    this.gui = false,
    @required this.file
  });

  DartMcLauncherFabricProperties.loadMap(Map<String,dynamic> map) {
    this._loadMap(map);
  }

  DartMcLauncherFabricProperties.loadProperties(Properties properties, this.file) {
    this._loadMap(properties.toMap());
    this.template = properties.toTemplate();
  }

  DartMcLauncherFabricProperties.loadFile(String file): this.loadProperties(Properties.decode(File(file).readAsStringSync()), file);

  void _loadMap(Map<String,dynamic> map) {
      if(map["type"] != "fabric") throw("Loading non-fabric configuration with fabric, type is \"${map["type"]}\"");
      this.fabric_version = map["fabric-version"];
      this.minecraft_version = map["minecraft-version"];
      this.jar_file = map["jar-file"];
      this.minram = map["min-ram"];
      this.maxram = map["max-ram"];
      this.gui = map["gui"];
  }

  @override
  Map<String,dynamic> toMap() {
    return {
      "type": "fabric",
      "fabric-version": fabric_version,
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
  String toString() {
    return toProperties().toString();
  }

  @override
  Future<File> save() {
    return saveToFile(file);
  }

  @override
  void saveSync() {
    saveToFileSync(file);
  }
}

const FabricManager fabric = const FabricManager();