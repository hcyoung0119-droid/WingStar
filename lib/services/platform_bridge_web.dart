import 'dart:async';
import 'dart:js_interop';
import 'package:sensors_plus/sensors_plus.dart';

@JS('wingstar.motionSupported')
external JSBoolean get _motionSupported;
@JS('wingstar.requestMotionAccess')
external JSPromise<JSString> _requestMotionAccess();
@JS('wingstar.resetMotionAccess')
external void _resetMotionAccess();
@JS('wingstar.startMotion')
external void _startMotion(JSFunction callback);
@JS('wingstar.stopMotion')
external void _stopMotion();
@JS('wingstar.shareLink')
external JSPromise<JSString> _shareLink();
@JS('wingstar.copyLink')
external JSPromise<JSString> _copyLink();
@JS('wingstar.loadState')
external JSString _loadState();
@JS('wingstar.saveState')
external JSBoolean _saveState(JSString value);

@JS('wingstarMedia.state')
external JSString _musicState();
@JS('wingstarMedia.play')
external JSPromise<JSString> _playMusic();
@JS('wingstarMedia.pause')
external void _pauseMusic();
@JS('wingstarMedia.stop')
external void _stopMusic();
@JS('wingstarMedia.pickMusic')
external void _pickMusic();
@JS('wingstarMedia.select')
external void _selectMusic(JSString id);
@JS('wingstarMedia.remove')
external JSPromise<JSAny?> _removeMusic(JSString id);
@JS('wingstarMedia.setEnabled')
external void _enableMusic(JSBoolean value);
@JS('wingstarMedia.setVolume')
external void _volume(JSNumber value);
@JS('wingstarMedia.setLifecycle')
external void _lifecycle(JSFunction callback);
@JS('wingstarMedia.wake')
external JSPromise<JSAny?> _wake();
@JS('wingstarMedia.releaseWake')
external void _releaseWake();
@JS('wingstarMedia.speak')
external void _speak(JSString value);
@JS('wingstarMedia.stopVoice')
external void _stopVoice();

String musicState() => _musicState().toDart;
Future<String> playMusic() => _playMusic().toDart.then((v) => v.toDart);
void pauseMusic() => _pauseMusic();
void stopMusic() => _stopMusic();
void pickMusic() => _pickMusic();
void selectMusic(String id) => _selectMusic(id.toJS);
Future<void> removeMusic(String id) async {
  await _removeMusic(id.toJS).toDart;
}

void enableMusic(bool value) => _enableMusic(value.toJS);
void setMusicVolume(double value) => _volume(value.toJS);
void onVisibility(void Function(bool) callback) =>
    _lifecycle(((JSBoolean visible) => callback(visible.toDart)).toJS);
Future<void> keepScreenAwake() async {
  await _wake().toDart;
}

void releaseScreenAwake() => _releaseWake();
void speakCue(String value) => _speak(value.toJS);
void stopVoice() => _stopVoice();

bool get browserMotionSupported => _motionSupported.toDart;
void resetMotionAccess() => _resetMotionAccess();
Future<String> requestMotionAccess() =>
    _requestMotionAccess().toDart.then((v) => v.toDart);
Future<String> shareAppLink() => _shareLink().toDart.then((v) => v.toDart);
Future<String> copyAppLink() => _copyLink().toDart.then((v) => v.toDart);
String loadDeviceState() => _loadState().toDart;
bool saveDeviceState(String value) => _saveState(value.toJS).toDart;

Stream<AccelerometerEvent> browserMotionEvents() {
  late StreamController<AccelerometerEvent> controller;
  controller = StreamController<AccelerometerEvent>(
    onListen: () {
      _startMotion(
        ((JSNumber x, JSNumber y, JSNumber z) {
          if (!controller.isClosed) {
            controller.add(
              AccelerometerEvent(
                x.toDartDouble,
                y.toDartDouble,
                z.toDartDouble,
                DateTime.now(),
              ),
            );
          }
        }).toJS,
      );
    },
    onCancel: () => _stopMotion(),
  );
  return controller.stream;
}
