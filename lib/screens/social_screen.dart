import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Social is brewing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
              ),
              SizedBox(height: 12),
              Text(
                'Friend hangouts and shared rankings are next — your log stays private until then.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.chocolate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
