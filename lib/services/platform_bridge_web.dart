import 'dart:async';
import 'dart:js_interop';
import 'package:sensors_plus/sensors_plus.dart';

@JS('wingstar.motionSupported')
external JSBoolean get _motionSupported;
@JS('wingstar.requestMotionAccess')
external JSPromise<JSString> _requestMotionAccess();
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

bool get browserMotionSupported => _motionSupported.toDart;
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
