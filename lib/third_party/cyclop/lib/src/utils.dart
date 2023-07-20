import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

//bool get isPhoneScreen => !(screenSize.shortestSide >= 600);

Size get screenSize => ui.window.physicalSize / ui.window.devicePixelRatio;

extension Screen on MediaQueryData {
  bool get isPhone => size.shortestSide < 600;
}

extension Chroma on String {
  /// converts string to [Color]
  /// fill incomplete values with 0
  /// ex: 'ff00'.toColor() => Color(0xffff0000)
  Color toColor({bool argb = false}) {
    final colorString = '0x${argb ? '' : 'ff'}$this'.padRight(10, '0');
    return Color(int.tryParse(colorString) ?? 0);
  }
}

/// shortcuts to manipulate [Color]
extension Utils on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  double get hue => hsl.hue;

  double get saturation => hsl.saturation;

  double get lightness => hsl.lightness;

  Color withHue(double value) => hsl.withHue(value).toColor();

  /// ff001232
  String get hexARGB => value.toRadixString(16).padLeft(8, '0');

  /// 001232ac
  String get hexRGB =>
      value.toRadixString(16).padLeft(8, '0').replaceRange(0, 2, '');

  Color withSaturation(double value) =>
      HSLColor.fromAHSL(opacity, hue, value, lightness).toColor();

  Color withLightness(double value) => hsl.withLightness(value).toColor();

  /// generate the gradient of a color with
  /// lightness from 0 to 1 in [stepCount] steps
  List<Color> getShades(int stepCount, {bool skipFirst = true}) =>
      List.generate(
        stepCount,
        (index) {
          return hsl
              .withLightness(1 -
                  ((index + (skipFirst ? 1 : 0)) /
                      (stepCount - (skipFirst ? -1 : 1))))
              .toColor();
        },
      );
}

extension Helper on List<Color> {
  /// return the central item of a color list or black if the list is empty
  Color get center => isEmpty ? Colors.black : this[length ~/ 2];
}

List<Color> getHueGradientColors({double? saturation, int steps = 36}) =>
    List.generate(steps, (value) => value)
        .map<Color>((v) {
          final hsl = HSLColor.fromAHSL(1, v * (360 / steps), 0.67, 0.50);
          final rgb = hsl.toColor();
          return rgb.withOpacity(1);
        })
        .map((c) => saturation != null ? c.withSaturation(saturation) : c)
        .toList();

const samplingGridSize = 9;

List<Color> getPixelColors(
  img.Image image,
  Offset offset, {
  int size = samplingGridSize,
}) =>
    List.generate(
      size * size,
      (index) => getPixelColor(
        image,
        offset + _offsetFromIndex(index, samplingGridSize),
      ),
    );

Color getPixelColor(img.Image image, Offset offset) {
  if (offset.dx >= 0 &&
      offset.dy >= 0 &&
      offset.dx < image.width &&
      offset.dy < image.height) {
    final Uint32List data = image.toUint8List().buffer.asUint32List();
    return abgr2Color(
        data[offset.dx.toInt() * image.width + offset.dy.toInt()]);
  } else {
    return const Color(0x00000000);
  }
}

ui.Offset _offsetFromIndex(int index, int numColumns) => Offset(
      (index % numColumns).toDouble(),
      ((index ~/ numColumns) % numColumns).toDouble(),
    );

Color abgr2Color(int value) {
  final a = (value >> 24) & 0xFF;
  final b = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final r = (value >> 0) & 0xFF;

  return Color.fromARGB(a, r, g, b);
}

Future<img.Image?> repaintBoundaryToImage(
  RenderRepaintBoundary renderer,
) async {
  try {
    final rawImage = await renderer.toImage(pixelRatio: 1);
    final byteData =
        await rawImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pngBytes = byteData!.buffer;
    return img.Image.fromBytes(
        width: rawImage.width, height: rawImage.height, bytes: pngBytes);
  } catch (err) {
    return null;
  }
}
