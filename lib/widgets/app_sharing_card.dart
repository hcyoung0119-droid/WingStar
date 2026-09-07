import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/platform_bridge.dart' as bridge;
import '../theme/app_theme.dart';

const wingstarPublicUrl = 'https://wingstar-care.use-loing-ai.chatgpt.site/';

class AppSharingCard extends StatelessWidget {
  const AppSharingCard({super.key});

  Future<void> _share(BuildContext context, {bool copy = false}) async {
    final result = await (copy ? bridge.copyAppLink() : bridge.shareAppLink());
    if (!context.mounted || result == 'cancelled' || result == 'shared') return;
    if (result == 'copied') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱 링크를 복사했어요. 카카오톡 대화창에 붙여넣어 주세요.')),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('링크 복사'),
          content: const SelectableText(wingstarPublicUrl),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'WingStar를 함께 사용해요',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
            ),
            onPressed: () => _share(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('카카오톡으로 공유'),
          ),
          const Text(
            '공유창에서 카카오톡을 선택하세요. 개인 기록은 공유되지 않아요.',
            style: TextStyle(fontSize: 12, color: WSColors.muted, height: 1.5),
          ),
          TextButton.icon(
            onPressed: () => _share(context, copy: true),
            icon: const Icon(Icons.link),
            label: const Text('앱 링크 복사'),
          ),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('아이폰 홈 화면에 추가'),
                content: const SingleChildScrollView(
                  child: Text(
                    '1. 이 링크를 Safari에서 여세요.\n2. Safari의 공유 버튼을 누르세요.\n3. ‘홈 화면에 추가’를 선택하세요.\n4. ‘웹 앱으로 열기’를 켜고 추가하세요.\n\n카카오톡 안에서 열었다면 메뉴에서 Safari로 열기를 선택하세요.\n\n동작·GPS 측정은 앱 화면을 열어둔 동안만 사용할 수 있어요. 건강 앱 걸음 수와는 연동되지 않습니다.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.add_to_home_screen),
            label: const Text('홈 화면 추가 방법'),
          ),
          const Text(
            '이 기기의 브라우저에 기록이 저장돼요. Safari와 홈 화면 앱은 저장 공간이 다를 수 있어요.',
            style: TextStyle(fontSize: 12, color: WSColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
