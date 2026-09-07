import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wingstar/state/app_store.dart';
import 'package:wingstar/theme/app_theme.dart';

/// 기록 탭용 세부 그래프 패널 (주간 / 월간)
class DetailChartsPanel extends StatefulWidget {
  const DetailChartsPanel({super.key, required this.store});
  final AppStore store;

  @override
  State<DetailChartsPanel> createState() => _DetailChartsPanelState();
}

class _DetailChartsPanelState extends State<DetailChartsPanel> {
  int period = 0; // 0 주간 · 1 월간
  int focus = 0; // 0 걸음 · 1 감정 · 2 코인 · 3 ESG · 4 스트레스

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                '세부 그래프',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            _Seg(
              labels: const ['주간', '월간'],
              index: period,
              onChanged: (i) => setState(() => period = i),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '걸음 · 감정 · 코인 · ESG · 스트레스를 한눈에 확인해요',
          style: TextStyle(color: WSColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final e in [
                (0, '걸음', Icons.directions_walk_rounded),
                (1, '감정', Icons.favorite_rounded),
                (2, '코인', Icons.monetization_on_rounded),
                (3, 'ESG', Icons.eco_rounded),
                (4, '스트레스', Icons.bolt_rounded),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(e.$3, size: 14),
                        const SizedBox(width: 4),
                        Text(e.$2),
                      ],
                    ),
                    selected: focus == e.$1,
                    onSelected: (_) => setState(() => focus = e.$1),
                    selectedColor: WSColors.primarySoft,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: focus == e.$1
                          ? WSColors.primaryDark
                          : WSColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SummaryStatsRow(items: _stats(store)),
        const SizedBox(height: 10),
        GlassCard(
          child: SizedBox(
            height: 220,
            child: period == 0
                ? _buildWeekChart(store)
                : _buildMonthChart(store),
          ),
        ),
        if (focus == 3) ...[
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESG 레이더',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 200, child: EsgRadarChart(store: store)),
              ],
            ),
          ),
        ],
        if (focus == 1) ...[
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '감정 분포 (최근 기록)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SizedBox(height: 160, child: MoodPieChart(store: store)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<(String, String)> _stats(AppStore store) {
    switch (focus) {
      case 1:
        return [
          ('평균 감정', store.weeklyMoodAvg.toStringAsFixed(1)),
          ('일기', '${store.journals.length}'),
          ('기록 수', '${store.mindEntries.length}'),
        ];
      case 2:
        return [
          ('주간 적립', '${store.weeklyCoinsEarned}'),
          ('잔액', '${store.wsc}'),
        ];
      case 3:
        return [
          ('ESG', '${store.esgScore}'),
          ('E', '${store.envScore}'),
          ('S', '${store.socialScore}'),
          ('G', '${store.govScore}'),
        ];
      case 4:
        return [
          ('오늘', '${store.stress}'),
          ('수면', '${store.sleepHours}h'),
          ('호흡', '${store.breathingSessions}'),
        ];
      default:
        final monthlyTotal = store.monthlyStepsSeries
            .fold<double>(0, (a, b) => a + b)
            .round();
        return [
          (
            period == 0 ? '주간 합계' : '28일 합계',
            NumberFormat(
              '#,###',
            ).format(period == 0 ? store.weeklyStepsTotal : monthlyTotal),
          ),
          (
            '일평균',
            NumberFormat('#,###').format(
              period == 0
                  ? store.weeklyStepsAvg.round()
                  : (monthlyTotal / 28).round(),
            ),
          ),
          ('목표', NumberFormat('#,###').format(store.stepGoal)),
        ];
    }
  }

  Widget _buildWeekChart(AppStore store) {
    switch (focus) {
      case 1:
        return SoftLineChart(
          values: store.weeklyMoodSeries,
          labels: store.weekLabels,
          color: WSColors.lavender,
          minY: 0,
          maxY: 5,
          unit: '점',
        );
      case 2:
        return SoftBarChart(
          values: store.weeklyCoinSeries,
          labels: store.weekLabels,
          color: WSColors.coin,
          unit: '',
        );
      case 3:
        return SoftLineChart(
          values: store.weeklyEsgSeries,
          labels: store.weekLabels,
          color: const Color(0xFF3CBF8A),
          minY: 0,
          maxY: 100,
          unit: '점',
        );
      case 4:
        return SoftLineChart(
          values: store.weeklyStressSeries,
          labels: store.weekLabels,
          color: WSColors.stress,
          minY: 0,
          maxY: 100,
          unit: '',
        );
      default:
        return SoftBarChart(
          values: store.weeklyStepsSeries,
          labels: store.weekLabels,
          color: WSColors.primary,
          unit: '걸음',
        );
    }
  }

  Widget _buildMonthChart(AppStore store) {
    if (focus == 0) {
      return SoftBarChart(
        values: store.monthlyStepsSeries,
        labels: store.monthDayLabels,
        color: WSColors.primary,
        unit: '걸음',
        sparseLabels: true,
      );
    }
    final week = switch (focus) {
      1 => store.weeklyMoodSeries,
      2 => store.weeklyCoinSeries,
      3 => store.weeklyEsgSeries,
      4 => store.weeklyStressSeries,
      _ => store.weeklyStepsSeries,
    };
    final expanded = List<double>.generate(28, (i) {
      final a = week[i % 7];
      final b = week[(i + 1) % 7];
      return a + (b - a) * ((i % 7) / 7);
    });
    return SoftLineChart(
      values: expanded,
      labels: store.monthDayLabels,
      color: switch (focus) {
        1 => WSColors.lavender,
        2 => WSColors.coin,
        3 => const Color(0xFF3CBF8A),
        4 => WSColors.stress,
        _ => WSColors.primary,
      },
      minY: 0,
      maxY: focus == 1 ? 5 : null,
      unit: focus == 2 ? '' : '점',
      sparseLabels: true,
    );
  }
}

