import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Honest coming-soon page used by Map.
class BrewingScreen extends StatelessWidget {
  const BrewingScreen({
    super.key,
    required this.headline,
    required this.subhead,
  });

  final String headline;
  final String subhead;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subhead,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.chocolate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
