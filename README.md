# dart-mc-launcher v0.0.1

dart-mc-launcher is a framework for starting minecraft clients and servers from dart

## Installation

```yaml
name: [unique_namespace]
dependencies:  
  mc_launcher: ^0.0.1
```

Also remember to replace the `[unique_namespace]` with your own project name and run

```shell
$ pub get
```

if you are using a clever editor like `vscode`, you can propably you can propably skip this step

## Getting started

### **Base**

First import the package

```dart
import 'package:mc_launcher/core.dart';
```

The hole package is written asynchronously, so we will use an async main method to demonstarte the package functionality.

```dart
void main(List<String> args) async {
}
```

### **Server**

Inside of it we will create a simple vanilla server the subdirectory server. This directory will be created automatically. Also we will set the default eula value to true, so we can start the server. It is defaultly false, so we have to accept it manually, but with this, our server is directly ready to start.
I set the version to 1.14.4 here, if you do not set the version, it will automatically use the latest version

```dart
MinecraftServer server = await VanillaServer.create("./server", defaultEula: true, version: "1.14.4");
```

Now we start the server

```dart
server.start();
```

We can execute Commands using

```dart
server.executeCommand("say hello world :)");
```

And stop it using

```dart
server.stop();
```

more configurations you can set like this:

```dart
server.properties.mar
```

### **Client**

To create clients also is really easy. You just have to specify the version, the root directory. If you want you can also specify maximum *(default: 1024)* and minimum *(default 512)* ram. *It will take some time for the client to download the assets at this point on the first start*

```dart
MinecraftClient client = await VanillaClient.createClient(rootDir: "./client", version: "1.14.4", maxRam: 6000, minRam: 4000);
```

To start the clients just use client.start.

```dart
client.start()
```

you can **not** use .stop() on the clients, you can just kill them via client.kill. The problem with killing the client is, that it saves no worlds, etc when you kill them, so be carefull with this function

```dart
client.kill()
```

## License

This package is licensed under the [BSD2-Clause](https://github.com/MinimineLP/dart-mc-launcher/blob/master/LICENSE)

## Authors

- **Minimine** - *Initial work* - [Minimine](https://github.com/MinimineLP)

## Issues

Please report bugs, issues, feature request and stuff like that on the [github issue tracker](https://github.com/MinimineLP/dart-mc-launcher/issues)

If you are coding yourself and have a fix for my code feel free do send a [pull request](https://github.com/MinimineLP/dart-mc-launcher/pulls)
