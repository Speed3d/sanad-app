// ─────────────────────────────────────────────────────────────────────────────
// excel_sheet_reader.dart — قراءة ملف إكسل إلى شبكة نصوص + بصمته
//
// **لماذا هنا لا داخل شاشة الاستيراد؟**
//   شاشتا استيراد تقرآن ملفات إكسل: مصاريف السلف (Schema v5) وكشوف الرواتب
//   (Schema v7). ونسخُ منطق قراءة الخلايا في الثانية يعني أن أي نوع خلية
//   جديد يُعالَج في إحداهما ويُنسى في الأخرى — فيظهر التاريخ رقماً خاماً في
//   شاشة ويُقرأ صحيحاً في الأخرى بلا تفسير.
//
// **البصمة على المحتوى لا على الاسم**: إعادة تسمية الملف لا تُخفي أنه
//   استُورد من قبل. ونستعمل SHA-256 من `pointycastle` الموجودة أصلاً
//   للنسخ الاحتياطية المشفَّرة — بلا تبعية جديدة (القانون ٦).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

// حزمة excel تُصدِّر Border و TextSpan التي تتعارض مع نظيرتيهما في Flutter —
// نخفيهما لأن هذا الملف لا يحتاجهما أصلاً.
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:pointycastle/digests/sha256.dart';

/// حصيلة قراءة ملف إكسل
class ExcelSheetData {
  /// صفوف الورقة الأولى — **كلها بالطول نفسه** (تُحشى الناقصة بفراغات)
  ///
  /// التسوية ضرورية: خلية أخيرة فارغة تجعل الصف أقصر، فيرمي الوصول بمؤشر
  /// العمود `RangeError` على صفوف بعينها دون غيرها — وهو عطل يظهر في ملف
  /// ولا يظهر في آخر.
  final List<List<String>> rows;

  /// بصمة SHA-256 لمحتوى الملف (ست وستون حرفاً ست عشرياً)
  final String sha256;

  const ExcelSheetData({required this.rows, required this.sha256});

  bool get isEmpty => rows.isEmpty;
}

/// قارئ ملفات الإكسل — دوال نقيّة بلا واجهة
abstract final class ExcelSheetReader {
  /// بصمة SHA-256 لمحتوى ثنائي
  static String hashOf(Uint8List bytes) {
    final digest = SHA256Digest().process(bytes);
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// قيمة خلية كنصّ — تُغطّي كل أنواع خلايا حزمة `excel`
  ///
  /// التاريخ يُعاد بصيغة `YYYY/MM/DD` ليقرأه [SheetValueParser.parseDate]
  /// بلا حالة خاصة: الخلية المنسَّقة تاريخاً في إكسل تصل ككائن لا كنصّ.
  static String cellText(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return '${value.year}/${value.month.toString().padLeft(2, '0')}/'
          '${value.day.toString().padLeft(2, '0')}';
    }
    if (value is BoolCellValue) return value.value.toString();
    return value.toString();
  }

  /// قراءة الورقة الأولى من ملف `.xlsx` إلى شبكة نصوص مسوّاة
  ///
  /// يرمي [FormatException] إن كان الملف فارغاً أو غير قابل للقراءة.
  static ExcelSheetData read(Uint8List bytes) {
    final hash = hashOf(bytes);

    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (e) {
      throw FormatException('تعذّرت قراءة ملف الإكسل: $e');
    }

    if (book.tables.isEmpty) {
      throw const FormatException('الملف لا يحتوي أي ورقة عمل.');
    }
    final sheet = book.tables[book.tables.keys.first];
    if (sheet == null || sheet.rows.isEmpty) {
      throw const FormatException('الملف فارغ أو لا يحتوي على بيانات.');
    }

    final raw = sheet.rows
        .map((row) => row.map<String>((cell) => cellText(cell?.value)).toList())
        .toList();

    final maxLen = raw.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    final normalized = raw.map((r) {
      final padded = List<String>.from(r);
      padded.addAll(List.filled(maxLen - r.length, ''));
      return padded;
    }).toList();

    return ExcelSheetData(rows: normalized, sha256: hash);
  }
}
