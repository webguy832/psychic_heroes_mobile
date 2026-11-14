// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void playRingtonePlatform() {
  try {
    js.context.callMethod('playRingtoneSound');
  } catch (_) {}
}

void stopRingtonePlatform() {
  try {
    js.context.callMethod('stopRingtoneSound');
  } catch (_) {}
}

