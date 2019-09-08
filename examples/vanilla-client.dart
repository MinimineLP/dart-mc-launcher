import 'package:mc_launcher/minecraft/minecraft.dart';
import 'package:mc_launcher/vanilla/vanilla.dart';

main() async {

  // Create client in directory ./client with version 1.14, 6000MB maximum and 4000 minimum ram
  MinecraftClient client = await VanillaClient.createClient(rootDir: "./client", version: "1.14.4", maxRam: 6000, minRam: 4000);

  // Start it
  client.start();

  // Kill our client after a minute
  Future.delayed(Duration(minutes: 1)).then((e) {
    client.kill();
  });

}