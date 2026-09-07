import 'package:sensors_plus/sensors_plus.dart';

bool get browserMotionSupported => false;
Future<String> requestMotionAccess() async => 'unavailable';
Stream<AccelerometerEvent> browserMotionEvents() => const Stream.empty();
Future<String> shareAppLink() async => 'unavailable';
Future<String> copyAppLink() async => 'unavailable';
String loadDeviceState() => '';
bool saveDeviceState(String value) => false;
