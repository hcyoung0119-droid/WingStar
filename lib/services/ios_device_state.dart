import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A synchronously readable cache with serialized, atomic iOS file writes.
class IosDeviceState {
  IosDeviceState._(this.value);
  static const channel = MethodChannel('wingstar/device-state');
  String value;
  Future<void> _writes = Future<void>.value();
  void Function()? onWriteError;

  static Future<IosDeviceState?> open() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    final value = await channel.invokeMethod<String>('load') ?? '';
    return IosDeviceState._(value);
  }

  bool save(String next) {
    value = next;
    _writes = _writes.then((_) async {
      try {
        await channel.invokeMethod<void>('save', {'value': next});
      } catch (_) {
        onWriteError?.call();
      }
    });
    // Accepted for writing; failures are surfaced through onWriteError.
    return true;
  }

  Future<void> flush() => _writes;
}
