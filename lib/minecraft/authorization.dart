import 'dart:convert';

import 'package:console/console.dart';
import 'package:mc_launcher/utils.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

Uuid _uuid = new Uuid();

class Authorization {

  final String access_token;
  final String client_token;
  final String uuid;
  final String name;
  final String user_properties;
  final Map<String,dynamic> selected_profile;
  final String email;
  final String userId;

  final Map<String, dynamic> answer;

  Authorization({
    this.access_token,
    this.name,
    this.client_token,
    this.selected_profile,
    this.user_properties,
    this.uuid,
    this.answer,
    this.email,
    this.userId
  });

  static Authorization invalid({String name = "no_name_selected"}) {
    return Authorization(access_token: _uuid.v1(), client_token: _uuid.v1(), uuid: _uuid.v1(), name: name, user_properties: "{}");
  }

  static Authorization offline({String name = "no_name_selected"}) {
    return invalid(name: name);
  }

  static Future<Authorization> authorize(String user, String password) async {
    String url = "https://authserver.mojang.com/authenticate";
    Map cont = {
      "agent": {
        "name": "Minecraft",
        "version": 1
      },
      "username": user,
      "password": password,
      "clientToken": _uuid.v1(),
      "requestUser": true
    };

    Map<String,String> headers = {
      "Content-Type": "application/json"
    };

    Map<String, dynamic> answer;

    try {
      answer = json.decode((await http.post(url,body: json.encode(cont), headers: headers)).body);
    } catch(e) {
      Chooser chooser = Chooser<String>(
        ["Y", "N"],
        message: "Could not connect to auth-server. Do you want to launch an offline session instead? (Y/n): ",
      );
      if(await chooser.choose() == "Y") {
        String name = await readLine();
        return Authorization.offline(name: name);
      }
      else {
        throw e;
      }
    }

    if(answer["selectedProfile"] == null) {
      throw("Wrong user / password!");
    }

    return new Authorization(
      access_token: answer["accessToken"],
      client_token: answer["clientToken"],
      uuid: answer["selectedProfile"]["id"],
      name: answer["selectedProfile"]["name"],
      selected_profile: answer["selectedProfile"],
      user_properties: json.encode(answer["user"]["properties"] ?? {}),
      answer: answer,
      userId: answer["user"]["id"],
      email: answer["user"]["email"],
    );
  }
}