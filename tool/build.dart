#! /home/bsutton/.dswitch/active/dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:pub_release/pub_release.dart' hide Settings;
import 'package:pubspec_manager/pubspec_manager.dart' as pm;

import 'lib/version_properties.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('build',
        abbr: 'b',
        help: 'build the apk suitable for installing the app via USB')
    ..addFlag('wasm', abbr: 'w', help: 'Build for wasm')
    ..addFlag('source-maps',
        abbr: 's',
        help: 'when building for wasm include debug symbols and source maps')
    ..addFlag('install',
        abbr: 'i', help: 'install the apk to a device connected via USB')
    ..addFlag('release', abbr: 'r', help: '''
Create a signed release appbundle suitable to upload to Google Play store.''')
    ..addFlag('help', abbr: 'h', help: 'Shows the help message');

  final results = parser.parse(args);

  Settings().setVerbose(enabled: false);

  final help = results['help'] as bool;
  if (help) {
    showUsage(parser);
    exit(0);
  }
  var build = results['build'] as bool;
  var install = results['install'] as bool;
  final release = results['release'] as bool;
  final wasm = results['wasm'] as bool;
  final sourceMaps = results['source-maps'] as bool;

  if (!build && !install && !release) {
    /// no switches passed so do it all.
    build = install = true;
  }
  if (release) {
    install = false;
    build = true;
  }

  var needPubGet = true;

  if (build) {
    final pathToPubSpec = DartProject.self.pathToPubSpec;
    final currentVersion = version(pubspecPath: pathToPubSpec)!;
    final newVersion = askForVersion(currentVersion);
    updateVersion(newVersion, pm.PubSpec.load(), pathToPubSpec);

    updateAndroidVersion(newVersion);

    if (needPubGet) {
      _runPubGet();
      needPubGet = false;
    }
    if (wasm) {
      buildWasm(includeSourceMaps: sourceMaps);
    }
    if (release) {
      buildAppBundle(newVersion);
    } else {
      buildApk();
    }
  }

  if (install) {
    installApk();
  }
}

void showUsage(ArgParser parser) {
  print('''
Tools to help build the app
  If no switches are passed then --assets, --build and --install are assumed
  ''');
  print(parser.usage);
}

void _runPubGet() {
  DartSdk().runPubGet(DartProject.self.pathToProjectRoot);
}

void installApk() {
  print(orange(
      'Make certain you have first run --build so you get the lastet apk'));
  // 'flutter install'.run;

  'adb install -r build/app/outputs/flutter-apk/app-release.apk'.run;
}

void buildApk() {
  'flutter build apk'.run;
}

void buildWasm({required bool includeSourceMaps}) {
  if (includeSourceMaps) {
    // build for debugging.
    'flutter  build web --wasm --no-strip-wasm --source-maps'.start();
  } else {
    'flutter  build web --wasm'.start();
  }
}

void buildAppBundle(Version newVersion) {
  'flutter build appbundle --release'.start();

  final targetPath =
      join(DartProject.self.pathToProjectRoot, 'hmb-$newVersion.aab');
  if (exists(targetPath)) {
    delete(targetPath);
  }
  move(join('build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'),
      targetPath);
  print(orange('Moved the bundle to $targetPath'));
}
