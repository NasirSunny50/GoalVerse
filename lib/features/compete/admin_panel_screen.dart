import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/sources/teams_data.dart';
import '../../providers/compete_provider.dart';
import '../../providers/fixtures_provider.dart';
import 'logout_action.dart';

/// Admin-only screen. The admin enters the REAL result for each match; those
/// answers are the ONLY thing user predictions are scored against (no live
/// data anywhere in the loop).
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _loading = true;
  String? _error;
  final Map<String, Map<String, dynamic>> _results = {}; // matchId -> result

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matches = await context.read<CompeteProvider>().adminResults();
      _results.clear();
      for (final m in matches) {
        final r = m['result'];
        if (r is Map) _results[m['id'] as String] = r.cast<String, dynamic>();
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not reach the server. Pull to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fx = context.watch<FixturesProvider>();
    final matches = [...fx.matches]
      ..sort((a, b) => a.kickoff.compareTo(b.kickoff));

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Admin · Results'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: matches.length + 1,
                itemBuilder: (c, i) {
                  if (i == 0) {
                    final recorded =
                        _results.values.where(_hasResult).length;
                    return _header(context, recorded, matches.length);
                  }
                  return _matchTile(context, matches[i - 1]);
                },
              ),
            ),
    );
  }

  Widget _header(BuildContext context, int done, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter the real result for each match',
              style: context.texts.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Predictions are scored ONLY against what you set here — no live data is used. $done of $total matches recorded.',
            style: context.texts.bodySmall
                ?.copyWith(color: context.semantic.textDim),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(
                    color: context.scheme.error, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  static bool _hasResult(Map<String, dynamic> r) =>
      r['winner'] != null ||
      (r['homeScore'] != null && r['awayScore'] != null);

  Team? _teamFor(FootballMatch m, Map<String, dynamic>? r,
      {required bool home}) {
    final id = r?[home ? 'homeTeamId' : 'awayTeamId'] as String?;
    if (id != null && id.isNotEmpty) return kTeamsById[id];
    return home ? m.home : m.away;
  }

  String _label(FootballMatch m, Team? t, {required bool home}) =>
      t?.code ?? (home ? m.homePlaceholder : m.awayPlaceholder) ?? 'TBD';

  Widget _matchTile(BuildContext context, FootballMatch m) {
    final r = _results[m.id];
    final recorded = r != null && _hasResult(r);
    final assignedOnly = r != null && !recorded;
    final home = _teamFor(m, r, home: true);
    final away = _teamFor(m, r, home: false);
    final knockout = m.stage != MatchStage.groupStage;
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      onTap: () async {
        final saved = await Navigator.of(context).push<Map<String, dynamic>?>(
          MaterialPageRoute(
              builder: (_) => AdminResultScreen(match: m, initial: r)),
        );
        if (saved == null || !mounted) return;
        // Reflect the (possibly cleared) knockout team assignment immediately,
        // so the list + a re-opened editor don't fall back to the stale overlay.
        if (m.stage != MatchStage.groupStage) {
          m.home = saved.isEmpty ? null : kTeamsById[saved['homeTeamId'] as String?];
          m.away = saved.isEmpty ? null : kTeamsById[saved['awayTeamId'] as String?];
        }
        setState(() {
          if (saved.isEmpty) {
            _results.remove(m.id);
          } else {
            _results[m.id] = saved;
          }
        });
      },
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recorded
                  ? const Color(0xFF36C275)
                  : assignedOnly
                      ? const Color(0xFFE0A93B)
                      : context.semantic.border,
            ),
          ),
          const SizedBox(width: 10),
          TeamBadge(team: home, size: 28),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_label(m, home, home: true)}  v  ${_label(m, away, home: false)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  knockout
                      ? '${m.stage.shortLabel} • ${Dates.day(m.kickoffBd)}'
                      : 'Group ${m.group} • ${Dates.day(m.kickoffBd)}',
                  style: context.texts.bodySmall
                      ?.copyWith(color: context.semantic.textDim, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TeamBadge(team: away, size: 28),
          const SizedBox(width: 10),
          if (recorded)
            Text(_summary(r),
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: context.scheme.primary))
          else if (assignedOnly)
            Text('Set result',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE0A93B))),
          Icon(Icons.chevron_right, size: 18, color: context.semantic.textDim),
        ],
      ),
    );
  }

  String _summary(Map<String, dynamic> r) {
    final hs = r['homeScore'], as = r['awayScore'];
    if (hs != null && as != null) return '$hs–$as';
    final w = r['winner'];
    return w == null ? '✓' : '$w'.toUpperCase();
  }
}

