import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

// ألوان فيسبوك الرسمية
class FBColors {
  static const Color primaryBlue = Color(0xFF1877F2);
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color lightCard = Colors.white;
  static const Color lightInput = Color(0xFFE4E6EB);
  static const Color lightSubText = Color(0xFF65676B);
  
  static const Color darkBg = Color(0xFF18191A);
  static const Color darkCard = Color(0xFF242526);
  static const Color darkInput = Color(0xFF3A3B3C);
  static const Color darkSubText = Color(0xFFB0B3B8);
}

// قاعدة بيانات كافة الدول والمدن العربية الـ 22
const Map<String, List<String>> locationsData = {
  'فلسطين': ['القدس', 'غزة', 'خان يونس', 'رفح', 'دير البلح', 'شمال غزة', 'رام الله', 'البيرة', 'نابلس', 'الخليل', 'جنين', 'طولكرم', 'قلقيلية', 'بيت لحم', 'أريحا', 'طوباس', 'سلفيت'],
  'مصر': ['القاهرة', 'الإسكندرية', 'الجيزة', 'القليوبية', 'بورسعيد', 'السويس', 'المنصورة', 'طنطا', 'الزقازيق', 'دمياط', 'الإسماعيلية', 'أسوان', 'الأقصر', 'الفيوم', 'بني سويف', 'المنيا', 'أسيوط', 'سوهاج', 'قنا', 'الغردقة', 'شرم الشيخ', 'مرسى مطروح'],
  'الأردن': ['عمّان', 'إربد', 'الزرقاء', 'العقبة', 'السلط', 'مادبا', 'المفرق', 'الكرك', 'جرش', 'الطفيلة', 'معان', 'عجلون'],
  'سوريا': ['دمشق', 'ريف دمشق', 'حلب', 'حمص', 'حماة', 'اللاذقية', 'طرطوس', 'إدلب', 'درعا', 'السويداء', 'القنيطرة', 'دير الزور', 'الرقة', 'الحسكة'],
  'لبنان': ['بيروت', 'طرابلس', 'صيدا', 'صور', 'النبطية', 'زحلة', 'بعبدا', 'جونيه', 'جبيل', 'بعلبك', 'عاليه'],
  'العراق': ['بغداد', 'البصرة', 'الموصل', 'أربيل', 'كركوك', 'النجف', 'كربلاء', 'السليمانية', 'الحلة', 'الناصرية', 'العمارة', 'الرمادي', 'الفلوجة', 'الكوت'],
  'السعودية': ['الرياض', 'جدة', 'مكة المكرمة', 'المدينة المنورة', 'الدمام', 'الخبر', 'الظهران', 'تبوك', 'بريدة', 'عنيزة', 'أبها', 'خميس مشيط', 'حائل', 'نجران', 'جازان', 'الطائف', 'ينبع'],
  'الإمارات': ['أبوظبي', 'دبي', 'الشارقة', 'عجمان', 'رأس الخيمة', 'الفجيرة', 'أم القيوين', 'العين'],
  'الكويت': ['مدينة الكويت', 'حولي', 'الفروانية', 'الأحمدي', 'الجهراء', 'مبارك الكبير'],
  'قطر': ['الدوحة', 'الريان', 'الوكرة', 'الخور', 'الشحانية', 'الشمال'],
  'البحرين': ['المنامة', 'المحرق', 'الرفاع', 'سترة', 'مدينة عيسى', 'مدينة حمد'],
  'عُمان': ['مسقط', 'صلالة', 'صحار', 'نزوى', 'صور', 'الرستاق', 'البريمي'],
  'اليمن': ['صنعاء', 'عدن', 'تعز', 'الحديدة', 'إب', 'المكلا', 'ذمار', 'مأرب'],
  'السودان': ['الخرطوم', 'أم درمان', 'بحري', 'بورتسودان', 'كسلا', 'القضارف', 'واد مدني'],
  'ليبيا': ['طرابلس', 'بنغازي', 'مصراتة', 'البيضاء', 'الزاوية', 'طبرق', 'سرت', 'سبها'],
  'تونس': ['تونس العاصمة', 'منوبة', 'أريانة', 'بن عروس', 'صفاقس', 'سوسة', 'المنستير', 'بنزرت', 'القيروان', 'قابس', 'مدنين', 'نابل'],
  'الجزائر': ['الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة', 'البليدة', 'سطيف', 'باتنة', 'تلمسان', 'تيزي وزو', 'بجاية'],
  'المغرب': ['الرباط', 'الدار البيضاء', 'مراكش', 'فاس', 'طنجة', 'أغادير', 'مكناس', 'وجدة', 'القنيطرة', 'تطوان'],
  'موريتانيا': ['نواكشوط', 'نواذيبو', 'كيفة', 'روصو', 'أطار'],
  'الصومال': ['مقديشو', 'هرجيسا', 'بوساسو', 'كيسمايو'],
  'جيبوتي': ['جيبوتي العاصمة', 'علي صبيح', 'تاجورة'],
  'جزر القمر': ['موروني', 'موتسامودو', 'فومبوني'],
};

// تنسيق الوقت بالعربية مثل فيسبوك
String formatArabicTime(dynamic timestamp) {
  if (timestamp == null) return 'الآن';
  try {
    final date = DateTime.parse(timestamp.toString()).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${date.year}/${date.month}/${date.day}';
  } catch (_) {
    return 'مؤخراً';
  }
}

String getFirstChar(dynamic text, [String fallback = 'أ']) {
  if (text == null) return fallback;
  final str = text.toString().trim();
  return str.isNotEmpty ? str[0] : fallback;
}

ImageProvider? getUniversalImageProvider(String? source) {
  if (source == null || source.trim().isEmpty) return null;
  final str = source.trim();
  try {
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return NetworkImage(str);
    }
    if (str.startsWith('data:image') || (str.length > 200 && !str.startsWith('/'))) {
      final clean = str.contains(',') ? str.split(',').last : str;
      return MemoryImage(base64Decode(clean));
    }
    final file = File(str);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}
  return null;
}

Widget renderUniversalImage(dynamic source, {double? height, double? width, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius}) {
  if (source == null) return const SizedBox.shrink();
  final str = source.toString().trim();
  if (str.isEmpty) return const SizedBox.shrink();

  Widget imgWidget;
  try {
    if (str.startsWith('http://') || str.startsWith('https://')) {
      imgWidget = Image.network(str, height: height, width: width, fit: fit);
    } else if (str.startsWith('data:image') || (str.length > 200 && !str.startsWith('/'))) {
      final clean = str.contains(',') ? str.split(',').last : str;
      imgWidget = Image.memory(base64Decode(clean), height: height, width: width, fit: fit);
    } else {
      imgWidget = Image.file(File(str), height: height, width: width, fit: fit);
    }
  } catch (_) {
    return const SizedBox.shrink();
  }

  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: imgWidget);
  }
  return imgWidget;
}
