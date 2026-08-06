// ─────────────────────────────────────────────────────────────────────────────
// audit_providers.dart — Providers سجل المراجعة
//
// يُوفّر:
//   - recentAuditLogsProvider  — Stream تفاعلي لآخر 100 سجل
//   - auditLogsByFilterProvider — Future مع فلاتر (جدول، تاريخ، نوع)
//   - auditLogCountProvider     — Future عدد السجلات الكلي
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

// ── استعلامات مع فلاتر ────────────────────────────────────────────────────

/// سجلات ضمن نطاق تاريخ وفلاتر اختيارية
@riverpod
Future<List<AuditLogData>> auditLogsByFilter(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
  String? action,
  int limit = 500,
  int offset = 0,
}) {
  final db = ref.watch(appDatabaseProvider);
  return db.auditLogDao.getLogsByDateRange(
    from: startDate,
    to: endDate,
    action: action,
    limit: limit,
    offset: offset,
  );
}

/// عدد السجلات الكلي — للـ Pagination
@riverpod
Future<int> auditLogCount(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.auditLogDao.countLogs();
}