class SummaryStatsRow extends StatelessWidget {
  const SummaryStatsRow({super.key, required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                children: [
                  Text(
                    items[i].$1,
                    style: const TextStyle(fontSize: 11, color: WSColors.muted),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      items[i].$2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SoftBarChart extends StatelessWidget {
  const SoftBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.unit = '',
    this.sparseLabels = false,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final String unit;
  final bool sparseLabels;

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = (maxV * 1.2).clamp(1.0, double.infinity).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => WSColors.foreground,
            getTooltipItem: (group, gIdx, rod, rIdx) {
              final label = labels[group.x.toInt()];
              final v = rod.toY;
              final text = unit == '걸음' || unit.isEmpty
                  ? '${NumberFormat('#,###').format(v.round())}$unit'
                  : '${v.toStringAsFixed(1)}$unit';
              return BarTooltipItem(
                '$label\n$text',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 4,
              getTitlesWidget: (v, meta) => Text(
                v >= 1000
                    ? '${(v / 1000).toStringAsFixed(1)}k'
                    : v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: WSColors.muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                if (sparseLabels && i % 4 != 0 && i != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 10, color: WSColors.muted),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: WSColors.border.withValues(alpha: 0.8),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: sparseLabels ? 4 : 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color.withValues(alpha: 0.55), color],
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 450),
    );
  }
}

class SoftLineChart extends StatelessWidget {
  const SoftLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.minY,
    this.maxY,
    this.unit = '',
    this.sparseLabels = false,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double? minY;
  final double? maxY;
  final String unit;
  final bool sparseLabels;

  @override
  Widget build(BuildContext context) {
    final lo = minY ?? 0;
    final hiRaw =
        maxY ?? values.fold<double>(0, (a, b) => a > b ? a : b) * 1.15;
    final hi = hiRaw <= lo ? lo + 1 : hiRaw;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: lo,
        maxY: hi,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => WSColors.foreground,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt().clamp(0, labels.length - 1);
              final text = unit.isEmpty
                  ? s.y.toStringAsFixed(1)
                  : '${s.y.toStringAsFixed(1)}$unit';
              return LineTooltipItem(
                '${labels[i]}\n$text',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (hi - lo) / 4,
              getTitlesWidget: (v, meta) => Text(
                v.toStringAsFixed(v >= 10 ? 0 : 1),
                style: const TextStyle(fontSize: 10, color: WSColors.muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                if (sparseLabels && i % 4 != 0 && i != labels.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 10, color: WSColors.muted),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (hi - lo) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: WSColors.border.withValues(alpha: 0.8),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: !sparseLabels,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 450),
    );
  }
}

class EsgRadarChart extends StatelessWidget {
  const EsgRadarChart({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [
              RadarEntry(value: store.envScore.toDouble()),
              RadarEntry(value: store.socialScore.toDouble()),
              RadarEntry(value: store.govScore.toDouble()),
            ],
            fillColor: const Color(0xFF3CBF8A).withValues(alpha: 0.25),
            borderColor: const Color(0xFF3CBF8A),
            entryRadius: 3,
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: WSColors.border),
        titlePositionPercentageOffset: 0.18,
        titleTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: WSColors.foreground,
        ),
        getTitle: (index, angle) {
          return switch (index) {
            0 => const RadarChartTitle(text: '환경 E'),
            1 => const RadarChartTitle(text: '사회 S'),
            _ => const RadarChartTitle(text: '거버넌스 G'),
          };
        },
        tickCount: 4,
        ticksTextStyle: const TextStyle(fontSize: 9, color: WSColors.muted),
        tickBorderData: BorderSide(
          color: WSColors.border.withValues(alpha: 0.7),
        ),
        gridBorderData: BorderSide(
          color: WSColors.border.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class MoodPieChart extends StatelessWidget {
  const MoodPieChart({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final counts = <Emotion, int>{
      Emotion.great: 0,
      Emotion.good: 0,
      Emotion.okay: 0,
      Emotion.hard: 0,
      Emotion.exhausted: 0,
    };
    for (final e in store.mindEntries) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    // 샘플 보정 (기록이 없으면 보기 좋은 분포)
    if (store.mindEntries.isEmpty) {
      counts[Emotion.great] = 2;
      counts[Emotion.good] = 3;
      counts[Emotion.okay] = 2;
      counts[Emotion.hard] = 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final colors = {
      Emotion.great: WSColors.sunny,
      Emotion.good: WSColors.mint,
      Emotion.okay: WSColors.primary,
      Emotion.hard: WSColors.lavender,
      Emotion.exhausted: WSColors.peach,
    };
    final labels = {
      Emotion.great: '최고',
      Emotion.good: '좋음',
      Emotion.okay: '보통',
      Emotion.hard: '힘듦',
      Emotion.exhausted: '지침',
    };

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final e in Emotion.values)
                  if ((counts[e] ?? 0) > 0)
                    PieChartSectionData(
                      value: (counts[e] ?? 0).toDouble(),
                      color: colors[e] ?? WSColors.primary,
                      radius: 42,
                      title: '${(((counts[e] ?? 0) / total) * 100).round()}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: WSColors.foreground,
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final e in Emotion.values)
              if ((counts[e] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[e],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${labels[e]} ${counts[e]}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

/// 마인드 탭용 주간 감정 미니 차트
class WeeklyMoodMiniChart extends StatelessWidget {
  const WeeklyMoodMiniChart({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return SoftLineChart(
      values: store.weeklyMoodSeries,
      labels: store.weekLabels,
      color: WSColors.lavender,
      minY: 0,
      maxY: 5,
      unit: '',
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: WSColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: index == i ? WSColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: index == i
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF1C2B36,
                            ).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: index == i ? WSColors.primaryDark : WSColors.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
