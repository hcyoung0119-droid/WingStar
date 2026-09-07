import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { idle, running, permissionDenied, serviceOff, error }

class LocationEngine extends ChangeNotifier {
  StreamSubscription<Position>? _subscription;
  Position? _lastPosition;
  bool _disposed = false;

  LocationStatus status = LocationStatus.idle;
  double distanceMeters = 0;
  String message = '거리 기록 대기 중';

  Future<void> start() async {
    await stop(resetStatusOnly: true);
    if (_disposed) return;
    distanceMeters = 0;
    _lastPosition = null;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (_disposed) return;
      if (!serviceEnabled) {
        status = LocationStatus.serviceOff;
        message = '위치 서비스가 꺼져 있어 거리 측정은 생략합니다.';
        _safeNotify();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (_disposed) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (_disposed) return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        status = LocationStatus.permissionDenied;
        message = '위치 권한이 없어 거리 측정은 생략합니다.';
        _safeNotify();
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      status = LocationStatus.running;
      message = '거리 측정 중';
      _safeNotify();

      _subscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onPosition,
        onError: (_) {
          status = LocationStatus.error;
          message = '위치 데이터를 읽는 중 오류가 발생했습니다.';
          _safeNotify();
        },
      );
    } catch (_) {
      status = LocationStatus.error;
      message = '이 기기에서는 위치 측정을 시작하지 못했습니다.';
      _safeNotify();
    }
  }

  void _onPosition(Position position) {
    if (position.accuracy > 60) return;

    if (_lastPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      if (delta >= 2 && delta <= 150) {
        distanceMeters += delta;
      }
    }

    _lastPosition = position;
    _safeNotify();
  }

  Future<void> stop({bool resetStatusOnly = false}) async {
    await _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
    if (!resetStatusOnly) {
      status = LocationStatus.idle;
      message = '거리 기록 종료';
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
