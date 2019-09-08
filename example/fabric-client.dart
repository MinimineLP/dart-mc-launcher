import 'package:mc_launcher/fabric/client.dart';
import 'package:mc_launcher/minecraft/minecraft.dart';
import 'package:mc_launcher/vanilla/vanilla.dart';

main() async {

  // Create client in directory ./client with minecraft version 1.14 and fabric loader version 0.6.1+build.165 (for me now this is the latest version)
  // 6000MB maximum and 4000 minimum ram
  MinecraftClient client = await FabricClient.createClient(rootDir: "./client", minecraft_version: "1.14.4", maxRam: 4096, minRam: 512, fabric_version: "0.6.1+build.165");

  // Start it
  client.start();

  // Kill our client after a minute
  Future.delayed(Duration(minutes: 1)).then((e) {
    client.kill();
  });

}