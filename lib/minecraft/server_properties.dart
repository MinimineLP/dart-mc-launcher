import 'dart:io';

import 'package:meta/meta.dart';
import 'package:mc_launcher/properties_format.dart';

class ServerProperties {
  PropertiesTemplate template = null;
  String file;

  LEVEL_TYPE level_type = LEVEL_TYPE.DEFAULT;
  SERVER_DIFFICULTY difficulty = SERVER_DIFFICULTY.EASY;
  SERVER_GAMEMODE gamemode = SERVER_GAMEMODE.SURVIVAL;
  String generator_settings = "";
  String level_name = "world";
  String level_seed = "";
  String motd = "A Minecraft Server";
  String resource_pack = "";
  String resource_pack_sha1 = "";
  String server_ip = "";
  bool allow_flight = false;
  bool allow_nether = true;
  bool broadcast_console_to_ops = true;
  bool enable_command_block = false;
  bool enable_query = false;
  bool enable_rcon = false;
  bool enforce_whitelist = false;
  bool force_gamemode = false;
  bool generate_structures = true;
  bool hardcore = false;
  bool online_mode = true;
  bool prevent_proxy_connections = false;
  bool pvp = true;
  bool snooper_enabled = true;
  bool spawn_animals = true;
  bool spawn_monsters = true;
  bool spawn_npcs = true;
  bool white_list = false;
  int function_permission_level = 2;
  int max_build_height = 256;
  int max_players = 20;
  int max_tick_time = 60000;
  int max_world_size = 29999984;
  int network_compression_threshold = 256;
  int op_permission_level = 4;
  int player_idle_timeout = 0;
  int server_port = 25565;
  int spawn_protection = 16;
  int view_distance = 10;

  ServerProperties ({
    this.allow_flight = false,
    this.allow_nether = true,
    this.broadcast_console_to_ops = true,
    this.difficulty = SERVER_DIFFICULTY.EASY,
    this.enable_command_block = false,
    this.enable_query = false,
    this.enable_rcon = false,
    this.enforce_whitelist = false,
    this.force_gamemode = false,
    this.function_permission_level = 2,
    this.gamemode = SERVER_GAMEMODE.SURVIVAL,
    this.generate_structures = true,
    this.generator_settings = "",
    this.hardcore = false,
    this.level_name = "world",
    this.level_seed = "",
    this.level_type = LEVEL_TYPE.DEFAULT,
    this.max_build_height = 256,
    this.max_players = 20,
    this.max_tick_time = 60000,
    this.max_world_size = 29999984,
    this.motd = "A Minecraft Server",
    this.network_compression_threshold = 256,
    this.online_mode = true,
    this.op_permission_level = 4,
    this.player_idle_timeout = 0,
    this.prevent_proxy_connections = false,
    this.pvp = true,
    this.resource_pack = "",
    this.resource_pack_sha1 = "",
    this.server_ip = "",
    this.server_port = 25565,
    this.snooper_enabled = true,
    this.spawn_animals = true,
    this.spawn_monsters = true,
    this.spawn_npcs = true,
    this.spawn_protection = 16,
    this.view_distance = 10,
    this.white_list = false,
    this.template = null,
    @required this.file,
  });

  ServerProperties.loadMap(Map<String,dynamic> properties, this.file) {
    this._loadMap(properties);
  }

  ServerProperties.loadProperties(Properties properties, this.file) {
    this._loadMap(properties.toMap());
    this.template = properties.toTemplate();
  }

  ServerProperties.loadFile(String file):this.loadProperties(Properties.parse(File(file).readAsStringSync()), file) ;

  Map<String,dynamic> toMap() {
    return {
      "allow-flight": this.allow_flight,
      "allow-nether": this.allow_nether,
      "broadcast-console-to-ops": this.broadcast_console_to_ops,
      "difficulty": this.difficulty.toString(),
      "enable-command-block": this.enable_command_block,
      "enable-query": this.enable_query,
      "enable-rcon": this.enable_rcon,
      "enforce-whitelist": this.enforce_whitelist,
      "force-gamemode": this.force_gamemode,
      "function-permission-level": this.function_permission_level,
      "gamemode": this.gamemode,
      "generate-structures": this.generate_structures,
      "generator-settings": this.generator_settings,
      "hardcore": this.hardcore,
      "level-name": this.level_name,
      "level-seed": this.level_seed,
      "level-type": this.level_type.toString(),
      "max-build-height": this.max_build_height,
      "max-players": this.max_players,
      "max-tick-time": this.max_tick_time,
      "max-world-size": this.max_world_size,
      "motd": this.motd,
      "network-compression-threshold": this.network_compression_threshold,
      "online-mode": this.online_mode,
      "op-permission-level": this.op_permission_level,
      "player-idle-timeout": this.player_idle_timeout,
      "prevent-proxy-connections": this.prevent_proxy_connections,
      "pvp": this.pvp,
      "resource-pack": this.resource_pack,
      "resource-pack-sha1": this.resource_pack_sha1,
      "server-ip": this.server_ip,
      "server-port": this.server_port,
      "snooper-enabled": this.snooper_enabled,
      "spawn-animals": this.spawn_animals,
      "spawn-monsters": this.spawn_monsters,
      "spawn-npcs": this.spawn_npcs,
      "spawn-protection": this.spawn_protection,
      "view-distance": this.view_distance,
      "white-list": this.white_list,
    };
  }

  Properties toProperties() {
    return (this.template ?? PropertiesTemplate([
      PropertiesComment("Minecraft server properties"),
      PropertiesComment("(File Modification Datestamp)"),
    ])).create(this.toMap());
  }

