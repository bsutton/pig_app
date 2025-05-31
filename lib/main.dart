import 'dart:async';

import 'package:dcli_core/dcli_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

// import 'api/http/http_client_factory.dart'
//     if (dart.library.js_interop) 'api/http/http_client_factory_web.dart' as http_factory;
import 'api/notification_manager.dart';
import 'ui/error.dart';
import 'ui/nav/route.dart';
import 'ui/widgets/blocking_ui.dart';
import 'util/hmb_theme.dart';
import 'util/log.dart';
import 'util/platform_ex.dart';

var firstRun = false;

Future<void> main(List<String> args) async {
  Log.configure('.');

  // Ensure WidgetsFlutterBinding is initialized before any async code.
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(isOptional: true);

  /// Requests notification updates for the webserver.
  NotificationManager().init();

  // BlockingUIRunner key
  final blockingUIKey = GlobalKey();

  runApp(
      // Provider<Client>(
      //       // Reusing the same `Client` may:
      //       // - reduce memory usage
      //       // - allow caching of fetched URLs
      //       // - allow connections to be persisted
      //       create: (_) => http_factory.httpClient(),
      //       dispose: (_, client) => client.close(),
      //       child:
      // Wrap the entire app with a Container and DecoratedBox
      ToastificationWrapper(
    child: MaterialApp.router(
      theme: theme,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
                border:
                    Border.all(color: isMobile ? Colors.black : Colors.white)),
            child: BlockingUIRunner(
              key: blockingUIKey,
              slowAction: () => _initialise(context),
              label: 'Upgrading your database.',
              builder: (context) => child ?? const SizedBox.shrink(),
            ),
          ),

          // The overlay
          const BlockingOverlay(),
        ],
      ),
    ),
  )
      // )
      );
}

ThemeData get theme => ThemeData(
      primaryColor: Colors.deepPurple,
      brightness: Brightness.dark, // Overall theme brightness
      scaffoldBackgroundColor: HMBColors.defaultBackground,
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.deepPurple, // Button background color
        textTheme: ButtonTextTheme.primary, // Ensures contrast for text
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple, // Background for elevated buttons
          foregroundColor: Colors.white, // Text color for elevated buttons
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              Colors.deepPurpleAccent, // Text color for text buttons
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              Colors.deepPurpleAccent, // Text color for outlined buttons
          side:
              const BorderSide(color: Colors.deepPurpleAccent), // Border color
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        actionTextColor: HMBColors.accent,
        backgroundColor: Colors.grey.shade800,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      timePickerTheme: TimePickerThemeData(
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
      dialogTheme: const DialogThemeData(
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: HMBColors.accent,
        surface: HMBColors.defaultBackground,
        onPrimary: Colors.white, // Ensures text contrast on primary
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

var initialised = false;
Future<void> _initialise(BuildContext context) async {
  if (!initialised) {
    try {
      initialised = true;
      firstRun = await _checkInstall();
      // ignore: avoid_catches_without_on_clauses
    } catch (e, _) {
      // Capture the exception in Sentry
      // unawaited(Sentry.captureException(e, stackTrace: stackTrace));

      if (context.mounted) {
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => FullScreenDialog(
                  content: ErrorScreen(errorMessage: e.toString()),
                  title: 'Database Error',
                ));
      }
      rethrow;
    }
  }
}

Future<bool> _checkInstall() async {
  if (kIsWeb) {
    return false;
  }

  final pathToHmbFirstRun = join(await pathToHmbFiles, 'firstrun.txt');
  print('checking firstRun: $pathToHmbFirstRun');

  if (!exists(await pathToHmbFiles)) {
    createDir(await pathToHmbFiles, recursive: true);
  }

  final firstRun = !exists(pathToHmbFirstRun);
  if (firstRun) {
    touch(pathToHmbFirstRun, create: true);
  }
  return firstRun;
}

Future<String> get pathToHmbFiles async =>
    join((await getApplicationSupportDirectory()).path, 'pigation');

// class ErrorApp extends StatelessWidget {
//   const ErrorApp(this.errorMessage, {super.key});
//   final String errorMessage;

//   @override
//   W
//idget build(BuildContext context) => MaterialApp(
//         home: ErrorScreen(errorMessage: errorMessage),
//       );
// }
