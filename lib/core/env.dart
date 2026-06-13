/// Build-time flag. When true (via `--dart-define=SCREENSHOT=true`) the app
/// pauses continuously-repeating animations and the live clock ticker so the
/// UI reaches a still frame for screenshots / golden tests. Off in real builds.
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT');
