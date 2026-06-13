import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../providers/compete_provider.dart';
import 'compete_models.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab =
      TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

  static const _periods = [
    LbPeriod.global,
    LbPeriod.weekly,
    LbPeriod.monthly,
    LbPeriod.allTime,
  ];

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: context.scheme.primary,
          labelColor: context.scheme.primary,
          unselectedLabelColor: context.semantic.textDim,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All-Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [for (final p in _periods) _board(context, p)],
      ),
    );
  }

  Widget _board(BuildContext context, LbPeriod period) {
    final compete = context.watch<CompeteProvider>();
    final rows = compete.leaderboard(period);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: rows.length,
      itemBuilder: (_, i) => _rowTile(context, i + 1, rows[i]),
    );
  }

  Widget _rowTile(BuildContext context, int rank, LeaderboardEntry e) {
    final medal = rank <= 3;
    final medalColor = rank == 1
        ? AppColors.gold
        : rank == 2
            ? const Color(0xFFC0C7D0)
            : const Color(0xFFCD7F32);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      gradient: e.isUser
          ? LinearGradient(colors: [
              context.scheme.primary.withValues(alpha: 0.22),
              context.scheme.secondary.withValues(alpha: 0.18),
            ])
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: medal
                ? Icon(Icons.emoji_events, color: medalColor, size: 22)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.semantic.textDim)),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 16,
            backgroundColor: context.scheme.primary.withValues(alpha: 0.18),
            child: Text(e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(e.isUser ? '${e.name} (you)' : e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Text('${e.accuracy}% acc • ${e.predictions} picks',
                    style: TextStyle(
                        color: context.semantic.textDim, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.points}',
                  style: context.texts.titleMedium
                      ?.copyWith(color: context.scheme.primary)),
              Text('pts',
                  style: TextStyle(
                      color: context.semantic.textDim, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
