import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wingstar/services/location_engine.dart';
import 'package:wingstar/state/app_store.dart';

import 'walking_integration_test.dart' show TestStepEngine, TestLocationEngine;

class PermissionLocationPlatform extends GeolocatorPlatform {
  int checks = 0, requests = 0, watches = 0;
  LocationPermission permission = LocationPermission.denied;
  final positions = StreamController<Position>.broadcast();
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async {
    checks++;
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    settings = locationSettings;
    watches++;
    return positions.stream;
  }
}

void main() {
  test(
    'iOS restores authorized fitness GPS without requesting permission again',
    () async {
      final previous = GeolocatorPlatform.instance;
      final platform = PermissionLocationPlatform()
        ..permission = LocationPermission.whileInUse;
      GeolocatorPlatform.instance = platform;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final engine = LocationEngine(browserPermissions: false);
      try {
        await engine.resumeAuthorized();
        expect(platform.requests, 0);
        final settings = platform.settings as AppleSettings;
        expect(settings.activityType, ActivityType.fitness);
        expect(settings.allowBackgroundLocationUpdates, true);
        expect(settings.showBackgroundLocationIndicator, true);
        expect(settings.pauseLocationUpdatesAutomatically, false);
        await engine.stop();
        expect(platform.positions.hasListener, false);
        platform.permission = LocationPermission.denied;
        await engine.resumeAuthorized();
        expect(platform.requests, 0);
        expect(platform.watches, 1);
        expect(engine.status, LocationStatus.permissionDenied);
      } finally {
        engine.dispose();
        await platform.positions.close();
        GeolocatorPlatform.instance = previous;
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
  test(
    'web GPS uses one watcher without a duplicate location permission request',
    () async {
      final previous = GeolocatorPlatform.instance;
      final platform = PermissionLocationPlatform();
      GeolocatorPlatform.instance = platform;
      final engine = LocationEngine(browserPermissions: true);
      try {
        await engine.start();
        expect(platform.checks, 0);
        expect(platform.requests, 0);
        expect(platform.watches, 1);
        await engine.stop();
        expect(platform.positions.hasListener, false);
        await engine.start();
        expect(platform.requests, 0);
        expect(platform.watches, 2);
        platform.positions.addError(const PermissionDeniedException('blocked'));
        await Future<void>.delayed(Duration.zero);
        expect(engine.status, LocationStatus.permissionDenied);
        expect(platform.positions.hasListener, false);
      } finally {
        engine.dispose();
        await platform.positions.close();
        GeolocatorPlatform.instance = previous;
      }
    },
  );

  test('native denied permission still prevents a GPS watcher', () async {
    final previous = GeolocatorPlatform.instance;
    final platform = PermissionLocationPlatform();
    GeolocatorPlatform.instance = platform;
    final engine = LocationEngine(browserPermissions: false);
    try {
      await engine.start();
      expect(platform.checks, 1);
      expect(platform.requests, 1);
      expect(platform.watches, 0);
      expect(engine.status, LocationStatus.permissionDenied);
    } finally {
      engine.dispose();
      await platform.positions.close();
      GeolocatorPlatform.instance = previous;
    }
  });

  test(
    'GPS and voice preferences save immediately and survive reopening on another day',
    () {
      String saved = '';
      AppStore open() => AppStore(
        stepEngine: TestStepEngine(),
        locationEngine: TestLocationEngine(),
        loadDeviceState: () => saved,
        saveDeviceState: (value) {
          saved = value;
          return true;
        },
      );
      final first = open();
      first.setRecordLocation(true);
      first.setVoiceGuidance(true);
      first.setSensitivity('high');
      // Before a debounce or dispose, the latest settings are already durable.
      final state = jsonDecode(saved) as Map<String, dynamic>;
      expect(state['recordLocation'], true);
      expect(state['voiceGuidance'], true);
      expect(state['sensitivity'], 'high');
      first.dispose();
      state['date'] = '2000-01-01';
      saved = jsonEncode(state);
      final reopened = open();
      expect(reopened.recordLocation, true);
      expect(reopened.voiceGuidance, true);
      expect(reopened.sensitivity, 'high');
      expect(
        reopened.walking,
        false,
      ); // Preferences never start sensors by themselves.
      reopened.setRecordLocation(false);
      reopened.setVoiceGuidance(false);
      reopened.dispose();
      final disabled = open();
      expect(disabled.recordLocation, false);
      expect(disabled.voiceGuidance, false);
      disabled.dispose();
    },
  );
}
