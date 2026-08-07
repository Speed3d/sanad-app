// ─────────────────────────────────────────────────────────────────────────────
// advance_repayment_test.dart — اختبارات سلامة تسديد السلف
//
// لماذا هذا الملف؟
//   كشف تدقيق 2026-08-06 أن تسديد السلف كان عرضة لسباق: الفحص يتم على نسخة
//   قديمة من السلفة خارج المعاملة، والكتابة مطلقة لا تراكمية. فسلفة 1,000,000
//   يمكن تسديدها 800,000 + 800,000 وينتهي total_repaid = 800,000 (تضيع دفعة).
//
//   الإصلاح: إعادة قراءة السلفة داخل المعاملة وحساب المجموع تراكمياً مع رفض
//   التجاوز. هذه الاختبارات تتحقق من المستوى الأساسي (DAO) الذي يضمن الذرّية.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sales_management/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int advanceId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // سلفة بقيمة 1,000,000
    advanceId = await db.employeesDao.insertAdvance(
      CashAdvancesCompanion.insert(
        amount: 1000000.0,
        advanceDate: DateTime(2026, 1, 1),
        externalPersonName: const Value('دائن خارجي'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('insertRepayment يحدّث total_repaid والحالة ذرياً', () async {
    await db.employeesDao.insertRepayment(
      repayment: CashAdvanceRepaymentsCompanion.insert(
        cashAdvanceId: advanceId,
        amount: 400000.0,
        repaymentDate: DateTime(2026, 2, 1),
      ),
      advanceId: advanceId,
      newTotalRepaid: 400000.0,
      newStatus: 'partial',
    );

    final advance = await db.employeesDao.getAdvanceById(advanceId);
    expect(advance!.totalRepaid, equals(400000.0));
    expect(advance.status, equals('partial'));

    final repayments = await db.employeesDao.getRepaymentsByAdvance(advanceId);
    expect(repayments.length, equals(1));
  });

  test('التسديد الكامل يجعل الحالة paid', () async {
    await db.employeesDao.insertRepayment(
      repayment: CashAdvanceRepaymentsCompanion.insert(
        cashAdvanceId: advanceId,
        amount: 1000000.0,
        repaymentDate: DateTime(2026, 2, 1),
      ),
      advanceId: advanceId,
      newTotalRepaid: 1000000.0,
      newStatus: 'paid',
    );

    final advance = await db.employeesDao.getAdvanceById(advanceId);
    expect(advance!.status, equals('paid'));
    expect(advance.totalRepaid, equals(1000000.0));
  });

  test('حساب المتبقي تراكمياً من عدة أقساط (يحاكي المنطق المُصحَّح)', () async {
    // نحاكي ما تفعله repayAdvance الآن: نقرأ الطازج ونحسب تراكمياً
    Future<void> repay(double amount) async {
      final fresh = await db.employeesDao.getAdvanceById(advanceId);
      final newRepaid = fresh!.totalRepaid + amount;
      final remaining = fresh.amount - fresh.totalRepaid;
      // الفحص التراكمي يمنع التجاوز
      expect(amount <= remaining + 0.001, isTrue,
          reason: 'يجب ألا يتجاوز القسط المتبقي الطازج');
      await db.employeesDao.insertRepayment(
        repayment: CashAdvanceRepaymentsCompanion.insert(
          cashAdvanceId: advanceId,
          amount: amount,
          repaymentDate: DateTime(2026, 2, 1),
        ),
        advanceId: advanceId,
        newTotalRepaid: newRepaid,
        newStatus: newRepaid >= fresh.amount - 0.001 ? 'paid' : 'partial',
      );
    }

    await repay(600000.0);
    await repay(400000.0);

    final advance = await db.employeesDao.getAdvanceById(advanceId);
    // المجموع الصحيح = 1,000,000 (لا تضيع أي دفعة)
    expect(advance!.totalRepaid, equals(1000000.0));
    expect(advance.status, equals('paid'));
  });
}