/// Result-entry form for a single match (admin).
class AdminResultScreen extends StatefulWidget {
  const AdminResultScreen({super.key, required this.match, this.initial});
  final FootballMatch match;
  final Map<String, dynamic>? initial;

  @override
  State<AdminResultScreen> createState() => _AdminResultScreenState();
}

class _AdminResultScreenState extends State<AdminResultScreen> {
  int? _home;
  int? _away;
  String? _homeTeamId;
  String? _awayTeamId;
  String? _winnerOverride; // null → derived from score
  String? _firstScorer; // home/away/none
  bool? _penalties; // knockout only — decided on penalties?
  bool _busy = false;
  String? _error;

  FootballMatch get m => widget.match;
  bool get _isKnockout => m.stage != MatchStage.groupStage;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _homeTeamId = (r?['homeTeamId'] as String?) ?? m.home?.id;
    _awayTeamId = (r?['awayTeamId'] as String?) ?? m.away?.id;
    if (r != null) {
      _home = r['homeScore'] as int?;
      _away = r['awayScore'] as int?;
      _winnerOverride = r['winner'] as String?;
      _firstScorer = r['firstScorer'] as String?;
      _penalties = r['penalties'] as bool?;
    }
  }

  // For knockout slots the selection is fully controlled by the picker (so it
  // can be cleared); group matches always fall back to their fixed teams.
  Team? get _homeTeam => _homeTeamId != null
      ? kTeamsById[_homeTeamId]
      : (_isKnockout ? null : m.home);
  Team? get _awayTeam => _awayTeamId != null
      ? kTeamsById[_awayTeamId]
      : (_isKnockout ? null : m.away);

  bool get _hasScores => _home != null && _away != null;

  // Total Goals (Under 3 / 3+) and BTTS follow from the score — shown so the
  // admin sees every market the user predicted.
  String? get _ouDisplay =>
      !_hasScores ? null : ((_home! + _away!) >= 3 ? 'over' : 'under');
  bool? get _bttsDisplay => !_hasScores ? null : (_home! > 0 && _away! > 0);

  String? get _derivedWinner => !_hasScores
      ? null
      : (_home! > _away! ? 'home' : (_home! < _away! ? 'away' : 'draw'));
  String? get _effectiveWinner => _winnerOverride ?? _derivedWinner;

  String get _saveLabel =>
      _hasScores ? 'Save Result' : (_isKnockout ? 'Save Teams' : 'Save');

  Map<String, dynamic> get _body => {
        'homeTeamId': _isKnockout ? _homeTeamId : null,
        'awayTeamId': _isKnockout ? _awayTeamId : null,
        'winner': _effectiveWinner,
        'homeScore': _home,
        'awayScore': _away,
        'firstScorer': _firstScorer,
        'penalties': _isKnockout ? _penalties : null,
      };

  Future<void> _save() async {
    // The only guard left: if BOTH knockout teams are set they must differ.
    if (_isKnockout &&
        _homeTeamId != null &&
        _awayTeamId != null &&
        _homeTeamId == _awayTeamId) {
      setState(() => _error = 'Home and away must be different teams.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = _body;
    final empty = body.values.every((v) => v == null);
    final compete = context.read<CompeteProvider>();
    // Nothing set (e.g. teams cleared and no result) → remove the row so the
    // slot resets to a placeholder.
    final err = empty
        ? await compete.clearMatchResult(m.id)
        : await compete.setMatchResult(m.id, body);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop(empty ? <String, dynamic>{} : body);
  }

  Future<void> _clear() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<CompeteProvider>().clearMatchResult(m.id);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{}); // empty map = cleared
  }

  @override
  Widget build(BuildContext context) {
    final hc = _homeTeam?.code ?? 'Home';
    final ac = _awayTeam?.code ?? 'Away';
    return GradientScaffold(
      appBar: AppBar(title: Text(_isKnockout ? m.stage.label : 'Match Result')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            0, 8, 0, 32 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          _matchHeader(context),
          if (_isKnockout) ...[
            _section(context, 'Teams'),
            _teamPickers(context),
          ],
          _section(context, 'Final Score'),
          _scoreCard(context, hc, ac),
          _section(context, 'Winner'),
          _winnerRow(context, hc, ac),
          _section(context, 'First Team to Score'),
          _chips(context, _firstScorer, {
            'home': hc,
            'none': 'None',
            'away': ac,
          }, (v) => setState(() => _firstScorer = v)),
          _section(context, 'Total Goals'),
          _autoChips(context, _ouDisplay,
              const {'under': 'Under 3', 'over': '3 or more'}),
          _section(context, 'Both Teams to Score?'),
          _autoChips(
              context,
              _bttsDisplay == null ? null : (_bttsDisplay! ? 'yes' : 'no'),
              const {'yes': 'Yes', 'no': 'No'}),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text('↑ Auto-filled from the score above.',
                style: context.texts.bodySmall
                    ?.copyWith(color: context.semantic.textDim)),
          ),
          if (_isKnockout) ...[
            _section(context, 'Decided on Penalties?'),
            _chips(
                context,
                _penalties == null ? null : (_penalties! ? 'yes' : 'no'),
                {'yes': 'Yes', 'no': 'No'},
                (v) => setState(() => _penalties = v == 'yes')),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(_error!,
                  style: TextStyle(
                      color: context.scheme.error,
                      fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (widget.initial != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _clear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: context.scheme.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Clear',
                          style: TextStyle(
                              color: context.scheme.error,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.scheme.primary,
                      foregroundColor: context.scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_saveLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient:
            const LinearGradient(colors: [Color(0xFF20264F), Color(0xFF131730)]),
      ),
      child: Row(
        children: [
          Expanded(
              child: _teamCol(_homeTeam,
                  _homeTeam?.name ?? (m.homePlaceholder ?? m.homeName))),
          const Text('VS',
              style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          Expanded(
              child: _teamCol(_awayTeam,
                  _awayTeam?.name ?? (m.awayPlaceholder ?? m.awayName))),
        ],
      ),
    );
  }

  Widget _teamPickers(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _teamPickBtn(
              context,
              _homeTeam,
              m.homePlaceholder ?? 'Home team',
              (t) => setState(() => _homeTeamId = t.id),
              () => setState(() => _homeTeamId = null),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _teamPickBtn(
              context,
              _awayTeam,
              m.awayPlaceholder ?? 'Away team',
              (t) => setState(() => _awayTeamId = t.id),
              () => setState(() => _awayTeamId = null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamPickBtn(BuildContext context, Team? team, String hint,
      ValueChanged<Team> onPick, VoidCallback onClear) {
    return Container(
      decoration: BoxDecoration(
        color: context.semantic.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.semantic.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final picked = await showModalBottomSheet<Team>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _TeamPickerSheet(),
                );
                if (picked != null) onPick(picked);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
                child: Row(
                  children: [
                    TeamBadge(team: team, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(team?.name ?? hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: team == null
                                  ? context.semantic.textDim
                                  : null)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Clear when a team is picked, otherwise a dropdown affordance.
          if (team != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 10, 10),
                child: Icon(Icons.close,
                    size: 18, color: context.semantic.textDim),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.expand_more,
                  size: 18, color: context.semantic.textDim),
            ),
        ],
      ),
    );
  }

  Widget _teamCol(Team? team, String name) => Column(
        children: [
          TeamBadge(team: team, size: 46),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      );

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(title, style: context.texts.titleMedium),
      );

  Widget _scoreCard(BuildContext context, String hc, String ac) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Touching either side sets BOTH (the untouched one → 0) so a result
          // is never saved half-filled (e.g. 4-? would break Exact/Goals/BTTS).
          _stepper(context, hc, _home ?? 0, (v) {
            setState(() {
              _home = v;
              _away ??= 0;
            });
          }),
          Text(':', style: context.texts.displaySmall?.copyWith(fontSize: 26)),
          _stepper(context, ac, _away ?? 0, (v) {
            setState(() {
              _away = v;
              _home ??= 0;
            });
          }),
        ],
      ),
    );
  }

  Widget _stepper(
      BuildContext context, String label, int value, ValueChanged<int> onChange) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: context.semantic.textDim, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            _miniBtn(context, Icons.remove,
                () => onChange((value - 1).clamp(0, 30))),
            SizedBox(
              width: 40,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: context.texts.titleLarge?.copyWith(fontSize: 24)),
            ),
            _miniBtn(context, Icons.add,
                () => onChange((value + 1).clamp(0, 30))),
          ],
        ),
      ],
    );
  }

  Widget _miniBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: context.semantic.bg2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: context.scheme.primary),
        ),
      ),
    );
  }

  Widget _winnerRow(BuildContext context, String hc, String ac) {
    // Highlights the effective winner; tapping sets an explicit override
    // (needed for knockout/penalty calls where the 90' score is a draw).
    return _chips(context, _effectiveWinner ?? '', {
      'home': hc,
      'draw': 'Draw',
      'away': ac,
    }, (v) => setState(() => _winnerOverride = v));
  }

  Widget _chips(BuildContext context, String? value,
      Map<String, String> options, ValueChanged<String> onPick) {
    final entries = options.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onPick(entries[i].key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == entries[i].key
                        ? context.scheme.primary
                        : context.semantic.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: value == entries[i].key
                            ? Colors.transparent
                            : context.semantic.border),
                  ),
                  child: Text(
                    entries[i].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: value == entries[i].key
                          ? context.scheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            if (i < entries.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// Read-only chips that just highlight the computed answer (Total Goals,
  /// BTTS) — these follow from the score, so the admin sees but can't mis-set.
  Widget _autoChips(
      BuildContext context, String? value, Map<String, String> options) {
    final entries = options.entries.toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value == entries[i].key
                      ? context.scheme.primary.withValues(alpha: 0.85)
                      : context.semantic.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: value == entries[i].key
                          ? Colors.transparent
                          : context.semantic.border),
                ),
                child: Text(entries[i].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: value == entries[i].key
                            ? context.scheme.onPrimary
                            : context.semantic.textDim)),
              ),
            ),
            if (i < entries.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Bottom-sheet team picker — all 48 teams grouped by their group.
class _TeamPickerSheet extends StatelessWidget {
  const _TeamPickerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) => Container(
        decoration: BoxDecoration(
          color: ctx.scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: ctx.semantic.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Select team', style: ctx.texts.titleLarge),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  for (final g in kGroupLetters) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                      child: Text('Group $g',
                          style: TextStyle(
                              color: ctx.scheme.primary,
                              fontWeight: FontWeight.w800)),
                    ),
                    for (final t in teamsInGroup(g))
                      ListTile(
                        dense: true,
                        leading: TeamBadge(team: t, size: 30),
                        title: Text(t.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.of(ctx).pop(t),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
