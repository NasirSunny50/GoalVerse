// Generates the GoalVerse launcher icon (football + blue orbital ring +
// sparkles on a dark navy field) as a 1024x1024 PNG.
// Run: dart run tool/gen_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  const n = 1024;
  final image = img.Image(width: n, height: n, numChannels: 4);

  // Background: dark navy with a soft radial glow.
  img.fill(image, color: img.ColorRgba8(10, 24, 48, 255));
  final cx = n / 2, cy = n / 2;
  for (var r = 480; r > 0; r -= 4) {
    final t = r / 480.0;
    final a = ((1 - t) * 60).round();
    img.fillCircle(image,
        x: cx.round(),
        y: cy.round(),
        radius: r,
        color: img.ColorRgba8(46, 120, 200, a),
        antialias: true);
  }

  final ballR = 250.0;
  const angle = -0.5;
  final a = 430.0, b = 196.0;

  List<img.Point> ringPoints() {
    final pts = <img.Point>[];
    for (var i = 0; i <= 120; i++) {
      final t = i / 120 * 2 * math.pi;
      final x0 = a * math.cos(t), y0 = b * math.sin(t);
      final x = cx + x0 * math.cos(angle) - y0 * math.sin(angle);
      final y = cy + x0 * math.sin(angle) + y0 * math.cos(angle);
      pts.add(img.Point(x, y));
    }
    return pts;
  }

  final pts = ringPoints();
  void drawRing(bool front) {
    final col = img.ColorRgba8(56, 198, 244, 255);
    for (var i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i], p2 = pts[i + 1];
      final midY = (p1.y + p2.y) / 2;
      final isFront = midY > cy;
      if (isFront != front) continue;
      img.drawLine(image,
          x1: p1.x.round(),
          y1: p1.y.round(),
          x2: p2.x.round(),
          y2: p2.y.round(),
          color: col,
          thickness: 26,
          antialias: true);
    }
  }

  // Ring behind the ball.
  drawRing(false);

  // Football body.
  img.fillCircle(image,
      x: cx.round(),
      y: cy.round(),
      radius: ballR.round() + 6,
      color: img.ColorRgba8(0, 0, 0, 60),
      antialias: true);
  img.fillCircle(image,
      x: cx.round(),
      y: cy.round(),
      radius: ballR.round(),
      color: img.ColorRgba8(245, 248, 252, 255),
      antialias: true);

  // Pentagons + seams.
  final black = img.ColorRgba8(18, 22, 31, 255);
  final pent = <img.Point>[];
  final pr = ballR * 0.34;
  for (var i = 0; i < 5; i++) {
    final ang = -math.pi / 2 + i * 2 * math.pi / 5;
    pent.add(img.Point(cx + pr * math.cos(ang), cy + pr * math.sin(ang)));
  }
  img.fillPolygon(image, vertices: pent, color: black);
  for (var i = 0; i < 5; i++) {
    final ang = -math.pi / 2 + i * 2 * math.pi / 5;
    final to = img.Point(
        cx + ballR * 0.92 * math.cos(ang), cy + ballR * 0.92 * math.sin(ang));
    img.drawLine(image,
        x1: pent[i].x.round(),
        y1: pent[i].y.round(),
        x2: to.x.round(),
        y2: to.y.round(),
        color: black,
        thickness: 16,
        antialias: true);
    img.fillCircle(image,
        x: to.x.round(),
        y: to.y.round(),
        radius: (ballR * 0.12).round(),
        color: black,
        antialias: true);
  }

  // Ring in front (lower arc, over the ball).
  drawRing(true);

  // Sparkles.
  void sparkle(double x, double y, double s) {
    final col = img.ColorRgba8(159, 227, 255, 255);
    img.fillPolygon(image, vertices: [
      img.Point(x, y - s),
      img.Point(x + s * 0.32, y),
      img.Point(x, y + s),
      img.Point(x - s * 0.32, y),
    ], color: col);
    img.fillPolygon(image, vertices: [
      img.Point(x - s, y),
      img.Point(x, y - s * 0.32),
      img.Point(x + s, y),
      img.Point(x, y + s * 0.32),
    ], color: col);
  }

  sparkle(cx + 300, cy - 280, 34);
  sparkle(cx - 320, cy + 90, 26);
  sparkle(cx + 250, cy + 300, 22);

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/goalverse_icon.png').writeAsBytesSync(img.encodePng(image));
  stdout.writeln('Wrote assets/icon/goalverse_icon.png');
}
