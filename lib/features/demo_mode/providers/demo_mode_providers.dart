import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/config/app_features.dart';
import '../data/demo_mode_service.dart';

final demoModeServiceProvider = Provider<DemoModeService>((ref) {
  final service = DemoModeService();
  ref.onDispose(service.dispose);
  return service;
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

final demoModeActiveProvider = FutureProvider<bool>((ref) async {
  if (!AppFeatures.demoModeEnabled) {
    return false;
  }

  final baseUrl = AppFeatures.demoModeBaseUrlValue;
  if (baseUrl.isEmpty) {
    return false;
  }

  final platform = switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => '',
  };

  if (platform.isEmpty) {
    return false;
  }

  final packageInfo = await ref.watch(packageInfoProvider.future);
  final service = ref.watch(demoModeServiceProvider);

  return service.isDemoModeActive(
    baseUrl: baseUrl,
    bundleId: packageInfo.packageName,
    buildNumber: packageInfo.buildNumber,
    platform: platform,
  );
});
