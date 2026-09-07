import 'dart:async';

import 'package:flutter/services.dart';

/// Cumulative Core Motion snapshots, never accelerometer estimates.
class IosPedometer {
  static const methods = MethodChannel('wingstar/walking');
  static const events = EventChannel('wingstar/walking/events');
  static int _sequence = 0;

  StreamSubscription<dynamic>? _subscription;
  String? _token;
  void Function(Map<String, dynamic>)? onSnapshot;
  void Function(Object)? onError;
  DateTime? startedAt;

  Future<void> start({DateTime? from, bool requestPermission = true}) async {
    await stop();
    startedAt = from ?? DateTime.now();
    final token = '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    _token = token;
    _subscription = events.receiveBroadcastStream().listen(
      (event) => _receive(event, token),
      onError: (Object error) {
        if (_token == token) onError?.call(error);
      },
    );
    final snapshot = await methods.invokeMapMethod<String, dynamic>('start', {
      'token': token,
      'fromMs': startedAt!.millisecondsSinceEpoch,
      'requestPermission': requestPermission,
    });
    _receive(snapshot, token);
  }

  Future<void> refresh() async {
    final token = _token;
    if (token == null) return;
    final snapshot = await methods.invokeMapMethod<String, dynamic>(
      'snapshot',
      {'token': token},
    );
    _receive(snapshot, token);
  }

  void _receive(dynamic value, String token) {
    if (_token != token || value is! Map || value['token'] != token) return;
    onSnapshot?.call(Map<String, dynamic>.from(value));
  }

  Future<void> stop() async {
    final token = _token;
    _token = null;
    startedAt = null;
    await _subscription?.cancel();
    _subscription = null;
    if (token != null) {
      await methods.invokeMethod<void>('stop', {'token': token});
    }
  }
}
