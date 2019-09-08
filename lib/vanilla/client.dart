import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mc_launcher/java.dart';
import 'package:mc_launcher/minecraft/authorization.dart';
import 'package:mc_launcher/minecraft/client.dart';
import 'package:meta/meta.dart';
import 'package:mc_launcher/utils.dart';

class VanillaClient implements MinecraftClient {

  final String rootDir;
  MinecraftClientPreparer handler;
  String version;
  int maxRam;
  int minRam;
  Authorization auth;
  bool get running => process != null;

  Process process;

  List<void Function(String)> onStdOut = [ (data) { stdout.write(data); } ];
  List<void Function(String)> onStdErr = [ (data) {  stderr.write(data); } ];

  VanillaClient._init({this.rootDir, this.version,this.handler, this.maxRam, this.minRam, this.auth}) {
    if(this.auth == null) { this.auth = Authorization.invalid(); }
  }

  static Future<VanillaClient> createClient({@required String rootDir, @required String version, int maxRam = 512, int minRam = 2048, Authorization auth}) async {
    return await new VanillaClient._init(handler: await new MinecraftClientPreparer(rootDir).setup(version), rootDir: rootDir, version: version, maxRam: maxRam, minRam: minRam, auth: auth)._prepare();
  }

  Future<VanillaClient> _prepare() async {
    await handler.install(version);
    return this;
  }

  Future<VanillaClient> start() async {
    String nativePath = resolvePath("$rootDir/natives/$version");
    
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
    classPaths.add('net.minecraft.client.main.Main');

    List<String> args = [];

    args.addAll(jvm);
    args.addAll(classPaths);

    this.handler.getLaunchOptions(auth: auth).forEach((e) {
      args.add(e);
    });

    //print("$JAVAW ${args.join(" ")}");
    this.process = await Process.start(JAVAW, args, workingDirectory: this.rootDir);
    this.process.stdout.transform(utf8.decoder).listen((data) { this.onStdOut.forEach((e) { e(data); }); });
    this.process.stderr.transform(utf8.decoder).listen((data) { this.onStdErr.forEach((e) { e(data); }); });
    this.process.exitCode.then((code) {
      process = null;
    });

    return this;
  }

  void kill() {
    process.kill();
  }
}