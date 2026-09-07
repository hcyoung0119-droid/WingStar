import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingstar/screens/my_screen.dart';
import 'package:wingstar/screens/profile_editor_screen.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'walking_integration_test.dart' show TestStepEngine, TestLocationEngine;

void main() {
  test(
    'Profile photo and decorations persist, and deleting a photo survives reopening',
    () {
      var saved = '';
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
      expect(
        first.updateProfile(
          displayName: '새싹 🌿',
          occupation: '산책하는 사람',
          bio: '나만의 속도로 걸어요.',
          photo: 'data:image/jpeg;base64,/9j/',
          color: 'mint',
          badge: 'sparkle',
        ),
        true,
      );
      expect(jsonDecode(saved)['profilePhoto'], 'data:image/jpeg;base64,/9j/');
      first.dispose();
      final next = open();
      expect(next.name, '새싹 🌿');
      expect(next.profileBio, '나만의 속도로 걸어요.');
      expect(next.profileColor, 'mint');
      expect(next.profileBadge, 'sparkle');
      expect(next.profilePhoto, 'data:image/jpeg;base64,/9j/');
      next.updateProfile(
        displayName: next.name,
        occupation: next.job,
        bio: next.profileBio,
        photo: '',
        color: next.profileColor,
        badge: next.profileBadge,
      );
      next.dispose();
      final removed = open();
      expect(removed.profilePhoto, '');
      removed.dispose();
    },
  );

  test(
    'Failed profile writes and invalid input leave the previous profile intact',
    () {
      final store = AppStore(
        stepEngine: TestStepEngine(),
        locationEngine: TestLocationEngine(),
        saveDeviceState: (_) => false,
      )..name = '기존 이름';
      expect(
        store.updateProfile(
          displayName: '새 이름',
          occupation: '',
          bio: '',
          photo: '',
          color: 'sky',
          badge: 'leaf',
        ),
        false,
      );
      expect(store.name, '기존 이름');
      expect(
        store.updateProfile(
          displayName: '',
          occupation: '',
          bio: '',
          photo: '',
          color: 'sky',
          badge: 'leaf',
        ),
        false,
      );
      expect(
        store.updateProfile(
          displayName: '새 이름',
          occupation: '',
          bio: '',
          photo: 'https://example.com/photo.jpg',
          color: 'sky',
          badge: 'leaf',
        ),
        false,
      );
      expect(store.name, '기존 이름');
      store.dispose();
    },
  );

  testWidgets(
    'Profile editor previews a draft and applies only on save on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = AppStore(
        stepEngine: TestStepEngine(),
        locationEngine: TestLocationEngine(),
      )..name = '산책 친구';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AnimatedBuilder(
            animation: store,
            builder: (_, _) => MyScreen(store: store),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('edit-profile')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditorScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('profile-name')),
        '새로운 산책 친구',
      );
      await tester.enterText(
        find.byKey(const Key('profile-bio')),
        '오늘도 나를 돌보는 한 걸음',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('profile-color-lavender')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('profile-color-lavender')));
      await tester.pump();
      expect(store.name, '산책 친구');
      expect(store.profileColor, 'sky');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pumpAndSettle();
      expect(store.name, '새로운 산책 친구');
      expect(store.profileColor, 'lavender');
      expect(find.byType(ProfileEditorScreen), findsNothing);
      expect(find.text('오늘도 나를 돌보는 한 걸음'), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit-profile')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('profile-name')),
        '저장하지 않은 이름',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(store.name, '새로운 산책 친구');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
