import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key, required this.store});
  final AppStore store;

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  final nameCtrl = TextEditingController();
  String job = AppStore.jobs.first;
  int step = 0;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkyBackground(
      hero: true,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: WSColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: WSColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'WingStar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '매일 조금씩, 몸과 마음을 돌보는 시간',
              textAlign: TextAlign.center,
              style: TextStyle(color: WSColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 28),
            if (step == 0) ...[
              Text(
                '만나서 반가워요',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이름을 알려주시면 맞춤 케어를 준비해드릴게요.',
                style: TextStyle(color: WSColors.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이름',
                      style: TextStyle(color: WSColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(hintText: '이름을 입력해주세요'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: WSColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('🎁  시작 즉시 웰컴 보너스 50코인이 준비되어 있어요'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => setState(() => step = 1),
                child: const Text(
                  '계속하기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ] else ...[
              Text(
                '어떤 일을 하고 계신가요?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '직군에 맞는 맞춤 케어 서비스를 준비해드릴게요.',
                style: TextStyle(color: WSColors.muted),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final j in AppStore.jobs)
                    ChoiceChip(
                      label: Text(j),
                      selected: job == j,
                      onSelected: (_) => setState(() => job = j),
                      selectedColor: WSColors.primarySoft,
                      labelStyle: TextStyle(
                        color: job == j ? WSColors.primaryDark : WSColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () =>
                    widget.store.completeBoarding(nameCtrl.text, job),
                child: const Text(
                  '시작하기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              '걷기 · 명상 · 플로깅 · ESG, 나와 지구를 돌보는 일상',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: WSColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
