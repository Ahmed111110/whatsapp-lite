import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 1. محرك التبديل الملوكي (Theme Notifier)
// ==========================================
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

Future<void> initAppTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('atheer_is_dark') ?? true;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleAppTheme() async {
  final prefs = await SharedPreferences.getInstance();
  if (themeNotifier.value == ThemeMode.dark) {
    themeNotifier.value = ThemeMode.light;
    await prefs.setBool('atheer_is_dark', false);
  } else {
    themeNotifier.value = ThemeMode.dark;
    await prefs.setBool('atheer_is_dark', true);
  }
}

// ==========================================
// 2. باليت الألوان الملوكية الذهبية (Royal Gold)
// ==========================================
class FBColors {
  // الذهب الملوكي الرئيسي في كلا الوضعين
  static const Color primaryBlue = Color(0xFFD4AF37); // Royal Gold
  static const Color royalGold = Color(0xFFD4AF37);
  static const Color champagneGold = Color(0xFFE5C158);
  static const Color darkAntiqueGold = Color(0xFFA67C1E);

  // التدرج الذهبي الفاخر
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFF3E7BE), Color(0xFFD4AF37), Color(0xFFA67C1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // الوضع الليلي الملوكي (Obsidian & Gold)
  static const Color darkBg = Color(0xFF0D0D11);
  static const Color darkCard = Color(0xFF16161B);
  static const Color darkInput = Color(0xFF222228);
  static const Color darkSubText = Color(0xFFA8A396);
  static const Color darkBorder = Color(0xFF2E2A20);

  // الوضع النهاري الملوكي اللؤلؤي (Pearl & Antique Gold)
  static const Color lightBg = Color(0xFFFBF9F4);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF2EFE9);
  static const Color lightSubText = Color(0xFF6E685E);
  static const Color lightBorder = Color(0xFFEAE3D2);
}

// ==========================================
// 3. معالج الصور والوقت
// ==========================================
ImageProvider getUniversalImageProvider(dynamic url) {
  if (url == null || url.toString().trim().isEmpty) {
    return const AssetImage('assets/images/default_avatar.png');
  }
  final s = url.toString().trim();
  if (s.startsWith('data:image')) {
    final b64 = s.split(',').last;
    return MemoryImage(base64Decode(b64));
  }
  return NetworkImage(s);
}

Widget renderUniversalImage(dynamic url, {double? width, double? height, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius}) {
  if (url == null || url.toString().trim().isEmpty) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.12),
      child: const Icon(Icons.image, color: FBColors.royalGold),
    );
  }
  final s = url.toString().trim();
  Widget img;
  if (s.startsWith('data:image')) {
    img = Image.memory(base64Decode(s.split(',').last), width: width, height: height, fit: fit);
  } else {
    img = Image.network(
      s,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.black26,
        child: const Icon(Icons.broken_image, color: FBColors.royalGold),
      ),
    );
  }
  return borderRadius != null ? ClipRRect(borderRadius: borderRadius, child: img) : img;
}

String getFirstChar(dynamic name) {
  if (name == null || name.toString().isEmpty) return 'أ';
  return name.toString().trim().characters.first.toUpperCase();
}

String formatArabicTime(dynamic timeStr) {
  if (timeStr == null || timeStr.toString().isEmpty) return '';
  try {
    final dt = DateTime.parse(timeStr.toString()).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    return '${dt.day}/${dt.month}';
  } catch (_) {
    return '';
  }
}
