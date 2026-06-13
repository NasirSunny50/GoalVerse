// Crops the ball+ring icon out of the full GoalVerse logo and builds:
//  - assets/branding/goalverse_icon.png   (square, transparent — in-app mark)
//  - assets/branding/goalverse_launcher.png (square, navy bg — launcher source)
// Run: dart run tool/crop_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

void main() {
  final full = img.decodePng(
      File('assets/branding/goalverse_full.png').readAsBytesSync())!;
  final w = full.width, h = full.height;

  // Bounding box of the artwork above the wordmark (top ~58%).
  final yLimit = (h * 0.58).round();
  int minX = w, minY = h, maxX = 0, maxY = 0;
  for (var y = 0; y < yLimit; y++) {
    for (var x = 0; x < w; x++) {
      if (full.getPixel(x, y).a > 30) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final bw = maxX - minX + 1, bh = maxY - minY + 1;
  stdout.writeln('icon bbox: x=$minX y=$minY w=$bw h=$bh');

  final cropped = img.copyCrop(full, x: minX, y: minY, width: bw, height: bh);

  // Square transparent canvas with padding.
  final side = math.max(bw, bh);
  final pad = (side * 0.08).round();
  final canvasSide = side + pad * 2;
  final icon = img.Image(width: canvasSide, height: canvasSide, numChannels: 4);
  img.compositeImage(icon, cropped,
      dstX: pad + (side - bw) ~/ 2, dstY: pad + (side - bh) ~/ 2);
  File('assets/branding/goalverse_icon.png')
      .writeAsBytesSync(img.encodePng(icon));

  // Launcher: navy rounded field + the icon centred.
  const L = 1024;
  final launcher = img.Image(width: L, height: L, numChannels: 4);
  img.fill(launcher, color: img.ColorRgba8(10, 24, 48, 255));
  // subtle radial glow
  for (var r = 470; r > 0; r -= 6) {
    final t = r / 470.0;
    img.fillCircle(launcher,
        x: L ~/ 2,
        y: L ~/ 2,
        radius: r,
        color: img.ColorRgba8(46, 120, 200, ((1 - t) * 50).round()),
        antialias: true);
  }
  final resized = img.copyResize(icon, width: (L * 0.84).round());
  img.compositeImage(launcher, resized,
      dstX: (L - resized.width) ~/ 2, dstY: (L - resized.height) ~/ 2);
  File('assets/branding/goalverse_launcher.png')
      .writeAsBytesSync(img.encodePng(launcher));

  stdout.writeln('Wrote goalverse_icon.png and goalverse_launcher.png');
}
