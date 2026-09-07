import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'platform_bridge.dart' as bridge;

class SocialStore extends ChangeNotifier {
  SocialStore() {
    refreshSnapshot();
    if (kIsWeb) {
      _poll = Timer.periodic(
        const Duration(seconds: 1),
        (_) => refreshSnapshot(),
      );
    }
  }
  Timer? _poll;
  String _snapshot = '';
  Map<String, dynamic> data = {};
  bool lastActionCreated = false;
  bool get authenticated => data['authenticated'] == true;
  bool get configured => data['configured'] == true;
  bool get busy => data['busy'] == true;
  Map<String, dynamic> get me =>
      (data['me'] as Map?)?.cast<String, dynamic>() ?? {};
  List<Map<String, dynamic>> list(String key) => (data[key] as List? ?? [])
      .whereType<Map>()
      .map((v) => v.cast<String, dynamic>())
      .toList();
  void refreshSnapshot() {
    try {
      final raw = bridge.socialState();
      if (raw == _snapshot) return;
      _snapshot = raw;
      data = jsonDecode(raw);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> action(
    String name, [
    Map<String, dynamic> payload = const {},
  ]) async {
    lastActionCreated = false;
    final pending = bridge.socialAction(name, payload);
    refreshSnapshot();
    try {
      final result = jsonDecode(await pending);
      lastActionCreated = result['created'] == true;
      return result['ok'] == true;
    } finally {
      refreshSnapshot();
    }
  }

  void login() => bridge.socialLogin();
  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
