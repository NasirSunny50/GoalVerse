import 'dart:convert';
import 'dart:io';

import 'package:goalverse_server/tournament_result.dart';

/// Records (or clears) the real tournament outcome that grades the
/// tournament-long predictions. Writes `data/tournament_result.json`, which the
/// running server reads on the next scoring pass — no restart needed.
///
/// Usage:
///   dart run bin/set_result.dart                       # show current result
///   dart run bin/set_result.dart --champion arg --runner-up fra \
///       --golden-boot arg --golden-glove fra            # record the result
///   dart run bin/set_result.dart --clear                # wipe (back to undecided)
///
/// Team ids are the same lower-case ids used in predictions (e.g. arg, fra).
void main(List<String> args) {
  final path = File('data/fixtures.json').existsSync()
      ? 'data/tournament_result.json'
      : 'server/data/tournament_result.json';
  final file = File(path);

  // No args → print the current result.
  if (args.isEmpty) {
    final res = TournamentResult.loadFromFile(path);
    stdout.writeln('Tournament result ($path):');
    _print(res);
    if (!res.decided) {
      stdout.writeln('\nNot recorded yet — no tournament points are awarded.');
      stdout.writeln('Record it with:');
      stdout.writeln('  dart run bin/set_result.dart --champion <id> '
          '--runner-up <id> --golden-boot <id> --golden-glove <id>');
    }
    return;
  }

  final flags = _parseFlags(args);
  if (flags == null) {
    stderr.writeln('Unknown or malformed arguments.');
    stderr.writeln('Run with no arguments to see usage.');
    exitCode = 64; // EX_USAGE
    return;
  }

  if (flags.containsKey('clear')) {
    if (file.existsSync()) file.deleteSync();
    stdout.writeln('Cleared tournament result — back to undecided.');
    return;
  }

  final res = TournamentResult(
    decided: true,
    champion: TournamentResult.normId(flags['champion']),
    runnerUp: TournamentResult.normId(flags['runner-up']),
    goldenBoot: TournamentResult.normId(flags['golden-boot']),
    goldenGlove: TournamentResult.normId(flags['golden-glove']),
  );

  if (res.champion == null &&
      res.runnerUp == null &&
      res.goldenBoot == null &&
      res.goldenGlove == null) {
    stderr.writeln('Nothing to record — pass at least one of '
        '--champion / --runner-up / --golden-boot / --golden-glove.');
    exitCode = 64;
    return;
  }

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(res.toJson()));
  stdout.writeln('Recorded tournament result ($path):');
  _print(res);
  stdout.writeln('\nThe server will apply this on its next scoring pass '
      '(once the Final has kicked off).');
}

void _print(TournamentResult r) {
  stdout.writeln('  decided      : ${r.decided}');
  stdout.writeln('  champion     : ${r.champion ?? '-'}');
  stdout.writeln('  runner-up    : ${r.runnerUp ?? '-'}');
  stdout.writeln('  golden boot  : ${r.goldenBoot ?? '-'}');
  stdout.writeln('  golden glove : ${r.goldenGlove ?? '-'}');
}

/// Parses `--key value` and bare `--clear`. Returns null on a malformed token.
Map<String, String>? _parseFlags(List<String> args) {
  const valueKeys = {'champion', 'runner-up', 'golden-boot', 'golden-glove'};
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (!a.startsWith('--')) return null;
    final key = a.substring(2);
    if (key == 'clear') {
      out['clear'] = '1';
      continue;
    }
    if (!valueKeys.contains(key)) return null;
    if (i + 1 >= args.length) return null;
    out[key] = args[++i];
  }
  return out;
}
