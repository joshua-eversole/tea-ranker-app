import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/phone_frame.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tea Ranker', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text(
                  'Missing Supabase URL or publishable key. Pass them at run time — never a service_role key.',
                ),
                const SizedBox(height: 20),
                const SelectableText(
                  'flutter run -d chrome \\\n'
                  '  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\\n'
                  '  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key\n\n'
                  'Or copy dart_defines.example.json to dart_defines.json '
                  '(gitignored) and use --dart-define-from-file=dart_defines.json',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
