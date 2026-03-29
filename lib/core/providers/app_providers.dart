import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_features.dart';
import '../database/app_database.dart';
import '../network/app_dio.dart';

final dioProvider = Provider<Dio>((ref) {
  if (!AppFeatures.dioNetworkEnabled) {
    throw UnsupportedError('Dio network feature is disabled.');
  }
  return AppDio.create();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  if (!AppFeatures.driftDbEnabled) {
    throw UnsupportedError('Drift database feature is disabled.');
  }
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final appLogsProvider = FutureProvider<List<AppLog>>((ref) async {
  if (!AppFeatures.driftDbEnabled) {
    return const [];
  }
  final database = ref.watch(appDatabaseProvider);
  return database.getRecentLogs();
});
