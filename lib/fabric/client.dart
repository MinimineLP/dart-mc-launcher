import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mc_launcher/fabric/fabricutils.dart';
import 'package:mc_launcher/java.dart';
import 'package:mc_launcher/minecraft/authorization.dart';
import 'package:mc_launcher/utils.dart';
import 'package:mc_launcher/minecraft/client.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

class FabricClient implements MinecraftClient {

  final String rootDir;
  MinecraftClientPreparer handler;
  String minecraft_version;
  String fabric_version;
  Authorization auth;
  bool get running => process != null;
  int maxRam = 2048;
  int minRam = 512;
  List<void Function(String)> onStdOut = [ (data) { stdout.write(data); } ];
  List<void Function(String)> onStdErr = [ (data) {  stderr.write(data); } ];
  String version;
  Process process;

  FabricClient._init({this.rootDir, @required this.minecraft_version, @required this.fabric_version, this.handler, this.version, this.maxRam = 2048, this.minRam = 512, this.auth}) {
    if(this.auth == null) { this.auth = Authorization.invalid(); }
  }

  static Future<FabricClient> createClient({@required String rootDir, @required String minecraft_version, @required String fabric_version, String installer_version, int maxRam = 2048, int minRam = 512, Authorization auth}) async {

    if(rootDir == null) throw("No rootDir given");
    if(fabric_version == null) throw("No fabric_version given");
    if(minecraft_version == null) throw("No minecraft_version given");

    String version = "fabric-loader-$fabric_version-$minecraft_version";

    await createDirIfNotExists(rootDir);
    if(!await new Directory(path.join(rootDir, "versions", version)).exists()) {

      print("Setting up $version...");

      await File(path.join(rootDir, "launcher_profiles.json")).writeAsString("{\"profiles\":{}}");

      String jarfile = await downloadInstaller(rootDir, installer_version: installer_version);
      List<String> args = ["-jar", jarfile, "client", "-dir", rootDir];

      if(minecraft_version != null) args.addAll(["-version", minecraft_version]);
      if(fabric_version != null) args.addAll(["-loader", fabric_version]);

      Completer installerFinished = new Completer<String>();
      Process.start(JAVA, args).then((Process process) {
        process.stdout.transform(utf8.decoder).listen((data) { stdout.write(data); });
        process.exitCode.then((code) { 
          Future.delayed(Duration(milliseconds: 1000)).then((e) { new Directory("$rootDir/tmp").delete(recursive: true); }); 
          installerFinished.complete(); 
        });
      }).catchError((e) {print(e);});    

      await installerFinished.future;
    }

    return await new FabricClient._init(handler: await new MinecraftClientPreparer(rootDir), rootDir: rootDir, minecraft_version: minecraft_version, fabric_version: fabric_version, version: version, maxRam: maxRam, minRam: minRam, auth: auth ?? auth)._prepare();

  }

  Future<FabricClient> _prepare() async {
    await handler.install(version);
    File jar = new File(await handler.getJar());
    if((await jar.readAsBytes()).length == 0)  {
      await jar.delete();
    }
    await handler.getJar();
    return this;
  }

  Future<FabricClient> start() async {
    String nativePath = resolvePath("$rootDir/natives/$minecraft_version");
    
    // Jvm
    List<String> jvm = [
      '-XX:-UseAdaptiveSizePolicy',
      '-XX:-OmitStackTraceInFastThrow',
      '-Dfml.ignorePatchDiscrepancies=true',
      '-Dfml.ignoreInvalidMinecraftCertificates=true',
      '-Djava.library.path=${nativePath}',  
      '-Xmx${maxRam}M',
      '-Xms${minRam}M',
    ];

    jvm.add(await this.handler.getJVM());
    String mcPath = await handler.getJar();
    List<String> classes = await handler.getClasses();
    List<String> classPaths = ['-cp'];
    String separator = this.handler.getOS() == "windows" ? ";" : ":";
    String jar = (await File(mcPath).exists()) ? '${mcPath}${separator}' : '';
    classPaths.add('${jar}${classes.join(separator)}');
    classPaths.add(handler.version["mainClass"] ?? 'net.minecraft.client.main.Main');

    List<String> args = [];

    args.addAll(jvm);
    args.addAll(classPaths);

    this.handler.getLaunchOptions(auth: auth).forEach((e) {
      args.add(e);
    });

    // print("$JAVAW ${args.join(" ")}");
    this.process = await Process.start(JAVAW, args, workingDirectory: this.rootDir);
    this.process.stdout.transform(utf8.decoder).listen((data) { this.onStdOut.forEach((e) { e(data); }); });
    this.process.stderr.transform(utf8.decoder).listen((data) { this.onStdErr.forEach((e) { e(data); }); });
    this.process.exitCode.then((code) { process = null; });

    return this;
  }

  void kill() {
    process.kill();
  }
}