import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationStatus { idle, running, permissionDenied, serviceOff, error }

class LocationEngine extends ChangeNotifier {
  LocationEngine({bool browserPermissions = kIsWeb})
    : _browserPermissions = browserPermissions;

  final bool _browserPermissions;
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

      // On the web, watchPosition checks the existing browser grant itself.
      // requestPermission also performs getCurrentPosition, causing two location
      // requests (and potentially two prompts for one-time Safari grants).
      if (!_browserPermissions) {
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
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      status = LocationStatus.running;
      message = 'GPS 연결 중';
      _safeNotify();

      _subscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            _onPosition,
            onError: (Object error) {
              final denied = error is PermissionDeniedException;
              status = denied
                  ? LocationStatus.permissionDenied
                  : LocationStatus.error;
              message = denied
                  ? '위치 권한이 꺼져 있어요. Safari의 이 웹사이트 설정에서 위치를 허용해 주세요.'
                  : '위치 데이터를 읽는 중 오류가 발생했습니다.';
              _safeNotify();
            },
            cancelOnError: true,
          );
    } catch (_) {
      status = LocationStatus.error;
      message = '이 기기에서는 위치 측정을 시작하지 못했습니다.';
      _safeNotify();
    }
  }

  void _onPosition(Position position) {
    status = LocationStatus.running;
    message = '거리 측정 중';
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
