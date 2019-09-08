import 'package:mc_launcher/core.dart';
import 'package:mc_launcher/minecraft/minecraft.dart';

main() async {

  // Create Fabric server in the directory "server" with a accepted eula, minecraft version 1.14 and fabric loader version 0.6.1+build.165
  // With setting the eula arg to true you accept the eula of Mojang!
  MinecraftServer server = await FabricServer.create("./server", defaultEula: true, minecraft_version: "1.14", fabric_version: "0.6.1+build.165");

  // Set the maximum ram of the server to 2048 MB
  server.properties.maxram = 2048;

  // Set the minimum ram of the server to 512 MB
  server.properties.maxram = 512;

  // Save the server's properties
  await server.properties.save();

  // Start it (Future finishes when server has finished starting)
  await server.start();

  // Execute Command in server console
  server.executeCommand("say hello world :)");

  // Stop server after one minute
  Future.delayed(Duration(minutes: 1)).then((e) {
    server.stop();
  });

}