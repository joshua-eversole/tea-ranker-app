import 'package:flutter/material.dart';

import 'brewing_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrewingScreen(
      headline: 'Social is brewing.',
      subhead:
          'Friend hangouts and shared rankings are next — your log stays private until then.',
    );
  }
}
