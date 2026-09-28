import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);
final supabase = Supabase.instance.client;

// =========================================================================
// قاعدة بيانات كافة الدول والمدن العربية الـ 22
// =========================================================================
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jflrgszsqhptcxsxbaej.supabase.co',
    anonKey: 'sb_publishable_wgWmv7UJ4lbH_5m3UZ8FSg_l8rbAADB',
  );

  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('atheer_theme_dark') ?? true;

  runApp(const AtheerApp());
}

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
    if (str.startsWith('data:image') || (str.length > 200 && !str.startsWith('/'))) {
      final clean = str.contains(',') ? str.split(',').last : str;
      return MemoryImage(base64Decode(clean));
    }
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return NetworkImage(str);
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
    if (str.startsWith('data:image') || (str.length > 200 && !str.startsWith('/'))) {
      final clean = str.contains(',') ? str.split(',').last : str;
      imgWidget = Image.memory(base64Decode(clean), height: height, width: width, fit: fit);
    } else if (str.startsWith('http://') || str.startsWith('https://')) {
      imgWidget = Image.network(str, height: height, width: width, fit: fit);
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

class AtheerApp extends StatelessWidget {
  const AtheerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'أَثِـيـر',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: FBColors.lightBg,
            primaryColor: FBColors.primaryBlue,
            cardColor: FBColors.lightCard,
            dividerColor: const Color(0xFFCED0D4),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Color(0xFF050505)),
              titleTextStyle: TextStyle(color: FBColors.primaryBlue, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: FBColors.darkBg,
            primaryColor: FBColors.primaryBlue,
            cardColor: FBColors.darkCard,
            dividerColor: const Color(0xFF3E4042),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF242526),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) {
          return const FacebookStyleMain();
        }
        return const AuthScreen();
      },
    );
  }
}

// ==========================================
// 1. شاشة التسجيل بهوية وشعار "أثير" الخاص
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  final _eduCtrl = TextEditingController();

  String _selectedCountry = 'فلسطين';
  String _selectedCity = 'خان يونس';
  String _selectedBirthDate = '';
  String? _avatarBase64;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 35, maxWidth: 450);
    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      setState(() => _avatarBase64 = base64Encode(bytes));
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: FBColors.primaryBlue, onPrimary: Colors.white, surface: Color(0xFF242526)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء البريد وكلمة المرور')));
      return;
    }
    if (!_isLogin && (name.isEmpty || _selectedBirthDate.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إكمال بيانات الاسم وتاريخ الميلاد')));
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await supabase.auth.signUp(email: email, password: pass);
        if (res.user != null) {
          final isFounder = email.toLowerCase().contains('anas') || name.contains('أنس');
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'name': name,
            'avatar_url': _avatarBase64 ?? '',
            'country': _selectedCountry,
            'city': _selectedCity,
            'location': '$_selectedCountry، $_selectedCity',
            'birth_date': _selectedBirthDate,
            'work': _workCtrl.text.trim(),
            'education': _eduCtrl.text.trim(),
            'bio': isFounder ? 'المؤسس والمطور لمنصة أثير 👑⚡' : 'عضو في فضاء أثير 🌌',
            'is_founder': isFounder,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCities = locationsData[_selectedCountry] ?? ['المركز'];
    final safeCity = currentCities.contains(_selectedCity) ? _selectedCity : currentCities.first;

    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          child: Column(
            children: [
              // الشعار الخاص والفريد بتطبيق أثير 🌌
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1877F2), Color(0xFF00C6FF), Color(0xFF8A2BE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1877F2).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: const Icon(Icons.blur_on_rounded, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('أَثِـيـر', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: FBColors.primaryBlue, letterSpacing: 2)),
              const Text('فضاء التواصل السحابي المضيء', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF242526),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF3A3B3C),
                          backgroundImage: getUniversalImageProvider(_avatarBase64),
                          child: _avatarBase64 == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.camera_alt, color: FBColors.primaryBlue, size: 24), Text('صورتك', style: TextStyle(fontSize: 10, color: Colors.white70))],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fbInputDecor('الاسم الكامل المعروض', Icons.person_outline),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: locationsData.containsKey(_selectedCountry) ? _selectedCountry : 'فلسطين',
                              dropdownColor: const Color(0xFF242526),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _fbInputDecor('الدولة', Icons.flag_outlined),
                              items: locationsData.keys.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCountry = val;
                                    _selectedCity = locationsData[val]!.first;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: safeCity,
                              dropdownColor: const Color(0xFF242526),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _fbInputDecor('المدينة', Icons.location_city_outlined),
                              items: currentCities.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCity = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: const Color(0xFF3A3B3C), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: FBColors.primaryBlue, size: 20),
                              const SizedBox(width: 10),
                              Text(_selectedBirthDate.isEmpty ? 'تاريخ الميلاد (اختر من الروزنامة)' : _selectedBirthDate, style: TextStyle(color: _selectedBirthDate.isEmpty ? Colors.white38 : Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _workCtrl, style: const TextStyle(color: Colors.white), decoration: _fbInputDecor('العمل والمهنة', Icons.work_outline)),
                      const SizedBox(height: 10),
                      TextField(controller: _eduCtrl, style: const TextStyle(color: Colors.white), decoration: _fbInputDecor('التعليم والدراسة', Icons.school_outlined)),
                      const SizedBox(height: 10),
                    ],
                    TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: _fbInputDecor('البريد الإلكتروني', Icons.email_outlined)),
                    const SizedBox(height: 10),
                    TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _fbInputDecor('كلمة السر', Icons.lock_outline)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _loading ? null : _submit,
                        child: _loading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد في أثير', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'ليس لديك حساب؟ أنشئ حساباً جديداً الآن' : 'هل لديك حساب بالفعل؟ سجّل دخولك', style: const TextStyle(color: FBColors.primaryBlue, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fbInputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF3A3B3C),
      prefixIcon: Icon(icon, color: FBColors.primaryBlue, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}

// =========================================================================
// 2. الهيكل الرئيسي
// =========================================================================
class FacebookStyleMain extends StatefulWidget {
  const FacebookStyleMain({super.key});