  @override
  String toString() {
    return toProperties().toString();
  }

  void _loadMap(Map<String,dynamic> properties) {
    this.allow_flight = properties["allow-flight"] ?? false;
    this.allow_nether = properties["allow-nether"] ?? true;
    this.broadcast_console_to_ops = properties["broadcast-console-to-ops"] ?? true;
    this.difficulty = SERVER_DIFFICULTY(properties["difficulty"]) ?? SERVER_DIFFICULTY.EASY;
    this.enable_command_block = properties["enable-command-block"] ?? false;
    this.enable_query = properties["enable-query"] ?? false;
    this.enable_rcon = properties["enable-rcon"] ?? false;
    this.enforce_whitelist = properties["enforce-whitelist"] ?? false;
    this.force_gamemode = properties["force-gamemode"] ?? false;
    this.function_permission_level = properties["function-permission-level"] ?? 2;
    this.gamemode = SERVER_GAMEMODE(properties["gamemode"]) ?? SERVER_GAMEMODE.SURVIVAL;
    this.generate_structures = properties["generate-structures"] ?? true;
    this.generator_settings = properties["generator-settings"] ?? "";
    this.hardcore = properties["hardcore"] ?? false;
    this.level_name = properties["level-name"] ?? "world";
    this.level_seed = properties["level-seed"] ?? "";
    this.level_type = LEVEL_TYPE(properties["level-type"]) ?? LEVEL_TYPE.DEFAULT;
    this.max_build_height = properties["max-build-height"] ?? 256;
    this.max_players = properties["max-players"] ?? 20;
    this.max_tick_time = properties["max-tick-time"] ?? 60000;
    this.max_world_size = properties["max-world-size"] ?? 29999984;
    this.motd = properties["motd"] ?? "A Minecraft Server";
    this.network_compression_threshold = properties["network-compression-threshold"] ?? 256;
    this.online_mode = properties["online-mode"] ?? true;
    this.op_permission_level = properties["op-permission-level"] ?? 4;
    this.player_idle_timeout = properties["player-idle-timeout"] ?? 0;
    this.prevent_proxy_connections = properties["prevent-proxy-connections"] ?? false;
    this.pvp = properties["pvp"] ?? true;
    this.resource_pack = properties["resource-pack"] ?? "";
    this.resource_pack_sha1 = properties["resource-pack-sha1"] ?? "";
    this.server_ip = properties["server-ip"] ?? "";
    this.server_port = properties["server-port"] ?? 25565;
    this.snooper_enabled = properties["snooper-enabled"] ?? true;
    this.spawn_animals = properties["spawn-animals"] ?? true;
    this.spawn_monsters = properties["spawn-monsters"] ?? true;
    this.spawn_npcs = properties["spawn-npcs"] ?? true;
    this.spawn_protection = properties["spawn-protection"] ?? 16;
    this.view_distance = properties["view-distance"] ?? 10;
    this.white_list = properties["white-list"] ?? false;
  }
  
  Future<File> saveToFile(String file) {
    return toProperties().saveToFile(file);
  }

  void saveToFileSync(String file) {
    toProperties().saveToFileSync(file);
  }

  Future<File> save() {
    return saveToFile(file);
  }

  void saveSync() {
    saveToFileSync(file);
  }
}

class SERVER_DIFFICULTY {
  final String value;
  const SERVER_DIFFICULTY(this.value);

  String toString() {
    return this.value;
  }

  bool operator ==(dynamic server_difficulty) { 
    return server_difficulty is SERVER_DIFFICULTY ? server_difficulty.value == this.value : server_difficulty is String ? server_difficulty == this.value : false; 
  }

  static const SERVER_DIFFICULTY PEACEFUL = SERVER_DIFFICULTY("peaceful");
  static const SERVER_DIFFICULTY EASY = SERVER_DIFFICULTY("easy");
  static const SERVER_DIFFICULTY NORMAL = SERVER_DIFFICULTY("normal");
  static const SERVER_DIFFICULTY HARD = SERVER_DIFFICULTY("hard");
}

class SERVER_GAMEMODE {
  final String value;
  const SERVER_GAMEMODE(this.value);

  String toString() {
    return this.value;
  }

  bool operator ==(dynamic server_difficulty) { 
    return server_difficulty is SERVER_GAMEMODE ? server_difficulty.value == this.value : server_difficulty is String ? server_difficulty == this.value : false; 
  }

  static const SERVER_GAMEMODE SURVIVAL = SERVER_GAMEMODE("survival");
  static const SERVER_GAMEMODE CREATIVE = SERVER_GAMEMODE("creative");
  static const SERVER_GAMEMODE ADVENTURE = SERVER_GAMEMODE("adventure");
  static const SERVER_GAMEMODE SPECTATOR = SERVER_GAMEMODE("spectator");
}

class LEVEL_TYPE {
  final String value;
  const LEVEL_TYPE(this.value);

  String toString() {
    return this.value.toString();
  }

  bool operator ==(dynamic level_type) { 
    return level_type is LEVEL_TYPE ? level_type.value == this.value : level_type is int ? level_type == this.value : false; 
  }

  static const LEVEL_TYPE DEFAULT = LEVEL_TYPE("DEFAULT");
  static const LEVEL_TYPE FLAT = LEVEL_TYPE("FLAT");
  static const LEVEL_TYPE LARGEBIOMES = LEVEL_TYPE("LARGEBIOMES");
  static const LEVEL_TYPE AMPLIFIED = LEVEL_TYPE("AMPLIFIED");
  static const LEVEL_TYPE BUFFET  = LEVEL_TYPE("BUFFET");
}