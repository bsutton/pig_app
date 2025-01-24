import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

final projectRoot = DartProject.self.pathToProjectRoot;
// original names
// final keyStorePath = join(projectRoot, 'hmb-key.keystore');
// const keyStoreAlias = 'hmbkey';

final keyStorePath = join(projectRoot, 'pigation-production.keystore');
const keyStoreAlias = 'pigation-production';

// final keyStorePathForDebug = join(projectRoot, 'hmb-key-debug.keystore');
// const keyStoreAliasForDebug = 'hmb-debug-key';

final keyStorePathForDebug = join(projectRoot, 'pigation-debug.keystore');
const keyStoreAliasForDebug = 'pigation-debug';
