import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';
import 'package:wingstar/widgets/profile_card.dart';

class SocialIdentityCard extends StatelessWidget {
  const SocialIdentityCard({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final social = store.social;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 WingStar 아이디',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (social.authenticated)
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    social.me['id'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: WSColors.primaryDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '아이디 복사',
                  onPressed: social.busy ? null : () => social.action('copy'),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                ),
              ],
            )
          else
            const Text(
              '구글 계정을 연결하면 고유 아이디와 친구 목록을 사용할 수 있어요.',
              style: TextStyle(
                fontSize: 13,
                color: WSColors.muted,
                height: 1.5,
              ),
            ),
          TextButton.icon(
            onPressed: store.openRankings,
            icon: const Icon(Icons.people_outline_rounded),
            label: const Text('친구 · 랭킹으로 이동'),
          ),
          TextButton(
            onPressed: () => social.action('privacy'),
            child: const Text('개인정보 안내'),
          ),
        ],
      ),
    );
  }
}

class RankingPanel extends StatefulWidget {
  const RankingPanel({super.key, required this.store});
  final AppStore store;
  @override
  State<RankingPanel> createState() => _RankingPanelState();
}

class _RankingPanelState extends State<RankingPanel> {
  final search = TextEditingController();
  Timer? refreshTimer;
  AppStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    unawaited(store.social.action('refresh'));
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (store.tab == 2 && store.recordsRanking && !store.social.busy) {
        unawaited(store.social.action('refresh'));
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> editPublicProfile() async {
    final name = TextEditingController(
      text: store.social.me['nickname'] ?? store.name,
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구에게 보이는 프로필'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              maxLength: 24,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const Text(
              '닉네임과 마이에서 고른 배경색·장식을 반영해요. 사진과 한 줄 소개는 이 기기에만 남습니다.',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await store.social.action('profile', {
        'nickname': name.text,
        'accent': store.profileColor,
        'badge': store.profileBadge,
        'publicRanking': store.social.me['publicRanking'] == true,
      });
    }
    name.dispose();
  }

  Future<void> removeFriend(Map<String, dynamic> friend) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${friend['nickname']}님과 친구 연결을 해제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('연결 해제'),
          ),
        ],
      ),
    );
    if (remove == true && mounted) {
      await store.social.action('remove', {'id': friend['id']});
    }
  }

  Widget avatar(Map<String, dynamic> person) {
    final colors =
        ProfileStyles.colors[person['accent']] ?? ProfileStyles.colors['sky']!;
    final badge =
        ProfileStyles.badges[person['badge']] ?? ProfileStyles.badges['leaf']!;
    return CircleAvatar(
      backgroundColor: colors.$2,
      child: Icon(badge.$2, color: Colors.white, size: 20),
    );
  }

  Widget personRow(Map<String, dynamic> person, {required Widget action}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            avatar(person),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person['nickname'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    person['id'] ?? '',
                    style: const TextStyle(fontSize: 10, color: WSColors.muted),
                  ),
                ],
              ),
            ),
            action,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store.social,
    builder: (context, _) {
      final social = store.social, me = social.me, data = social.data;
      final incoming = social.list('incoming'),
          outgoing = social.list('outgoing'),
          friends = social.list('friends'),
          ranking = social.list('ranking');
      final result = data['search'] as Map?;
      final rawMatches = result?['results'];
      final matches =
          (rawMatches is List
                  ? rawMatches
                  : result?['user'] is Map
                  ? [result]
                  : <dynamic>[])
              .whereType<Map>()
              .where((match) => match['user'] is Map)
              .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '함께 걷는 이번 주',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: '랭킹 새로고침',
                onPressed: social.busy ? null : () => social.action('refresh'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (data['loading'] == true || social.busy)
            const LinearProgressIndicator(),
          if ((data['notice'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                data['notice'],
                style: const TextStyle(
                  color: WSColors.primaryDark,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          if (!social.authenticated)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 38,
                    color: WSColors.primaryDark,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '닉네임으로 친구와 연결',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '같은 구글 계정이면 휴대폰을 바꿔도 같은 아이디와 친구 목록을 사용할 수 있어요.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: social.configured ? social.login : null,
                    icon: const Icon(Icons.login),
                    label: Text(
                      social.configured ? '구글 계정으로 로그인' : '구글 로그인 연결 준비 중',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (social.configured && data['testing'] == true)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '현재 구글 로그인은 등록된 테스트 계정부터 이용할 수 있어요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: WSColors.primaryDark,
                        ),
                      ),
                    ),
                  Text(
                    social.configured
                        ? '친구 요청을 수락하면 서로 주간 걸음 기록을 볼 수 있어요. 전체 랭킹 참여는 직접 선택할 수 있습니다.'
                        : '계정 연결이 준비되면 고유 아이디 발급·친구 추가·랭킹을 사용할 수 있어요.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: WSColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            GlassCard(
              color: WSColors.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          me['nickname'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '친구 프로필 수정',
                        onPressed: social.busy ? null : editPublicProfile,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          me['id'] ?? '',
                          style: const TextStyle(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '아이디 복사',
                        onPressed: social.busy
                            ? null
                            : () => social.action('copy'),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      '전체 랭킹에 참여',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      '닉네임·아이디·주간 걸음 수가 참여자에게 보여요.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: me['publicRanking'] == true,
                    onChanged: social.busy
                        ? null
                        : (value) => social.action('profile', {
                            'nickname': me['nickname'],
                            'accent': me['accent'],
                            'badge': me['badge'],
                            'publicRanking': value,
                          }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '닉네임으로 친구 찾기',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: search,
                    textCapitalization: TextCapitalization.none,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    maxLength: 24,
                    decoration: InputDecoration(
                      hintText: '닉네임 일부만 입력해도 좋아요',
                      labelText: '친구 닉네임',
                      helperText: '기존 아이디로도 검색할 수 있어요.',
                      counterText: '',
                      suffixIcon: IconButton(
                        tooltip: '친구 검색',
                        onPressed: social.busy
                            ? null
                            : () => social.action('search', {
                                'query': search.text,
                              }),
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    onSubmitted: social.busy
                        ? null
                        : (_) =>
                              social.action('search', {'query': search.text}),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      matches.isEmpty
                          ? '검색 결과가 없어요. 다른 닉네임으로 찾아보세요.'
                          : result['hasMore'] == true
                          ? '결과가 많아 20명까지 보여드려요. 닉네임을 더 입력해 보세요.'
                          : '‘${result['query'] ?? search.text}’ 검색 결과 ${matches.length}명 · 프로필을 확인해 주세요.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: WSColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  for (final match in matches)
                    personRow(
                      Map<String, dynamic>.from(match['user']),
                      action: match['relationship'] == 'none'
                          ? TextButton(
                              onPressed: social.busy
                                  ? null
                                  : () => social.action('request', {
                                      'id': match['user']['id'],
                                    }),
                              child: const Text('친구 요청'),
                            )
                          : match['relationship'] == 'incoming'
                          ? TextButton(
                              onPressed: social.busy
                                  ? null
                                  : () => social.action('accept', {
                                      'id': match['user']['id'],
                                    }),
                              child: const Text('수락'),
                            )
                          : Text(
                              match['relationship'] == 'self'
                                  ? '나'
                                  : match['relationship'] == 'friend'
                                  ? '친구'
                                  : '요청 보냄',
                              style: const TextStyle(
                                fontSize: 12,
                                color: WSColors.muted,
                              ),
                            ),
                    ),
                ],
              ),
            ),
            if (incoming.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '받은 친구 요청 ${incoming.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    for (final person in incoming)
                      personRow(
                        person,
                        action: Wrap(
                          children: [
                            IconButton(
                              tooltip: '요청 수락',
                              onPressed: social.busy
                                  ? null
                                  : () => social.action('accept', {
                                      'id': person['id'],
                                    }),
                              icon: const Icon(
                                Icons.check,
                                color: WSColors.success,
                              ),
                            ),
                            IconButton(
                              tooltip: '요청 거절',
                              onPressed: social.busy
                                  ? null
                                  : () => social.action('decline', {
                                      'id': person['id'],
                                    }),
                              icon: const Icon(
                                Icons.close,
                                color: WSColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (outgoing.isNotEmpty) ...[
              const SizedBox(height: 14),
              GlassCard(
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '보낸 친구 요청 ${outgoing.length}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  children: [
                    for (final person in outgoing)
                      personRow(
                        person,
                        action: TextButton(
                          onPressed: social.busy
                              ? null
                              : () => social.action('remove', {
                                  'id': person['id'],
                                }),
                          child: const Text('취소'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'friends', label: Text('친구 랭킹')),
                ButtonSegment(value: 'all', label: Text('전체 랭킹')),
              ],
              selected: {data['scope'] as String? ?? 'friends'},
              onSelectionChanged: social.busy
                  ? null
                  : (values) => social.action('scope', {'scope': values.first}),
            ),
            const SizedBox(height: 10),
            Text(
              '${data['week'] ?? ''}부터 · 월요일 00시, 한국 시간 기준',
              style: const TextStyle(fontSize: 11, color: WSColors.muted),
            ),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  if (ranking.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '아직 랭킹 참여자가 없어요.',
                        style: TextStyle(color: WSColors.muted),
                      ),
                    ),
                  for (final row in ranking)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: row['rank'] == 1 && row['steps'] > 0
                            ? WSColors.sunny
                            : WSColors.secondary,
                        child: Text(
                          row['steps'] == 0 ? '–' : '${row['rank']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: WSColors.navy,
                          ),
                        ),
                      ),
                      title: Text(
                        '${row['nickname']}${row['public_id'] == me['id'] ? ' · 나' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        row['public_id'],
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        '${row['steps']}걸음',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: WSColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (data['scope'] == 'all' && me['publicRanking'] != true)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '전체 랭킹 참여를 켜면 내 순위도 표시돼요.',
                  style: TextStyle(fontSize: 12, color: WSColors.muted),
                ),
              ),
            if (data['myRank'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '내 주간 기록 · ${data['myRank']['steps']}걸음',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '로그인 후 걷기 중에 측정한 걸음을 모아요. 순위는 함께 걷는 즐거움을 위한 기록이며 리워드와는 별개예요.${(data['pendingSteps'] as num? ?? 0) > 0 ? '\n${data['pendingSteps']}걸음 동기화 대기 중' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  color: WSColors.muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '연결된 친구 ${friends.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if ((data['receivedCheers'] as num? ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '오늘 친구들이 보낸 응원 ${data['receivedCheers']}개',
                        style: const TextStyle(
                          color: WSColors.primaryDark,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        '닉네임으로 친구를 찾아 첫 요청을 보내보세요.',
                        style: TextStyle(fontSize: 13, color: WSColors.muted),
                      ),
                    ),
                  for (final person in friends)
                    personRow(
                      person,
                      action: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '친구 응원',
                            onPressed: social.busy
                                ? null
                                : () async {
                                    if (await social.action('cheer', {
                                          'id': person['id'],
                                        }) &&
                                        social.lastActionCreated) {
                                      store.cheerFriend(person['nickname']);
                                    }
                                  },
                            icon: const Icon(
                              Icons.favorite_border,
                              color: WSColors.primaryDark,
                            ),
                          ),
                          IconButton(
                            tooltip: '친구 연결 해제',
                            onPressed: social.busy
                                ? null
                                : () => removeFriend(person),
                            icon: const Icon(
                              Icons.person_remove_outlined,
                              size: 20,
                              color: WSColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: social.busy ? null : () => social.action('logout'),
              child: const Text('구글 계정 로그아웃'),
            ),
          ],
        ],
      );
    },
  );
}
