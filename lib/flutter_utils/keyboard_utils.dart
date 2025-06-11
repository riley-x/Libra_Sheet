import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HardwareKeyboard;

bool isMultiselect() {
  if (kIsWeb) {
    return HardwareKeyboard.instance.isControlPressed;
  } else if (Platform.isMacOS) {
    return HardwareKeyboard.instance.isMetaPressed;
  } else if (Platform.isWindows) {
    return HardwareKeyboard.instance.isControlPressed;
  } else {
    return false;
  }
}