  @override
  State<FacebookStyleMain> createState() => _FacebookStyleMainState();
}

class _FacebookStyleMainState extends State<FacebookStyleMain> {
  int _tabIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    SocialHubScreen(),
    ChatsListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_tabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? FBColors.darkCard : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFCED0D4), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: FBColors.primaryBlue,
          unselectedItemColor: isDark ? FBColors.darkSubText : FBColors.lightSubText,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 26), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.group, size: 26), label: 'المجتمع'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble, size: 24), label: 'الدردشات'),
            BottomNavigationBarItem(icon: Icon(Icons.menu, size: 26), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 3. خلاصة المنشورات مع الكاش أوفلاين + إصلاح الإعجاب والمعاينة
// =========================================================================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  final Set<String> _hiddenPostIds = {};
  final Set<String> _savedPostIds = {};
  bool _loading = true;
  Map<String, dynamic>? _myProfile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFromCacheFirst();
    _loadAll();
  }

  // تحميل الكاش المحلي أوفلاين فوراً قبل أي اتصال
  Future<void> _loadFromCacheFirst() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPosts = prefs.getString('atheer_cached_posts');
    final cachedStories = prefs.getString('atheer_cached_stories');
    final cachedProfile = prefs.getString('atheer_cached_profile');

    if (cachedPosts != null && mounted) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(jsonDecode(cachedPosts));
        _loading = false;
      });
    }
    if (cachedStories != null && mounted) {
      setState(() => _stories = List<Map<String, dynamic>>.from(jsonDecode(cachedStories)));
    }
    if (cachedProfile != null && mounted) {
      setState(() => _myProfile = jsonDecode(cachedProfile));
    }
  }

  Future<void> _loadAll() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final p = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        if (p != null) {
          _myProfile = p;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('atheer_cached_profile', jsonEncode(p));
        }
      }
      final postsRes = await supabase.from('posts').select().order('created_at', ascending: false);
      final storiesRes = await supabase.from('stories').select().order('created_at', ascending: false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_cached_posts', jsonEncode(postsRes));
      await prefs.setString('atheer_cached_stories', jsonEncode(storiesRes));

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(postsRes);
          _stories = List<Map<String, dynamic>>.from(storiesRes);
          _loading = false;
        });
      }
    } catch (_) {
      // في حال انقطاع النت يبقى الكاش كما هو بدون توقف
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addStory() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 35, maxWidth: 650);
    final textCtrl = TextEditingController();
    String? b64;
    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      b64 = base64Encode(bytes);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة إلى القصة 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (b64 != null) renderUniversalImage(b64, height: 140, borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 10),
            TextField(controller: textCtrl, decoration: const InputDecoration(hintText: 'اكتب نصاً لقصتك...')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
            onPressed: () async {
              final user = supabase.auth.currentUser;
              await supabase.from('stories').insert({
                'user_id': user?.id,
                'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                'avatar_url': _myProfile?['avatar_url'] ?? '',
                'image_url': b64 ?? '',
                'text': textCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              _loadAll();
            },
            child: const Text('مشاركة في القصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _viewStory(Map<String, dynamic> story) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StoryViewerDialog(story: story),
    );
  }

  // =========================================================================
  // نظام الإعجاب المنطقي الصحيح (Toggle Like) - نقرة واحدة لكل مستخدم
  // =========================================================================
  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    }

    List likedUsers = (reactions['liked_users'] is List) ? List.from(reactions['liked_users']) : [];
    int currentCount = post['likes_count'] ?? 0;

    final bool alreadyLiked = likedUsers.contains(myId);

    if (alreadyLiked) {
      likedUsers.remove(myId);
      currentCount = (currentCount > 0) ? currentCount - 1 : 0;
    } else {
      likedUsers.add(myId);
      currentCount = currentCount + 1;
    }

    reactions['liked_users'] = likedUsers;

    setState(() {
      post['likes_count'] = currentCount;
      post['reactions'] = reactions;
    });

    try {
      await supabase.from('posts').update({
        'likes_count': currentCount,
        'reactions': reactions,
      }).eq('id', post['id']);
    } catch (_) {}
  }

  Future<void> _handleReaction(Map<String, dynamic> post, String reactionType) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    }

    List likedUsers = (reactions['liked_users'] is List) ? List.from(reactions['liked_users']) : [];
    int totalLikes = post['likes_count'] ?? 0;

    if (!likedUsers.contains(myId)) {
      likedUsers.add(myId);
      totalLikes += 1;
    }

    reactions['liked_users'] = likedUsers;
    reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;

    setState(() {
      post['likes_count'] = totalLikes;
      post['reactions'] = reactions;
    });

    try {
      await supabase.from('posts').update({
        'likes_count': totalLikes,
        'reactions': reactions,
      }).eq('id', post['id']);
    } catch (_) {}
  }

  // =========================================================================
  // نافذة المعاينة المكبرة بالضغط المطول على المنشور
  // =========================================================================
  void _showPostPreviewModal(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FBColors.primaryBlue.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: getUniversalImageProvider(post['author_avatar']),
                        child: (post['author_avatar'] == null || post['author_avatar'] == '') ? Text(getFirstChar(post['author_name'])) : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${formatArabicTime(post['created_at'])} • ${post['visibility'] == 'friends' ? 'للأصدقاء 👥' : 'عام 🌐'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if ((post['text'] ?? '').isNotEmpty)
                    Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, height: 1.45)),
                  if ((post['image_url'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: renderUniversalImage(post['image_url'], height: 220, width: double.infinity, borderRadius: BorderRadius.circular(12)),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue.withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.copy_rounded, color: FBColors.primaryBlue, size: 18),
                          label: const Text('نسخ المنشور', style: TextStyle(color: FBColors.primaryBlue, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: post['text'] ?? ''));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور بنجاح!')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.share, color: Colors.grey, size: 18),
                          label: const Text('مشاركة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر أثير 🌌'));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز الرابط للمشاركة!')));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFBReactionsSummary(Map<String, dynamic> post) {
    final int count = post['likes_count'] ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.thumb_up, color: Colors.white, size: 11),
              ),
              Positioned(
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFFA3E3E), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Text('$count', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text('تعليقات ومشاركات', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? FBColors.darkSubText : FBColors.lightSubText)),
        ],
      ),
    );
  }

  void _showReactionsOverlay(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            bottom: 120,
            right: 40,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF242526), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
                child: Row(
                  children: [
                    _reactionItem('👍', 'like', post, ctx),
                    _reactionItem('❤️', 'love', post, ctx),
                    _reactionItem('😨', 'scare', post, ctx),
                    _reactionItem('😡', 'angry', post, ctx),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionItem(String emoji, String type, Map<String, dynamic> post, BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _handleReaction(post, type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  void _showPostMenu(Map<String, dynamic> post) {
    final myId = supabase.auth.currentUser?.id;
    final String? postUserId = post['user_id']?.toString();
    final bool isOwner = (myId != null && postUserId != null && myId == postUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: FBColors.primaryBlue),
                title: const Text('تعديل المنشور', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  final editCtrl = TextEditingController(text: post['text']);
                  showDialog(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('تعديل المنشور ✏️'),
                      content: TextField(controller: editCtrl, maxLines: 3),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                          onPressed: () async {
                            await supabase.from('posts').update({'text': editCtrl.text.trim()}).eq('id', post['id']);
                            Navigator.pop(d);
                            _loadAll();
                          },
                          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF31A24C)),
                title: Text(post['visibility'] == 'friends' ? 'تغيير الجمهور إلى: عام 🌐' : 'تغيير الجمهور إلى: للأصدقاء فقط 👥', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final nextVis = post['visibility'] == 'friends' ? 'public' : 'friends';
                  await supabase.from('posts').update({'visibility': nextVis}).eq('id', post['id']);
                  _loadAll();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('حذف المنشور نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('posts').delete().eq('id', post['id']);
                  _loadAll();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded, color: FBColors.primaryBlue),
                title: Text(_savedPostIds.contains(post['id'].toString()) ? 'إلغاء حفظ المنشور' : 'حفظ المنشور 📌', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  final pid = post['id'].toString();
                  setState(() {
                    if (_savedPostIds.contains(pid)) {
                      _savedPostIds.remove(pid);
                    } else {
                      _savedPostIds.add(pid);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المنشور في محفوظاتك! 📌')));
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Colors.amber),
                title: const Text('إخفاء المنشور 👁️', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _hiddenPostIds.add(post['id'].toString()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.grey),
                title: const Text('نسخ نص المنشور'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: post['text'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص بنجاح!')));
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visiblePosts = _posts.where((p) => !_hiddenPostIds.contains(p['id'].toString())).toList();
    final dividerBg = isDark ? FBColors.darkBg : FBColors.lightBg;
    final myId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أَثِـيـر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: FBColors.primaryBlue)),
        actions: [
          _fbCircleIcon(Icons.search, () {}),
          const SizedBox(width: 8),
          _fbCircleIcon(Icons.chat_bubble_rounded, () {
            final parent = context.findAncestorStateOfType<_FacebookStyleMainState>();
            if (parent != null) parent.setState(() => parent._tabIndex = 2);
          }),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.only(top: 12, left: 14, right: 14, bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_myProfile != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: _myProfile!['id'], initialProfile: _myProfile)));
                                }
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url']),
                                child: (_myProfile?['avatar_url'] == null || _myProfile?['avatar_url'] == '') ? Text(getFirstChar(_myProfile?['name'])) : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showCreatePostModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? FBColors.darkInput : FBColors.lightInput,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text('بِمَ تفكّر؟', style: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 14.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _fbQuickAction(Icons.videocam, Colors.red, 'بث مباشر', () {}),
                            Container(width: 1, height: 18, color: Colors.grey.withOpacity(0.3)),
                            _fbQuickAction(Icons.photo_library, const Color(0xFF45BD62), 'صورة', _showCreatePostModal),
                            Container(width: 1, height: 18, color: Colors.grey.withOpacity(0.3)),
                            _fbQuickAction(Icons.emoji_emotions, const Color(0xFFF7B125), 'شعور/نشاط', () {}),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(height: 8, color: dividerBg),

                  Container(
                    color: Theme.of(context).cardColor,
                    height: 195,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 10),
                        _buildCreateStoryCard(isDark),
                        ..._stories.map((st) => _buildStoryCard(st, isDark)),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),

                  Container(height: 8, color: dividerBg),

                  // قائمة المنشورات مع التفاعل الصحيح والمعاينة بالضغط المطول
                  ...visiblePosts.map((post) {
                    final bool isFounder = post['is_founder'] == true;
                    final Map reactions = (post['reactions'] is Map) ? post['reactions'] : {};
                    final List likedUsers = (reactions['liked_users'] is List) ? reactions['liked_users'] : [];
                    final bool isLikedByMe = (myId != null && likedUsers.contains(myId));

                    return GestureDetector(
                      onLongPress: () => _showPostPreviewModal(post),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 6),
                              child: Row(
                                children: [
                                  // النقر على الصورة ينقل لصفحة الكاتب
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: post['user_id'] ?? '', fallbackName: post['author_name'], fallbackAvatar: post['author_avatar'])));
                                    },
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: getUniversalImageProvider(post['author_avatar']),
                                      child: (post['author_avatar'] == null || post['author_avatar'] == '') ? Text(getFirstChar(post['author_name'])) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // النقر على الاسم ينقل لصفحة الكاتب
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: post['user_id'] ?? '', fallbackName: post['author_name'], fallbackAvatar: post['author_avatar'])));
                                          },
                                          child: Row(
                                            children: [
                                              Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              if (isFounder) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: FBColors.primaryBlue, size: 16),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(formatArabicTime(post['created_at']), style: TextStyle(fontSize: 12, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                                            Icon(post['visibility'] == 'friends' ? Icons.group : Icons.public, size: 13, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                    onPressed: () => _showPostMenu(post),
                                  ),
                                ],
                              ),
                            ),

                            if ((post['text'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.35)),
                              ),

                            if ((post['image_url'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: renderUniversalImage(post['image_url'], width: double.infinity, fit: BoxFit.cover),
                              ),

                            _buildFBReactionsSummary(post),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Divider(height: 1),
                            ),

                            // شريط الأزرار التفاعلية
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onLongPress: () => _showReactionsOverlay(post),
                                      onTap: () => _toggleLike(post),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isLikedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                              size: 18,
                                              color: isLikedByMe ? FBColors.primaryBlue : (isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'أعجبني',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isLikedByMe ? FBColors.primaryBlue : (isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openComments(post['id']),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.chat_bubble_outline, size: 18, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            const SizedBox(width: 6),
                                            Text('تعليق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر تطبيق أثير 🌌'));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور لمشاركته!')));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.share_outlined, size: 18, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            const SizedBox(width: 6),
                                            Text('مشاركة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _fbCircleIcon(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _fbQuickAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard(bool isDark) {
    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _addStory,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 115,
                width: double.infinity,
                child: renderUniversalImage(_myProfile?['avatar_url'], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 42,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              child: Text('إنشاء قصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> st, bool isDark) {
    return GestureDetector(
      onTap: () => _viewStory(st),
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF242526),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: renderUniversalImage(st['image_url'], fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: getUniversalImageProvider(st['avatar_url']),
                    child: (st['avatar_url'] == null || st['avatar_url'] == '') ? Text(getFirstChar(st['author_name']), style: const TextStyle(fontSize: 10)) : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  st['author_name'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostModal() {
    final textCtrl = TextEditingController();
    String? b64;
    String vis = 'public';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setM) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 20, backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url'])),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_myProfile?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: vis,
                          underline: const SizedBox(),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'public', child: Text('عام 🌐', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'friends', child: Text('الأصدقاء 👥', style: TextStyle(fontSize: 11))),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => vis = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'بِمَ تفكّر؟', border: InputBorder.none)),
              if (b64 != null) renderUniversalImage(b64, height: 140, borderRadius: BorderRadius.circular(10)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Color(0xFF45BD62)),
                    onPressed: () async {
                      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 35, maxWidth: 650);
                      if (f != null) {
                        final bytes = await File(f.path).readAsBytes();
                        setM(() => b64 = base64Encode(bytes));
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      if (textCtrl.text.trim().isNotEmpty) {
                        final user = supabase.auth.currentUser;
                        await supabase.from('posts').insert({
                          'user_id': user?.id,
                          'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                          'author_avatar': _myProfile?['avatar_url'] ?? '',
                          'is_founder': _myProfile?['is_founder'] ?? false,
                          'text': textCtrl.text.trim(),
                          'image_url': b64 ?? '',
                          'visibility': vis,
                          'likes_count': 0,
                          'reactions': {'like': 0, 'love': 0, 'scare': 0, 'angry': 0, 'liked_users': []},
                        });
                        Navigator.pop(ctx);
                        _loadAll();
                      }
                    },
                    child: const Text('نشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openComments(dynamic postId) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setC) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
          child: Column(
            children: [
              const Text('التعليقات 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: supabase.from('comments').select().eq('post_id', postId.toString()).order('created_at', ascending: true),
                  builder: (cx, AsyncSnapshot snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data as List;
                    if (list.isEmpty) return const Center(child: Text('كن أول من يعلّق على هذا المنشور!'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (cx, i) => ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: getUniversalImageProvider(list[i]['author_avatar']),
                          child: (list[i]['author_avatar'] == null || list[i]['author_avatar'] == '') ? Text(getFirstChar(list[i]['author_name'])) : null,
                        ),
                        title: Text(list[i]['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(list[i]['content'] ?? ''),
                        trailing: Text(formatArabicTime(list[i]['created_at']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً...',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? FBColors.darkInput : FBColors.lightInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: FBColors.primaryBlue),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isNotEmpty) {
                        final u = supabase.auth.currentUser;
                        await supabase.from('comments').insert({
                          'post_id': postId.toString(),
                          'user_id': u?.id,
                          'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                          'author_avatar': _myProfile?['avatar_url'] ?? '',
                          'content': commentCtrl.text.trim(),
                        });
                        commentCtrl.clear();
                        setC(() {});
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// عارض الستوري السينمائي
// =========================================================================
class StoryViewerDialog extends StatefulWidget {
  final Map<String, dynamic> story;
  const StoryViewerDialog({super.key, required this.story});

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog> {
  final TextEditingController _replyCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendStoryReaction(String emoji) async {
    final myId = supabase.auth.currentUser?.id;
    final targetId = widget.story['user_id'];
    if (myId == null || targetId == null) return;

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': targetId,
      'content': '$emoji تفاعل مع قصتك',
      'image_url': widget.story['image_url'] ?? '',
      'is_deleted': false,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال تفاعل $emoji في الماسنجر! 💬')));
    }
  }

  Future<void> _sendStoryReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final myId = supabase.auth.currentUser?.id;
    final targetId = widget.story['user_id'];
    if (myId == null || targetId == null) return;

    setState(() => _sending = true);
    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': targetId,
      'content': 'رد على القصة: $text',
      'image_url': widget.story['image_url'] ?? '',
      'is_deleted': false,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ردك في رسائل الماسنجر! ✉️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Dialog(
      backgroundColor: const Color(0xFF18191A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: getUniversalImageProvider(story['avatar_url']),
                    child: (story['avatar_url'] == null || story['avatar_url'] == '') ? Text(getFirstChar(story['author_name'])) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story['author_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(formatArabicTime(story['created_at']), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if ((story['image_url'] ?? '').isNotEmpty) renderUniversalImage(story['image_url'], width: double.infinity, fit: BoxFit.contain),
                    if ((story['text'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(story['text'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _storyReactionBtn('❤️'),
                  _storyReactionBtn('🔥'),
                  _storyReactionBtn('😂'),
                  _storyReactionBtn('👏'),
                  _storyReactionBtn('😮'),
                  _storyReactionBtn('😢'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: const Color(0xFF3A3B3C), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'إرسال رسالة إلى صاحب القصة...',
                          hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: FBColors.primaryBlue)) : const Icon(Icons.send_rounded, color: FBColors.primaryBlue),
                    onPressed: _sending ? null : _sendStoryReply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyReactionBtn(String emoji) {
    return InkWell(
      onTap: () => _sendStoryReaction(emoji),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

// =========================================================================
// 4. المجتمع والأصدقاء
// =========================================================================
class SocialHubScreen extends StatefulWidget {
  const SocialHubScreen({super.key});

  @override
  State<SocialHubScreen> createState() => _SocialHubScreenState();
}

class _SocialHubScreenState extends State<SocialHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _friendRequests = [];
  Set<String> _myFollowingIds = {};
  Set<String> _myFriendIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadSocial();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSocial() async {
    setState(() => _loading = true);
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final users = await supabase.from('profiles').select().neq('id', myId);
      final follows = await supabase.from('follows').select('following_id').eq('follower_id', myId);

      final reqs = await supabase.from('friendships').select().eq('receiver_id', myId).eq('status', 'pending');
      final friends1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId).eq('status', 'accepted');
      final friends2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId).eq('status', 'accepted');

      final friendSet = <String>{};
      for (var f in friends1) { friendSet.add(f['receiver_id'].toString()); }
      for (var f in friends2) { friendSet.add(f['sender_id'].toString()); }

      if (mounted) {
        setState(() {
          _allUsers = List<Map<String, dynamic>>.from(users);
          _friendRequests = List<Map<String, dynamic>>.from(reqs);
          _myFollowingIds = (follows as List).map((e) => e['following_id'].toString()).toSet();
          _myFriendIds = friendSet;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(String id) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    if (_myFollowingIds.contains(id)) {
      await supabase.from('follows').delete().match({'follower_id': myId, 'following_id': id});
      setState(() => _myFollowingIds.remove(id));
    } else {
      await supabase.from('follows').insert({'follower_id': myId, 'following_id': id});
      setState(() => _myFollowingIds.add(id));
    }
  }

  Future<void> _sendFriendRequest(String targetId) async {
    final myId = supabase.auth.currentUser?.id;
    await supabase.from('friendships').insert({'sender_id': myId, 'receiver_id': targetId, 'status': 'pending'});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الصداقة!')));
  }

  Future<void> _handleRequest(String reqId, String newStatus) async {
    await supabase.from('friendships').update({'status': newStatus}).eq('id', reqId);
    _loadSocial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمع والأصدقاء 👥'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FBColors.primaryBlue,
          tabs: [
            const Tab(text: 'استكشاف'),
            Tab(text: 'الطلبات (${_friendRequests.length})'),
            const Tab(text: 'أصدقائي'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                ListView.builder(
                  itemCount: _allUsers.length,
                  itemBuilder: (ctx, i) {
                    final u = _allUsers[i];
                    final String uid = u['id'];
                    final bool isF = _myFollowingIds.contains(uid);
                    final bool isFriend = _myFriendIds.contains(uid);

                    return ListTile(
                      leading: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: uid, initialProfile: u))),
                        child: CircleAvatar(
                          backgroundImage: getUniversalImageProvider(u['avatar_url']),
                          child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'])) : null,
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: uid, initialProfile: u))),
                        child: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      subtitle: Text('${u['location'] ?? ''} • ${u['work'] ?? ''}', maxLines: 1),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isFriend ? Icons.handshake : Icons.person_add_alt_1, color: isFriend ? Colors.green : FBColors.primaryBlue),
                            onPressed: isFriend ? null : () => _sendFriendRequest(uid),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isF ? Colors.grey.withOpacity(0.3) : FBColors.primaryBlue),
                            onPressed: () => _toggleFollow(uid),
                            child: Text(isF ? 'تتابعه' : 'متابعة', style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _friendRequests.isEmpty
                    ? const Center(child: Text('لا توجد طلبات صداقة معلقة'))
                    : ListView.builder(
                        itemCount: _friendRequests.length,
                        itemBuilder: (ctx, i) {
                          final r = _friendRequests[i];
                          return ListTile(
                            title: const Text('طلب صداقة جديد'),
                            subtitle: Text(formatArabicTime(r['created_at'])),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                                  onPressed: () => _handleRequest(r['id'], 'accepted'),
                                  child: const Text('قبول', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2)),
                                  onPressed: () => _handleRequest(r['id'], 'rejected'),
                                  child: const Text('رفض', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                _myFriendIds.isEmpty
                    ? const Center(child: Text('لم تقم بإضافة أصدقاء بعد'))
                    : ListView(
                        children: _allUsers.where((u) => _myFriendIds.contains(u['id'])).map((u) {
                          return ListTile(
                            leading: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: u['id'], initialProfile: u))),
                              child: CircleAvatar(
                                backgroundImage: getUniversalImageProvider(u['avatar_url']),
                                child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'], 'ص')) : null,
                              ),
                            ),
                            title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(u['location'] ?? ''),
                            trailing: const Icon(Icons.check_circle, color: Colors.green),
                          );
                        }).toList(),
                      ),
              ],
            ),
    );
  }
}

// =========================================================================
// 5. محادثات Messenger مع الكاش أوفلاين
// =========================================================================
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _users = [];
  Set<String> _friendIds = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadFromCache();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('atheer_cached_chat_users');
    if (cached != null && mounted) {
      setState(() => _users = List<Map<String, dynamic>>.from(jsonDecode(cached)));
    }
  }

  Future<void> _loadUsers() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final res = await supabase.from('profiles').select().neq('id', myId);
      final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId).eq('status', 'accepted');
      final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId).eq('status', 'accepted');
      final s = <String>{};
      for (var f in f1) { s.add(f['receiver_id'].toString()); }
      for (var f in f2) { s.add(f['sender_id'].toString()); }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_cached_chat_users', jsonEncode(res));

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(res);
          _friendIds = s;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final friendsList = _users.where((u) => _friendIds.contains(u['id'])).toList();
    final nonFriendsList = _users.where((u) => !_friendIds.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات 💬', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FBColors.primaryBlue,
          tabs: [
            Tab(text: 'الأصدقاء (${friendsList.length})'),
            Tab(text: 'طلبات المراسلة (${nonFriendsList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _chatUserList(friendsList, false),
          _chatUserList(nonFriendsList, true),
        ],
      ),
    );
  }

  Widget _chatUserList(List<Map<String, dynamic>> list, bool isRequest) {
    if (list.isEmpty) return Center(child: Text(isRequest ? 'لا توجد طلبات مراسلة' : 'ابدأ محادثة مع أحد أصدقائك'));
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final u = list[i];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: getUniversalImageProvider(u['avatar_url']),
                child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: const Color(0xFF31A24C), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2.5)),
                ),
              ),
            ],
          ),
          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(isRequest ? 'طلب محادثة من غير الأصدقاء' : (u['bio'] ?? 'انقر لفتح المحادثة المباشرة'), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerChatScreen(targetUser: u))),
        );
      },
    );
  }
}

class MessengerChatScreen extends StatefulWidget {
  final Map<String, dynamic> targetUser;
  const MessengerChatScreen({super.key, required this.targetUser});

  @override
  State<MessengerChatScreen> createState() => _MessengerChatScreenState();
}

class _MessengerChatScreenState extends State<MessengerChatScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _isTyping) {
        setState(() => _isTyping = hasText);
      }
    });

    _loadCachedMessages();
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _fetchMessages(silent: true));
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCachedMessages() async {
    final myId = supabase.auth.currentUser?.id;
    final otherId = widget.targetUser['id'];
    if (myId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('atheer_chat_${myId}_$otherId');
    if (cached != null && mounted) {
      setState(() => _messages = List<Map<String, dynamic>>.from(jsonDecode(cached)));
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final myId = supabase.auth.currentUser?.id;
    final otherId = widget.targetUser['id'];
    if (myId == null) return;

    try {
      final res = await supabase.from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)')
          .order('created_at', ascending: true);

      final newMsgs = List<Map<String, dynamic>>.from(res);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_chat_${myId}_$otherId', jsonEncode(newMsgs));

      if (newMsgs.length != _messages.length || !silent) {
        if (mounted) {
          setState(() => _messages = newMsgs);
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? imageBase64, String? customText}) async {
    final text = customText ?? _msgCtrl.text.trim();
    if (text.isEmpty && imageBase64 == null) return;

    final myId = supabase.auth.currentUser?.id;
    final otherId = widget.targetUser['id'];

    _msgCtrl.clear();

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': otherId,
      'content': text,
      'image_url': imageBase64 ?? '',
      'is_deleted': false,
    });

    _fetchMessages();
  }

  void _pickAndSendImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 35, maxWidth: 650);
    if (f != null) {
      final bytes = await File(f.path).readAsBytes();
      final b64 = base64Encode(bytes);
      _sendMessage(imageBase64: b64, customText: '📷 صورة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookUserProfileScreen(userId: widget.targetUser['id'], initialProfile: widget.targetUser))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundImage: getUniversalImageProvider(widget.targetUser['avatar_url']),
                child: (widget.targetUser['avatar_url'] == null || widget.targetUser['avatar_url'] == '') ? Text(getFirstChar(widget.targetUser['name'])) : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.targetUser['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const Text('نشط الآن 🟢', style: TextStyle(fontSize: 10, color: Color(0xFF31A24C))),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m['sender_id'] == myId;
                final bool isDeleted = m['is_deleted'] == true;
                final hasImage = (m['image_url'] ?? '').isNotEmpty && !isDeleted;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: getUniversalImageProvider(widget.targetUser['avatar_url']),
                          child: (widget.targetUser['avatar_url'] == null || widget.targetUser['avatar_url'] == '') ? Text(getFirstChar(widget.targetUser['name']), style: const TextStyle(fontSize: 10)) : null,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDeleted
                                ? Colors.grey.withOpacity(0.2)
                                : (isMe ? FBColors.primaryBlue : (isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB))),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: Radius.circular(isMe ? 18 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (hasImage)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: renderUniversalImage(m['image_url'], height: 180, width: double.infinity, borderRadius: BorderRadius.circular(12)),
                                ),
                              if ((m['content'] ?? '').isNotEmpty)
                                Text(
                                  m['content'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF050505)),
                                    fontSize: 14.5,
                                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                  ),
                                ),
                              const SizedBox(height: 3),
                              Text(
                                formatArabicTime(m['created_at']),
                                style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFCED0D4), width: 0.5)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: FBColors.primaryBlue, size: 24),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? FBColors.darkInput : FBColors.lightInput,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_isTyping)
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: FBColors.primaryBlue, size: 26),
                      onPressed: () => _sendMessage(),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.thumb_up_alt_rounded, color: FBColors.primaryBlue, size: 26),
                      onPressed: () => _sendMessage(customText: '👍'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 6. الصفحة الشخصية الكاملة المطابقة لفيسبوك (لأي مستخدم أو للمستخدم الحالي)
// =========================================================================
class FacebookUserProfileScreen extends StatefulWidget {
  final String userId;
  final String? fallbackName;
  final String? fallbackAvatar;
  final Map<String, dynamic>? initialProfile;

  const FacebookUserProfileScreen({
    super.key,
    required this.userId,
    this.fallbackName,
    this.fallbackAvatar,
    this.initialProfile,
  });

  @override
  State<FacebookUserProfileScreen> createState() => _FacebookUserProfileScreenState();
}

class _FacebookUserProfileScreenState extends State<FacebookUserProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _userPosts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _loading = false;
    }
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final p = await supabase.from('profiles').select().eq('id', widget.userId).maybeSingle();
      final postsRes = await supabase.from('posts').select().eq('user_id', widget.userId).order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          if (p != null) _profile = p;
          _userPosts = List<Map<String, dynamic>>.from(postsRes);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMyProfile = (myId != null && myId == widget.userId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = _profile?['name'] ?? widget.fallbackName ?? 'مستخدم أثير';
    final bio = _profile?['bio'] ?? '';
    final avatar = _profile?['avatar_url'] ?? widget.fallbackAvatar ?? '';
    final isFounder = _profile?['is_founder'] == true;
    final location = _profile?['location'] ?? '';
    final work = _profile?['work'] ?? '';
    final edu = _profile?['education'] ?? '';
    final birth = _profile?['birth_date'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.settings, color: FBColors.primaryBlue),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => FacebookSettingsHub(currentProfile: _profile ?? {})));
                _loadUserProfile();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : ListView(
              children: [
                // غلاف فيسبوك العريض + الصورة الشخصية المتداخلة
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -45,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: FBColors.primaryBlue,
                          backgroundImage: getUniversalImageProvider(avatar),
                          child: (avatar.isEmpty) ? Text(getFirstChar(name), style: const TextStyle(fontSize: 42, color: Colors.white)) : null,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 52),

                // الاسم والشارة والنبذة
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      if (isFounder) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: FBColors.primaryBlue, size: 22),
                      ],
                    ],
                  ),
                ),
                if (bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(bio, textAlign: TextAlign.center, style: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 13.5)),
                  ),

                const SizedBox(height: 12),

                // أزرار فيسبوك التفاعلية
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (isMyProfile) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text('إضافة إلى القصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: isDark ? FBColors.darkInput : FBColors.lightInput, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black, size: 18),
                            label: Text('تعديل الملف', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => FullEditProfileScreen(currentProfile: _profile ?? {})));
                              _loadUserProfile();
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
                            label: const Text('إضافة صديق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              supabase.from('friendships').insert({'sender_id': myId, 'receiver_id': widget.userId, 'status': 'pending'});
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الصداقة!')));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: isDark ? FBColors.darkInput : FBColors.lightInput, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            icon: const Icon(Icons.chat_bubble, color: FBColors.primaryBlue, size: 18),
                            label: Text('مراسلة', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MessengerChatScreen(targetUser: _profile ?? {'id': widget.userId, 'name': name, 'avatar_url': avatar})));
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // قسم تفاصيل الحساب (About details)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('التفاصيل 📌', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (work.isNotEmpty) _fbDetailItem(Icons.work, 'يعمل لدى: $work'),
                      if (edu.isNotEmpty) _fbDetailItem(Icons.school, 'درس في: $edu'),
                      if (location.isNotEmpty) _fbDetailItem(Icons.home, 'يقيم في: $location'),
                      if (birth.isNotEmpty) _fbDetailItem(Icons.cake, 'تاريخ الميلاد: $birth'),
                    ],
                  ),
                ),

                const Divider(),

                // عنوان المنشورات
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('منشورات $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),

                if (_userPosts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('لا توجد منشورات لهذا المستخدم بعد.')),
                  )
                else
                  ..._userPosts.map((post) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 18, backgroundImage: getUniversalImageProvider(avatar)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(formatArabicTime(post['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if ((post['text'] ?? '').isNotEmpty) Text(post['text']),
                          if ((post['image_url'] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: renderUniversalImage(post['image_url'], height: 200, width: double.infinity, borderRadius: BorderRadius.circular(10)),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Widget _fbDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: FBColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ==========================================
// 7. شاشة الملف الشخصي الحالية
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id ?? '';
    return FacebookUserProfileScreen(userId: myId);
  }
}

// ==========================================
// 8. مركز الإعدادات بنمط فيسبوك
// ==========================================
class FacebookSettingsHub extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const FacebookSettingsHub({super.key, required this.currentProfile});

  @override
  State<FacebookSettingsHub> createState() => _FacebookSettingsHubState();
}

class _FacebookSettingsHubState extends State<FacebookSettingsHub> {
  bool _notifComments = true;
  bool _notifMessages = true;
  bool _notifFriends = true;
  String _defaultAudience = 'عام 🌐';
  String _messagingPrivacy = 'الجميع';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifComments = prefs.getBool('notif_comments') ?? true;
      _notifMessages = prefs.getBool('notif_messages') ?? true;
      _notifFriends = prefs.getBool('notif_friends') ?? true;
      _defaultAudience = prefs.getString('default_audience') ?? 'عام 🌐';
      _messagingPrivacy = prefs.getString('messaging_privacy') ?? 'الجميع';
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _showChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة السر 🔐'),
        content: TextField(
          controller: newPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة السر الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
            onPressed: () async {
              final newPass = newPassCtrl.text.trim();
              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب أن تكون كلمة المرور 6 أحرف على الأقل')));
                return;
              }
              try {
                await supabase.auth.updateUser(UserAttributes(password: newPass));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب نهائياً ⚠️', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت متأكد من رغبتك في حذف حسابك من فضاء أثير؟ هذا الإجراء سيحذف كافة بياناتك نهائياً!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final uid = supabase.auth.currentUser?.id;
              if (uid != null) {
                await supabase.from('profiles').delete().eq('id', uid);
                await supabase.auth.signOut();
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات والخصوصية ⚙️')),
      body: ListView(
        children: [
          _buildHeader('مركز الحسابات والمعلومات الشخصية'),
          ListTile(
            leading: const CircleAvatar(backgroundColor: FBColors.primaryBlue, child: Icon(Icons.person, color: Colors.white)),
            title: const Text('المعلومات الشخصية وتعديل الملف', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تعديل الاسم، الصورة، الدولة، المدينة، تاريخ الميلاد، العمل'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FullEditProfileScreen(currentProfile: widget.currentProfile)),
              );
            },
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.security, color: Colors.white)),
            title: const Text('كلمة السر والأمان', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('تحديث كلمة المرور لحسابك'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),

          const Divider(),

          _buildHeader('التفضيلات والمظهر'),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.amber : FBColors.primaryBlue),
            title: const Text('الوضع المظلم (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isDark ? 'مفعّل حالياً' : 'معطّل حالياً'),
            value: isDarkModeNotifier.value,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              isDarkModeNotifier.value = val;
              await prefs.setBool('atheer_theme_dark', val);
              setState(() {});
            },
          ),

          const Divider(),

          _buildHeader('الجمهور والخصوصية'),
          ListTile(
            leading: const Icon(Icons.public, color: FBColors.primaryBlue),
            title: const Text('الجمهور الافتراضي للمنشورات', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الحالي: $_defaultAudience'),
            trailing: DropdownButton<String>(
              value: _defaultAudience,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'عام 🌐', child: Text('عام 🌐')),
                DropdownMenuItem(value: 'الأصدقاء 👥', child: Text('الأصدقاء 👥')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _defaultAudience = v);
                  _savePref('default_audience', v);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mark_chat_read, color: FBColors.primaryBlue),
            title: const Text('من يمكنه إرسال طلبات مراسلة لك؟', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('الحالي: $_messagingPrivacy'),
            trailing: DropdownButton<String>(
              value: _messagingPrivacy,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'الجميع', child: Text('الجميع')),
                DropdownMenuItem(value: 'الأصدقاء فقط', child: Text('الأصدقاء فقط')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _messagingPrivacy = v);
                  _savePref('messaging_privacy', v);
                }
              },
            ),
          ),

          const Divider(),

          _buildHeader('إعدادات الإشعارات والتنبيهات'),
          SwitchListTile(
            secondary: const Icon(Icons.comment, color: FBColors.primaryBlue),
            title: const Text('إشعارات التعليقات والتفاعلات'),
            value: _notifComments,
            onChanged: (val) {
              setState(() => _notifComments = val);
              _savePref('notif_comments', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat, color: FBColors.primaryBlue),
            title: const Text('إشعارات الرسائل الفورية'),
            value: _notifMessages,
            onChanged: (val) {
              setState(() => _notifMessages = val);
              _savePref('notif_messages', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.person_add, color: FBColors.primaryBlue),
            title: const Text('إشعارات طلبات الصداقة'),
            value: _notifFriends,
            onChanged: (val) {
              setState(() => _notifFriends = val);
              _savePref('notif_friends', val);
            },
          ),

          const Divider(),

          _buildHeader('ملكية الحساب وإدارته'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            subtitle: const Text('حذف الحساب والبيانات نهائياً من السيرفر'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
            onTap: _confirmDeleteAccount,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(color: FBColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// =========================================================================
// 9. شاشة تعديل الملف مع التحديث الشامل في كل الجداول والكاش
// =========================================================================
class FullEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  const FullEditProfileScreen({super.key, required this.currentProfile});

  @override
  State<FullEditProfileScreen> createState() => _FullEditProfileScreenState();
}

class _FullEditProfileScreenState extends State<FullEditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _workCtrl;
  late TextEditingController _eduCtrl;
  String _country = 'فلسطين';
  String _city = 'خان يونس';
  String _birthDate = '';
  String? _newAvatarBase64;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentProfile['name'] ?? '');
    _bioCtrl = TextEditingController(text: widget.currentProfile['bio'] ?? '');
    _workCtrl = TextEditingController(text: widget.currentProfile['work'] ?? '');
    _eduCtrl = TextEditingController(text: widget.currentProfile['education'] ?? '');
    _country = widget.currentProfile['country'] ?? 'فلسطين';
    _city = widget.currentProfile['city'] ?? 'خان يونس';
    _birthDate = widget.currentProfile['birth_date'] ?? '';
    _newAvatarBase64 = widget.currentProfile['avatar_url'];
  }

  Future<void> _pickNewAvatar() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 35, maxWidth: 450);
    if (f != null) {
      final bytes = await File(f.path).readAsBytes();
      setState(() => _newAvatarBase64 = base64Encode(bytes));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  // حفظ وتحديث الصورة والبيانات في جدول الحساب وجدول المنشورات والكاش معاً!
  Future<void> _saveProfileSettings() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _saving = true);
    final updatedData = {
      'id': uid,
      'name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'work': _workCtrl.text.trim(),
      'education': _eduCtrl.text.trim(),
      'country': _country,
      'city': _city,
      'location': '$_country، $_city',
      'birth_date': _birthDate,
      'avatar_url': _newAvatarBase64 ?? '',
    };

    try {
      // 1. تحديث البروفايل
      await supabase.from('profiles').upsert(updatedData);

      // 2. تحديث صورة واسم الكاتب في المنشورات السابقة حتى تظهر للجميع
      await supabase.from('posts').update({
        'author_name': _nameCtrl.text.trim(),
        'author_avatar': _newAvatarBase64 ?? '',
      }).eq('user_id', uid);

      // 3. تحديث الكاش المحلي ليعمل التطبيق بها حتى بدون إنترنت
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_cached_profile', jsonEncode(updatedData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ صورتك وتحديث بياناتك في كامل السيرفر بنجاح! 🎉')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCities = locationsData[_country] ?? ['المركز الرئيسي'];
    final safeCity = currentCities.contains(_city) ? _city : currentCities.first;

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickNewAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: FBColors.primaryBlue,
                    backgroundImage: getUniversalImageProvider(_newAvatarBase64),
                    child: (_newAvatarBase64 == null || _newAvatarBase64!.isEmpty) ? Text(getFirstChar(_nameCtrl.text), style: const TextStyle(fontSize: 42, color: Colors.white)) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('انقر لتغيير صورتك الشخصية', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 24),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الكامل المعروض', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: 'النبذة التعريفية (Bio)', prefixIcon: Icon(Icons.info_outline))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: locationsData.containsKey(_country) ? _country : 'فلسطين',
                    decoration: const InputDecoration(labelText: 'الدولة العربية', prefixIcon: Icon(Icons.flag)),
                    items: locationsData.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _country = val;
                          _city = locationsData[val]!.first;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: safeCity,
                    decoration: const InputDecoration(labelText: 'المدينة', prefixIcon: Icon(Icons.location_city)),
                    items: currentCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _city = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'تاريخ الميلاد', prefixIcon: Icon(Icons.cake)),
                child: Text(_birthDate.isEmpty ? 'اختر تاريخ الميلاد' : _birthDate),
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _workCtrl, decoration: const InputDecoration(labelText: 'العمل والمهنة', prefixIcon: Icon(Icons.work))),
            const SizedBox(height: 12),
            TextField(controller: _eduCtrl, decoration: const InputDecoration(labelText: 'التعليم والدراسة', prefixIcon: Icon(Icons.school))),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: _saving ? null : _saveProfileSettings,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ وتحديث في السيرفر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
