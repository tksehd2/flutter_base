import 'package:flutter/material.dart';

import '../config/app_features.dart';

class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final enabledFeatures = <String>[
      if (AppFeatures.googleAuthEnabled) 'Google Auth',
      if (AppFeatures.googleDriveEnabled) 'Google Drive',
      if (AppFeatures.geminiEnabled) 'Gemini',
      if (AppFeatures.driftDbEnabled) 'Drift DB',
      if (AppFeatures.dioNetworkEnabled) 'Dio Network',
      if (AppFeatures.demoModeEnabled) 'Demo Mode',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Base')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              'Production app shell ready.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Start your real app from app/ and add optional integrations under features/.',
            ),
            const SizedBox(height: 24),
            Text(
              'Enabled foundations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: enabledFeatures
                  .map((feature) => Chip(label: Text(feature)))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Recommended next edits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. Replace this page with your real home screen.\n'
                  '2. Keep shared infrastructure in core/.\n'
                  '3. Add optional product capabilities under features/.\n'
                  '4. Toggle integrations from app/config/app_features.dart.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
