#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

void main() {
  'adb shell am start -a android.intent.action.VIEW '
          '-c android.intent.category.BROWSABLE '
          '-d "https://pigation.onepub.dev/xero/auth_complete"'
      .run;
}
