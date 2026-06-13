import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/goalverse_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'admin_panel_screen.dart';
import 'auth_screen.dart';
import 'compete_models.dart';
import 'leaderboard_screen.dart';
import 'my_predictions_screen.dart';
import 'predict_match_screen.dart';
import 'predictions_list_screen.dart';
import 'profile_screen.dart';
import 'tournament_predict_screen.dart';

class CompeteScreen extends StatelessWidget {
  const CompeteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final compete = context.watch<CompeteProvider>();
    if (!compete.ready) {
      return const GradientScaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (!compete.loggedIn) {
      return const GradientScaffold(
        body: SafeArea(child: AuthPanel()),
      );
    }
    if (compete.isAdmin) {
      return const AdminPanelScreen();
    }
    return const _Dashboard();
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final compete = context.watch<CompeteProvider>();
    final now = fx.now;
    final stats = compete.compute();
    final notifs = compete.notifications(fx.matches, now);
    final allUpcoming = fx.upcomingMatches
        .where((m) => m.home != null && m.away != null)
        .toList();
    final upcoming = allUpcoming.take(8).toList();
    final board = compete.leaderboard(LbPeriod.global);

    return GradientScaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: GoalVerseLogo(
            markSize: 34,
            fontSize: 24,
            onDark: Theme.of(context).brightness == Brightness.dark),
        actions: [
          _bell(context, notifs),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => fx.refreshNow(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            _rankHero(context, compete.user!, stats),
            const SizedBox(height: 14),
            _statRow(context, stats),
            const SizedBox(height: 10),
            _navButton(
                context,
                Icons.fact_check,
                'My Predictions',
                'Review your picks & results',
                () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const MyPredictionsScreen()))),
            _countdown(context, fx, now),
            _header(context, 'Prediction Deadlines', Icons.timer,
                action: 'Tournament picks',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TournamentPredictScreen()))),
            if (upcoming.isEmpty)
              _empty(context, 'No upcoming matches to predict right now.')
            else ...[
              for (final m in upcoming) _predictTile(context, m, compete, now),
              if (allUpcoming.length > upcoming.length)
                _seeAllTile(context, allUpcoming.length),
            ],
            _header(context, 'Leaderboard', Icons.leaderboard,
                action: 'View all',
                onAction: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen()))),
            _leaderSnapshot(context, board, compete.user!),
          ],
        ),
      ),
    );
  }

  // ---- Notifications bell --------------------------------------------------

  Widget _bell(BuildContext context, List<AppNotification> notifs) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => _showNotifs(context, notifs),
        ),
        if (notifs.isNotEmpty)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.live, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text('${notifs.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }

  void _showNotifs(BuildContext context, List<AppNotification> notifs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications', style: ctx.texts.titleLarge),
              const SizedBox(height: 4),
              Text('Smart alerts for deadlines, achievements & your rank',
                  style: TextStyle(color: ctx.semantic.textDim, fontSize: 12)),
              const SizedBox(height: 12),
              Expanded(
                child: notifs.isEmpty
                    ? Center(
                        child: Text('You are all caught up 🎉',
                            style: TextStyle(color: ctx.semantic.textDim)))
                    : ListView.builder(
                        controller: controller,
                        itemCount: notifs.length,
                        itemBuilder: (_, i) {
                          final n = notifs[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  ctx.scheme.primary.withValues(alpha: 0.16),
                              child: Icon(n.icon,
                                  color: ctx.scheme.primary, size: 20),
                            ),
                            title: Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(n.body),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Hero ----------------------------------------------------------------

  Widget _rankHero(BuildContext context, String name, CompeteStats s) {
    final progress =
        s.xpForLevel == 0 ? 0.0 : (s.xpIntoLevel / s.xpForLevel).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
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
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $name',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    Text('Level ${s.level} • Rank #${s.rank}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${s.points}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26)),
                  const Text('POINTS',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, CompeteStats s) {
    final items = [
      ('#${s.rank}', 'My Rank', Icons.leaderboard),
      ('${s.accuracy}%', 'Accuracy', Icons.track_changes),
      ('${s.streak}', 'Streak', Icons.local_fire_department),
      ('${s.predictions}', 'Picks', Icons.checklist),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: GlassCard(
              // The "Picks" card opens the read-only My Predictions list.
              onTap: i == 3
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MyPredictionsScreen()))
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                children: [
                  Icon(items[i].$3, size: 18, color: context.scheme.primary),
                  const SizedBox(height: 6),
                  Text(items[i].$1,
                      style:
                          context.texts.titleMedium?.copyWith(fontSize: 16)),
                  Text(items[i].$2,
                      style: TextStyle(
                          color: context.semantic.textDim, fontSize: 10)),
                ],
              ),
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _countdown(BuildContext context, FixturesProvider fx, DateTime now) {
    final next = fx.nextMatch;
    if (next == null) return const SizedBox.shrink();
    final d = next.timeUntil(now);
    return GlassCard(
      margin: const EdgeInsets.only(top: 12),
      gradient: LinearGradient(colors: [
        context.scheme.secondary.withValues(alpha: 0.85),
        context.scheme.primary.withValues(alpha: 0.8),
      ]),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next prediction deadline',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text('${next.homeName} v ${next.awayName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ),
          Text(Dates.countdown(d),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title, IconData icon,
      {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.scheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(title,
                  style: context.texts.titleLarge?.copyWith(fontSize: 18))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  foregroundColor: context.scheme.primary),
              child: Text(action,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _navButton(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: context.scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(
                        color: context.semantic.textDim, fontSize: 11.5)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: context.semantic.textDim),
        ],
      ),
    );
  }

  Widget _seeAllTile(BuildContext context, int total) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const PredictionsListScreen())),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month, size: 18, color: context.scheme.primary),
          const SizedBox(width: 8),
          Text('See all $total upcoming matches',
              style: TextStyle(
                  color: context.scheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward, size: 16, color: context.scheme.primary),
        ],
      ),
    );
  }

  Widget _predictTile(BuildContext context, FootballMatch m,
      CompeteProvider compete, DateTime now) {
    final has = compete.hasPrediction(m.id);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PredictMatchScreen(match: m))),
      child: Row(
        children: [
          TeamBadge(team: m.home, size: 34),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('${m.home?.code ?? '—'}  v  ${m.away?.code ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    '${Dates.relativeDay(m.kickoffBd, now.toUtc().add(const Duration(hours: 6)))} • ${Dates.time(m.kickoffBd)} BD',
                    style: TextStyle(
                        color: context.semantic.textDim, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TeamBadge(team: m.away, size: 34),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: has
                  ? context.scheme.primary.withValues(alpha: 0.16)
                  : context.semantic.bg2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: has
                      ? context.scheme.primary.withValues(alpha: 0.5)
                      : context.semantic.border),
            ),
            child: Text(has ? 'Edit ✓' : 'Predict',
                style: TextStyle(
                    color: has ? context.scheme.primary : null,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _leaderSnapshot(
      BuildContext context, List<LeaderboardEntry> board, String user) {
    final top = board.take(5).toList();
    final userIdx = board.indexWhere((e) => e.isUser);
    return GlassCard(
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) _snapRow(context, i + 1, top[i]),
          if (userIdx >= 5) ...[
            Divider(color: context.semantic.border),
            _snapRow(context, userIdx + 1, board[userIdx]),
          ],
        ],
      ),
    );
  }

  Widget _snapRow(BuildContext context, int rank, LeaderboardEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('$rank',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: rank == 1
                        ? AppColors.gold
                        : context.semantic.textDim)),
          ),
          Expanded(
            child: Text(e.isUser ? '${e.name} (you)' : e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: e.isUser ? FontWeight.w800 : FontWeight.w600,
                    color: e.isUser ? context.scheme.primary : null)),
          ),
          Text('${e.points} pts',
              style: TextStyle(
                  color: context.semantic.textDim,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String text) => GlassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
              child: Text(text,
                  style: TextStyle(color: context.semantic.textDim))),
        ),
      );
}
