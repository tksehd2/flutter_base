import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/demo_mode/demo_mode.dart';
import '../config/app_features.dart';

class AppHomePage extends ConsumerWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoModeState = ref.watch(demoModeActiveProvider);
    final enabledFeatures = <String>[
      if (AppFeatures.googleAuthEnabled) 'Google Auth',
      if (AppFeatures.googleDriveEnabled) 'Google Drive',
      if (AppFeatures.geminiEnabled) 'Gemini',
      if (AppFeatures.driftDbEnabled) 'Drift DB',
      if (AppFeatures.dioNetworkEnabled) 'Dio Network',
      if (AppFeatures.demoModeEnabled)
        demoModeState.when(
          data: (isActive) =>
              isActive ? 'Demo Mode (Active)' : 'Demo Mode (Inactive)',
          loading: () => 'Demo Mode (Checking)',
          error: (_, _) => 'Demo Mode (Inactive)',
        ),
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
            if (AppFeatures.demoModeEnabled) ...[
              Text(
                'Demo mode check',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Remote marker lookup'),
                  subtitle: Text(
                    demoModeState.when(
                      data: (isActive) => isActive
                          ? 'Marker file found. Demo mode is active.'
                          : 'Marker file not found. Demo mode is inactive.',
                      loading: () => 'Checking GitHub Pages marker file...',
                      error: (_, _) => 'Request failed. Demo mode is inactive.',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
