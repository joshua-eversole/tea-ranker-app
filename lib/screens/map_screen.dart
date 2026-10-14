import 'package:flutter/material.dart';

import 'brewing_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrewingScreen(
      headline: 'Map is brewing.',
      subhead:
          'Shop pins on a real map are next — your log stays private until then.',
    );
  }
}
