import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../data/shop_brands.dart';

Future<List<String>> extractLogoPalette(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final generator = await PaletteGenerator.fromImage(
      image,
      maximumColorCount: 8,
    );
    final colors = <Color>[
      if (generator.dominantColor != null) generator.dominantColor!.color,
      if (generator.vibrantColor != null) generator.vibrantColor!.color,
      if (generator.mutedColor != null) generator.mutedColor!.color,
      if (generator.darkVibrantColor != null) generator.darkVibrantColor!.color,
      if (generator.lightVibrantColor != null)
        generator.lightVibrantColor!.color,
      if (generator.darkMutedColor != null) generator.darkMutedColor!.color,
      ...generator.colors,
    ];
    return takePaletteHexes(colors);
  } finally {
    image.dispose();
  }
}
