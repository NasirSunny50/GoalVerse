import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../providers/compete_provider.dart';
import 'compete_models.dart';
import 'logout_action.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compete = context.watch<CompeteProvider>();
    final stats = compete.compute();
    final hof = compete.leaderboard(LbPeriod.allTime);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => confirmLogout(context, popAfter: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _header(context, compete.user ?? 'Player', stats),
          _statGrid(context, stats),
          _sectionTitle(context, 'Achievement Badges'),
          _badges(context, stats.badges),
          _sectionTitle(context, 'Milestones'),
          _milestones(context, stats),
          _sectionTitle(context, 'Hall of Fame'),
          for (var i = 0; i < hof.take(5).length; i++)
            _hofRow(context, i + 1, hof[i]),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String name, CompeteStats s) {
    final progress =
        s.xpForLevel == 0 ? 0.0 : (s.xpIntoLevel / s.xpForLevel).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
            colors: [AppColors.secondary, AppColors.primary]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    Text('Rank #${s.rank} of ${s.totalPlayers}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('LEVEL',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                    Text('${s.level}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${s.xpIntoLevel}/${s.xpForLevel} XP to level ${s.level + 1}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(BuildContext context, CompeteStats s) {
    final items = [
      ('${s.points}', 'Points', Icons.stars),
      ('${s.accuracy}%', 'Accuracy', Icons.track_changes),
      ('${s.streak}', 'Streak', Icons.local_fire_department),
      ('${s.predictions}', 'Predictions', Icons.checklist),
      ('${s.exact}', 'Exact Scores', Icons.gps_fixed),
      ('${s.correct}', 'Correct', Icons.verified),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: [
          for (final it in items)
            GlassCard(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.$3, color: context.scheme.primary, size: 22),
                  const SizedBox(height: 6),
                  Text(it.$1,
                      style: context.texts.titleLarge?.copyWith(fontSize: 18)),
                  Text(it.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.semantic.textDim, fontSize: 10.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(t, style: context.texts.titleLarge?.copyWith(fontSize: 18)),
      );

  Widget _badges(BuildContext context, List<String> earned) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: [
        for (final b in CompeteProvider.allBadges)
          _badgeTile(context, b, earned.contains(b.id)),
      ],
    );
  }

  Widget _badgeTile(BuildContext context, AchievementBadge b, bool unlocked) {
    return Tooltip(
      message: '${b.name}\n${b.description}',
      child: Opacity(
        opacity: unlocked ? 1 : 0.4,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked
                    ? const LinearGradient(colors: AppColors.brandGradient)
                    : null,
                color: unlocked ? null : context.semantic.card,
                border: Border.all(
                    color: unlocked
                        ? Colors.transparent
                        : context.semantic.border),
              ),
              child: Icon(b.icon,
                  color: unlocked ? Colors.white : context.semantic.textDim,
                  size: 24),
            ),
            const SizedBox(height: 4),
            Text(b.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _milestones(BuildContext context, CompeteStats s) {
    final items = [
      ('Reach 100 points', s.points, 100),
      ('Reach level 5', s.level, 5),
      ('Make 10 predictions', s.predictions, 10),
      ('Hit a 5 streak', s.streak, 5),
    ];
    return Column(
      children: [
        for (final it in items)
          GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                    it.$2 >= it.$3
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: it.$2 >= it.$3
                        ? context.scheme.primary
                        : context.semantic.textDim,
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(it.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('${it.$2.clamp(0, it.$3)}/${it.$3}',
                    style: TextStyle(
                        color: context.semantic.textDim,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hofRow(BuildContext context, int rank, LeaderboardEntry e) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text('#$rank',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? AppColors.gold : context.semantic.textDim)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(e.isUser ? '${e.name} (you)' : e.name,
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('${e.points} pts',
              style: TextStyle(color: context.scheme.primary)),
        ],
      ),
    );
  }
}
