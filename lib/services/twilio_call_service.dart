import 'twilio_call_service_stub.dart'
    if (dart.library.html) 'twilio_call_service_web.dart';

class TwilioCallService {
  static void registerViews() => TwilioCallServicePlatform.registerViews();

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
  }) {
    TwilioCallServicePlatform.startCall(
      token: token,
      roomName: roomName,
      isAudioOnly: isAudioOnly,
      onConnected: onConnected,
      onDisconnected: onDisconnected,
      onParticipantConnected: onParticipantConnected,
      onParticipantDisconnected: onParticipantDisconnected,
      onMicLevel: onMicLevel,
      onError: onError,
    );
  }

  static bool toggleAudio(bool enable) => TwilioCallServicePlatform.toggleAudio(enable);

  static bool toggleVideo(bool enable) => TwilioCallServicePlatform.toggleVideo(enable);

  static void switchCamera() => TwilioCallServicePlatform.switchCamera();

  static void remountVideo() => TwilioCallServicePlatform.remountVideo();

  static void setVolume(double percent) => TwilioCallServicePlatform.setVolume(percent);

  static void endCall() => TwilioCallServicePlatform.endCall();
}
