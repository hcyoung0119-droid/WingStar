import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wingstar/state/app_store.dart' as model;
import 'package:wingstar/theme/app_theme.dart';

String emotionEmoji(model.Emotion emotion) => switch (emotion) {
  model.Emotion.great => '😄',
  model.Emotion.good => '🙂',
  model.Emotion.okay => '😐',
  model.Emotion.hard => '😞',
  model.Emotion.exhausted => '😢',
};

class MindCalendar extends StatefulWidget {
  const MindCalendar({super.key, required this.store, this.now});
  final model.AppStore store;
  final DateTime Function()? now;
  @override
  State<MindCalendar> createState() => _MindCalendarState();
}

class _MindCalendarState extends State<MindCalendar>
    with WidgetsBindingObserver {
  late DateTime today;
  late DateTime month;
  late DateTime selected;
  Timer? timer;
  DateTime get deviceDate =>
      DateUtils.dateOnly((widget.now?.call() ?? DateTime.now()).toLocal());

  @override
  void initState() {
    super.initState();
    today = deviceDate;
    month = DateTime(today.year, today.month);
    selected = today;
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => syncDate());
  }

  void syncDate() {
    final next = deviceDate;
    if (DateUtils.isSameDay(today, next)) return;
    setState(() {
      if (DateUtils.isSameDay(selected, today)) {
        selected = next;
        month = DateTime(next.year, next.month);
      }
      today = next;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncDate();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void moveMonth(int delta) => setState(() {
    month = DateTime(month.year, month.month + delta);
    selected = month;
  });

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday % 7;
    final entries = widget.store.mindEntries
        .where((e) => DateUtils.isSameDay(e.date.toLocal(), selected))
        .toList();
    final journals = widget.store.journals
        .where((e) => DateUtils.isSameDay(e.date.toLocal(), selected))
        .toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '이전 달',
                onPressed: () => moveMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${month.year}년 ${month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                tooltip: '다음 달',
                onPressed: () => moveMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '휴대폰 날짜 기준',
                  style: TextStyle(color: WSColors.muted, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  today = deviceDate;
                  selected = today;
                  month = DateTime(today.year, today.month);
                }),
                child: const Text('오늘'),
              ),
            ],
          ),
          Row(
            children: [
              for (final day in ['일', '월', '화', '수', '목', '금', '토'])
                Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        color: WSColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            key: const Key('mind-month-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((offset + days + 6) ~/ 7) * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              mainAxisExtent: 54,
            ),
            itemBuilder: (_, index) {
              final day = index - offset + 1;
              if (day < 1 || day > days) return const SizedBox.shrink();
              final date = DateTime(month.year, month.month, day);
              final isToday = DateUtils.isSameDay(today, date);
              final isSelected = DateUtils.isSameDay(selected, date);
              final emotions = widget.store.mindEntries.where(
                (e) => DateUtils.isSameDay(e.date.toLocal(), date),
              );
              final hasJournal = widget.store.journals.any(
                (e) => DateUtils.isSameDay(e.date.toLocal(), date),
              );
              return Semantics(
                label:
                    '${date.year}년 ${date.month}월 ${date.day}일${isToday ? ', 오늘' : ''}',
                selected: isSelected,
                button: true,
                child: InkWell(
                  key: ValueKey('mind-day-${date.year}-${date.month}-$day'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => selected = date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? WSColors.primarySoft
                          : WSColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday ? WSColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isToday || isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        if (emotions.isNotEmpty)
                          Text(
                            emotionEmoji(emotions.first.emotion),
                            style: const TextStyle(fontSize: 15),
                          )
                        else if (hasJournal)
                          const Icon(
                            Icons.edit_note,
                            size: 17,
                            color: WSColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '${selected.month}월 ${selected.day}일 기록',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty && journals.isEmpty)
            const Text(
              '이날은 아직 기록이 없어요.',
              style: TextStyle(color: WSColors.muted),
            ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${emotionEmoji(entry.emotion)} ${entry.body.isEmpty ? '감정을 기록했어요' : entry.body}',
              ),
            ),
          for (final journal in journals)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journal.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    journal.content,
                    style: const TextStyle(color: WSColors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
