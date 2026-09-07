import 'package:sensors_plus/sensors_plus.dart';

bool get browserMotionSupported => false;
void resetMotionAccess() {}
Future<String> requestMotionAccess() async => 'unavailable';
Stream<AccelerometerEvent> browserMotionEvents() => const Stream.empty();
Future<String> shareAppLink() async => 'unavailable';
Future<String> copyAppLink() async => 'unavailable';
String loadDeviceState() => '';
bool saveDeviceState(String value) => false;
String musicState() =>
    '{"tracks":[],"status":"unavailable","enabled":false,"volume":0.45,"notice":"음악 기능은 아이폰 웹앱에서 이용할 수 있어요."}';
Future<String> playMusic() async => 'unavailable';
void pauseMusic() {}
void stopMusic() {}
void pickMusic() {}
void selectMusic(String id) {}
Future<void> removeMusic(String id) async {}
void enableMusic(bool value) {}
void setMusicVolume(double value) {}
void onVisibility(void Function(bool) callback) {}
Future<void> keepScreenAwake() async {}
void releaseScreenAwake() {}
void speakCue(String value) {}
void stopVoice() {}
