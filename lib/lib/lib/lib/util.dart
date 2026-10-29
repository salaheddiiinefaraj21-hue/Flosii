import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class C {
  static const bg = Color(0xFF0A1F18);
  static const card = Color(0xFF11302A);
  static const line = Color(0xFF1E4A3D);
  static const green = Color(0xFF4ADE9B);
  static const red = Color(0xFFFF6B6B);
  static const gold = Color(0xFFF2B73C);
  static const text = Color(0xFFE8F5EE);
  static const muted = Color(0xFF8FB5A5);
  static const deep = Color(0xFF0B6B4A);
}

final NumberFormat _nf = NumberFormat('#,##0.##', 'en_US');
String money(double v) => _nf.format(v);

String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOf(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

const List<String> monthNames = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو',
  'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر'
];

const List<String> dayNames = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];

String niceDate(String s) {
  final d = dateOf(s);
  return '${dayNames[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]}';
}

String latinDigits(String s) {
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  var r = s;
  for (var i = 0; i < 10; i++) {
    r = r.replaceAll(arabic[i], '$i');
  }
  return r;
}

double parseAmount(String s) =>
    double.tryParse(latinDigits(s).trim().replaceAll(',', '.')) ?? 0;

ThemeData buildTheme() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: C.line),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.green,
      onPrimary: Color(0xFF06231A),
      secondary: C.gold,
      surface: C.card,
      error: C.red,
    ),
    appBarTheme: const AppBarTheme(backgroundColor: C.bg, elevation: 0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.bg,
      border: border,
      enabledBorder: border,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: C.card,
      indicatorColor: C.deep,
    ),
  );
}
