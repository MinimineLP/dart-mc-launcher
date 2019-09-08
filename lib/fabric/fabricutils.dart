import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:mc_launcher/utils.dart';

/// download an installer for fabric
Future<String> downloadInstaller(dir, {String installer_version}) async {

  await createDirIfNotExists(dir);

  if(installer_version == null) {
    http.Response response = await http.get('https://maven.fabricmc.net/net/fabricmc/fabric-installer/');
    Document document = parser.parse(response.body);
    installer_version = "";

    document.getElementsByTagName('a').forEach((Element element){
      if(new RegExp(r"[0-9]").hasMatch(element.text.substring(0, 1))) {
        installer_version = element.attributes["href"].substring(0, element.attributes["href"].length - 1);
      }
    });
  }

  String uri = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/$installer_version/fabric-installer-$installer_version.jar";
  print("downloading fabric installer from $uri...");

  String tmp = "$dir/tmp";

  await createDirIfNotExists(tmp);
  return await downloadFile(uri, '$tmp/fabric-installer.jar');
}