import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/goalverse_logo.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/team_badge.dart';
import '../../data/models/team.dart';
import '../../data/sources/teams_data.dart';
import '../../providers/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final teams = kTeams
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query.toLowerCase()) ||
            t.code.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return GradientScaffold(
      body: Stack(
        children: [
          Column(
            children: [
          const SizedBox(height: 12),
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search 48 nations…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.semantic.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.semantic.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: context.semantic.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 64,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: teams.length,
              itemBuilder: (context, i) {
                final t = teams[i];
                return _TeamChip(
                  team: t,
                  selected: _selected.contains(t.id),
                  onTap: () => setState(() {
                    if (!_selected.remove(t.id)) _selected.add(t.id);
                  }),
                ).animate().fadeIn(
                      delay: (i * 18).ms,
                      duration: 300.ms,
                    );
              },
            ),
          ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _continueButton(context),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoalVerseLogo(
                  markSize: 38,
                  fontSize: 26,
                  onDark: Theme.of(context).brightness == Brightness.dark)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.1),
          const SizedBox(height: 6),
          Text('FIFA World Cup 2026 • Predict. Compete. Win.',
              style: context.texts.bodySmall?.copyWith(
                  color: context.scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: 14),
          Text('Pick your nations',
              style: context.texts.displayMedium?.copyWith(fontSize: 30))
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.2),
          const SizedBox(height: 6),
          Text(
            'Your home screen, fixtures and alerts get personalised around the teams you follow.',
            style: context.texts.bodyMedium
                ?.copyWith(color: context.semantic.textDim),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _continueButton(BuildContext context) {
    final has = _selected.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => context
              .read<AppState>()
              .completeOnboarding(has ? _selected : const []),
          style: FilledButton.styleFrom(
            backgroundColor: context.scheme.primary,
            foregroundColor: context.scheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(
            has ? 'Continue with ${_selected.length} team(s)' : 'Skip for now',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? context.scheme.primary.withValues(alpha: 0.16)
              : context.semantic.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? context.scheme.primary
                : context.semantic.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            TeamBadge(team: team, size: 36, showRing: false),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                team.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: context.scheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
