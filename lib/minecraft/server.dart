import 'dart:io';

import 'package:mc_launcher/minecraft/server_properties.dart';
import 'package:mc_launcher/properties_format.dart';

abstract class MinecraftServer {
  String get serverdir;
  DartMcLauncherProperties get properties;
  ServerProperties get server_properties;
  Process process;
  List<void Function(String)> onStdOut;
  List<void Function(String)> onStdErr;
  bool get running;
  Future<MinecraftServer> start();
  Future<MinecraftServer> stop();
  void executeCommand(String command);
}

abstract class DartMcLauncherProperties {
  PropertiesTemplate template = null;
  String minecraft_version;
  String jar_file;
  int minram;
  int maxram;
  bool gui = false;
  String file;
  Map<String,dynamic> toMap();
  Properties toProperties();
  Future<File> saveToFile(String file);
  Future<File> save();
  void saveToFileSync(String file);
  void saveSync();

  @override
  String toString();
}