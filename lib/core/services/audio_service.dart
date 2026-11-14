import 'audio_service_stub.dart'
    if (dart.library.html) 'audio_service_web.dart';

class AudioService {
  /// Plays the incoming notification / calling ringtone sound
  static void playRingtone() {
    playRingtonePlatform();
  }

  /// Stops the ringtone sound immediately
  static void stopRingtone() {
    stopRingtonePlatform();
  }
}
