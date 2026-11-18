class TwilioCallServicePlatform {
  static void registerViews() {}

  static void startCall({
    required String token,
    required String roomName,
    required bool isAudioOnly,
    Function(String roomName)? onConnected,
    Function()? onDisconnected,
    Function(String identity)? onParticipantConnected,
    Function(String identity)? onParticipantDisconnected,
    Function(double level)? onMicLevel,
    Function(String error)? onError,
  }) {}

  static bool toggleAudio(bool enable) => enable;

  static bool toggleVideo(bool enable) => enable;

  static void switchCamera() {}

  static void remountVideo() {}

  static void setVolume(double percent) {}

  static void endCall() {}
}
