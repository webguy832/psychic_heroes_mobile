// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

class TwilioCallServicePlatform {
  static bool _viewsRegistered = false;

  static void registerViews() {
    if (_viewsRegistered) return;
    _viewsRegistered = true;
    try {
      ui_web.platformViewRegistry.registerViewFactory('twilio-remote-video-view', (int viewId) {
        final div = html.DivElement()
          ..id = 'twilio-remote-video'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent';
        return div;
      });

      ui_web.platformViewRegistry.registerViewFactory('twilio-local-pip-view', (int viewId) {
        final div = html.DivElement()
          ..id = 'twilio-local-pip'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '14px'
          ..style.overflow = 'hidden'
          ..style.backgroundColor = 'transparent';
        return div;
      });
    } catch (_) {}
  }

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
    registerViews();
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        final callbacks = js.JsObject.jsify({
          'onConnected': (String room) {
            if (onConnected != null) onConnected(room);
          },
          'onDisconnected': () {
            if (onDisconnected != null) onDisconnected();
          },
          'onParticipantConnected': (String id) {
            if (onParticipantConnected != null) onParticipantConnected(id);
          },
          'onParticipantDisconnected': (String id) {
            if (onParticipantDisconnected != null) onParticipantDisconnected(id);
          },
          'onMicLevel': (num lvl) {
            if (onMicLevel != null) onMicLevel(lvl.toDouble());
          },
          'onError': (dynamic err) {
            if (onError != null) onError(err.toString());
          },
        });

        mgr.callMethod('startCall', [token, roomName, isAudioOnly, callbacks]);
      }
    } catch (e) {
      if (onError != null) onError(e.toString());
    }
  }

  static bool toggleAudio(bool enable) {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        final res = mgr.callMethod('toggleAudio', [enable]);
        return res == true;
      }
    } catch (_) {}
    return enable;
  }

  static bool toggleVideo(bool enable) {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        final res = mgr.callMethod('toggleVideo', [enable]);
        return res == true;
      }
    } catch (_) {}
    return enable;
  }

  static void switchCamera() {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        mgr.callMethod('switchCamera');
      }
    } catch (_) {}
  }

  static void remountVideo() {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        mgr.callMethod('remountVideo');
      }
    } catch (_) {}
  }

  static void setVolume(double percent) {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        mgr.callMethod('setVolume', [percent]);
      }
    } catch (_) {}
  }

  static void endCall() {
    try {
      final mgr = js.context['TwilioCallManager'];
      if (mgr != null) {
        mgr.callMethod('endCall');
      }
    } catch (_) {}
  }
}
