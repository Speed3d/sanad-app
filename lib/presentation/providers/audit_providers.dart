// ─────────────────────────────────────────────────────────────────────────────
// audit_providers.dart — Providers سجل المراجعة
//
// يُوفّر:
//   - recentAuditLogsProvider  — Stream تفاعلي لآخر 100 سجل
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';
import 'database_provider.dart';

part 'audit_providers.g.dart';

// ── Stream تفاعلي ─────────────────────────────────────────────────────────

/// آخر 100 سجل مراجعة — يتحدث تلقائياً
@riverpod
Stream<List<AuditLogData>> recentAuditLogs(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.auditLogDao.watchRecentLogs(limit: 100);
}

