import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wingstar/services/platform_bridge.dart' as bridge;
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/profile_card.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController name, job, bio;
  final form = GlobalKey<FormState>();
  late String photo, color, badge;
  bool picking = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final store = widget.store;
    name = TextEditingController(text: store.name);
    job = TextEditingController(text: store.job);
    bio = TextEditingController(text: store.profileBio);
    photo = store.profilePhoto;
    color = store.profileColor;
    badge = store.profileBadge;
  }

  @override
  void dispose() {
    name.dispose();
    job.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    if (picking) return;
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final result =
          jsonDecode(await bridge.pickProfilePhoto()) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        if (result['photo'] is String) photo = result['photo'];
        error = result['error'] as String?;
      });
    } catch (_) {
      if (mounted) setState(() => error = '사진을 가져오지 못했어요. 다시 선택해 주세요.');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  void save() {
    if (!form.currentState!.validate()) return;
    final saved = widget.store.updateProfile(
      displayName: name.text,
      occupation: job.text,
      bio: bio.text,
      photo: photo,
      color: color,
      badge: badge,
    );
    if (!saved) {
      setState(
        () => error = '프로필을 저장하지 못했어요. 저장 공간을 확인하거나 사진을 지운 뒤 다시 시도해 주세요.',
      );
      return;
    }
    widget.store.showToast('나만의 프로필을 저장했어요');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('프로필 꾸미기'),
      actions: [
        TextButton(
          key: const Key('save-profile'),
          onPressed: picking ? null : save,
          child: const Text('저장'),
        ),
      ],
    ),
    body: SkyBackground(
      dark: widget.store.darkMode,
      child: SafeArea(
        top: false,
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ProfileCard(
                name: name.text,
                job: job.text,
                bio: bio.text,
                photo: photo,
                color: color,
                badge: badge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    key: const Key('pick-profile-photo'),
                    onPressed: picking || !kIsWeb ? null : pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      picking
                          ? '사진 준비 중…'
                          : photo.isEmpty
                          ? '사진 추가'
                          : '사진 변경',
                    ),
                  ),
                  if (photo.isNotEmpty)
                    TextButton(
                      onPressed: picking
                          ? null
                          : () => setState(() => photo = ''),
                      child: const Text('사진 삭제'),
                    ),
                ],
              ),
              const Text(
                '사진은 가운데를 정사각형으로 맞춰 이 브라우저에 저장해요. 공개하거나 서버로 보내지 않습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: WSColors.muted,
                  height: 1.5,
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(color: WSColors.destructive),
                  ),
                ),
              const SizedBox(height: 22),
              TextFormField(
                key: const Key('profile-name'),
                controller: name,
                maxLength: 24,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '닉네임을 입력해 주세요.' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: job,
                maxLength: 30,
                decoration: const InputDecoration(labelText: '나의 일상 · 하는 일'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('profile-bio'),
                controller: bio,
                maxLength: 80,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '한 줄 소개',
                  hintText: '나를 표현하는 말을 적어보세요.',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                '나의 배경색',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in ProfileStyles.colors.entries)
                    ChoiceChip(
                      key: Key('profile-color-${entry.key}'),
                      selected: color == entry.key,
                      avatar: CircleAvatar(
                        backgroundColor: entry.value.$2,
                        radius: 9,
                      ),
                      label: Text(entry.value.$1),
                      onSelected: (_) => setState(() => color = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                '나를 닮은 포인트',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in ProfileStyles.badges.entries)
                    ChoiceChip(
                      selected: badge == entry.key,
                      avatar: Icon(entry.value.$2, size: 18),
                      label: Text(entry.value.$1),
                      onSelected: (_) => setState(() => badge = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: picking ? null : save,
                child: const Text('프로필 저장'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
