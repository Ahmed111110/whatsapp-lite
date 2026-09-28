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
    if (diff.inSeconds < 60) return 'منذ لحظات';
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
            scaffoldBackgroundColor: const Color(0xFFF0F2F5),
            primaryColor: const Color(0xFF0084FF),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Color(0xFF050505)),
              titleTextStyle: TextStyle(color: Color(0xFF050505), fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF18191A),
            primaryColor: const Color(0xFF0084FF),
            cardColor: const Color(0xFF242526),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF242526),
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
// 1. شاشة تسجيل الدخول وإنشاء الحساب
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
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 500);
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
          colorScheme: const ColorScheme.dark(primary: Color(0xFF0084FF), onPrimary: Colors.white, surface: Color(0xFF242526)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة البريد وكلمة المرور')));
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
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFFA826C6)]),
                ),
                child: const Icon(Icons.bubble_chart_rounded, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('أَثِـيـر', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              const Text('فضاء التواصل السحابي المضيء', style: TextStyle(color: Color(0xFF0084FF), fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF242526),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: const Color(0xFF3A3B3C),
                          backgroundImage: getUniversalImageProvider(_avatarBase64),
                          child: _avatarBase64 == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.camera_alt, color: Color(0xFF0084FF), size: 24), Text('صورتك', style: TextStyle(fontSize: 10, color: Colors.white70))],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecor('الاسم الكامل المعروض', Icons.person_outline),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: locationsData.containsKey(_selectedCountry) ? _selectedCountry : 'فلسطين',
                              dropdownColor: const Color(0xFF242526),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDecor('الدولة', Icons.flag_outlined),
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
                              decoration: _inputDecor('المدينة', Icons.location_city_outlined),
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
                          decoration: BoxDecoration(color: const Color(0xFF3A3B3C), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: Color(0xFF0084FF), size: 20),
                              const SizedBox(width: 10),
                              Text(_selectedBirthDate.isEmpty ? 'تاريخ الميلاد (اختر من الروزنامة)' : _selectedBirthDate, style: TextStyle(color: _selectedBirthDate.isEmpty ? Colors.white38 : Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _workCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor('العمل والمهنة', Icons.work_outline)),
                      const SizedBox(height: 10),
                      TextField(controller: _eduCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor('التعليم والدراسة', Icons.school_outlined)),
                      const SizedBox(height: 10),
                    ],
                    TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: _inputDecor('البريد الإلكتروني', Icons.email_outlined)),
                    const SizedBox(height: 10),
                    TextField(controller: _passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _inputDecor('كلمة المرور', Icons.lock_outline)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
                child: Text(_isLogin ? 'ليس لديك حساب؟ أنشئ حسابك الآن' : 'لديك حساب بالفعل؟ سجّل دخولك', style: const TextStyle(color: Color(0xFF0084FF), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF3A3B3C),
      prefixIcon: Icon(icon, color: const Color(0xFF0084FF), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}

// ==========================================
// 2. الهيكل الرئيسي
// ==========================================
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
          color: isDark ? const Color(0xFF242526) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0084FF),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'المجتمع'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'الدردشات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. خلاصة المنشورات مع تصحيح الصلاحيات 100%
// ==========================================
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
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    if (user != null) {
      final p = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (p != null) _myProfile = p;
    }
    final postsRes = await supabase.from('posts').select().order('created_at', ascending: false);
    final storiesRes = await supabase.from('stories').select().order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(postsRes);
        _stories = List<Map<String, dynamic>>.from(storiesRes);
        _loading = false;
      });
    }
  }

  void _addStory() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 800);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('نشر قصة في أثير 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (b64 != null) renderUniversalImage(b64, height: 130, borderRadius: BorderRadius.circular(12)),
            const SizedBox(height: 10),
            TextField(controller: textCtrl, decoration: const InputDecoration(hintText: 'اكتب عبارة تظهر مع القصة...')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF)),
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
            child: const Text('نشر القصة', style: TextStyle(color: Colors.white)),
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

  Future<void> _handleReaction(Map<String, dynamic> post, String reactionType) async {
    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    } else {
      reactions = {'like': 0, 'love': 0, 'scare': 0, 'angry': 0};
    }

    reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
    final int totalLikes = (post['likes_count'] ?? 0) + 1;

    await supabase.from('posts').update({
      'likes_count': totalLikes,
      'reactions': reactions,
    }).eq('id', post['id']);

    _loadAll();
  }

  Widget _buildReactionsSummary(Map<String, dynamic> post) {
    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    }

    final List<String> activeIcons = [];
    if ((reactions['like'] ?? 0) > 0) activeIcons.add('👍');
    if ((reactions['love'] ?? 0) > 0) activeIcons.add('❤️');
    if ((reactions['scare'] ?? 0) > 0) activeIcons.add('😨');
    if ((reactions['angry'] ?? 0) > 0) activeIcons.add('😡');

    if (activeIcons.isEmpty && (post['likes_count'] ?? 0) > 0) {
      activeIcons.add('👍');
    }

    final int totalCount = post['likes_count'] ?? 0;

    return Row(
      children: [
        if (activeIcons.isNotEmpty) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: activeIcons.map((e) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(e, style: const TextStyle(fontSize: 14)),
            )).toList(),
          ),
          const SizedBox(width: 6),
        ] else ...[
          const Icon(Icons.thumb_up_rounded, size: 15, color: Color(0xFF0084FF)),
          const SizedBox(width: 4),
        ],
        Text('$totalCount تفاعل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                leading: const Icon(Icons.edit, color: Color(0xFF0084FF)),
                title: const Text('تعديل المنشور', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تعديل نص المنشور وتحديثه في السيرفر'),
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
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF)),
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
                title: Text(post['visibility'] == 'friends' ? 'تغيير العرض إلى: عام 🌐' : 'تغيير العرض إلى: للأصدقاء فقط 👥', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('التحكم في من يمكنه مشاهدة منشورك'),
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
                subtitle: const Text('إزالة المنشور بالكامل من منصة أثير'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('posts').delete().eq('id', post['id']);
                  _loadAll();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف منشورك بنجاح')));
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF0084FF)),
                title: Text(_savedPostIds.contains(post['id'].toString()) ? 'إلغاء حفظ المنشور' : 'حفظ المنشور في المحفوظات 📌', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إضافة هذا المنشور لقائمتك للرجوع إليه لاحقاً'),
                onTap: () {
                  Navigator.pop(ctx);
                  final pid = post['id'].toString();
                  setState(() {
                    if (_savedPostIds.contains(pid)) {
                      _savedPostIds.remove(pid);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إزالة المنشور من المحفوظات')));
                    } else {
                      _savedPostIds.add(pid);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المنشور في محفوظاتك بنجاح! 📌')));
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Colors.amber),
                title: const Text('إخفاء المنشور 👁️', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إخفاء هذا المنشور من صفحتك الرئيسية'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _hiddenPostIds.add(post['id'].toString());
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إخفاء هذا المنشور من خامتك')));
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
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: const Text('الإبلاغ عن المنشور', style: TextStyle(color: Colors.redAccent)),
                subtitle: const Text('إبلاغ الإدارة عن منشور غير لائق'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام البلاغ وسيتم مراجعته، شكراً لمساعدتنا!')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('أَثِـيـر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : const Color(0xFF0084FF)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final next = !isDarkModeNotifier.value;
              isDarkModeNotifier.value = next;
              await prefs.setBool('atheer_theme_dark', next);
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  Container(
                    height: 104,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _addStory,
                          child: Column(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0084FF), width: 2)),
                                child: const Icon(Icons.add, color: Color(0xFF0084FF), size: 30),
                              ),
                              const SizedBox(height: 4),
                              const Text('قصتك +', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ..._stories.map((st) => GestureDetector(
                              onTap: () => _viewStory(st),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: [Color(0xFF0084FF), Color(0xFFA826C6)]),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundImage: getUniversalImageProvider(st['avatar_url']),
                                        child: (st['avatar_url'] == null || st['avatar_url'] == '') ? Text(getFirstChar(st['author_name'])) : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(st['author_name'] ?? '', style: const TextStyle(fontSize: 10), maxLines: 1),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url']),
                          child: (_myProfile?['avatar_url'] == null || _myProfile?['avatar_url'] == '') ? Text(getFirstChar(_myProfile?['name'])) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showCreatePostModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB), borderRadius: BorderRadius.circular(25)),
                              child: Text('بِمَ تفكّر يا ${_myProfile?['name'] ?? 'أنس'}؟ شارك العالم...', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...visiblePosts.map((post) {
                    final bool isFounder = post['is_founder'] == true;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: getUniversalImageProvider(post['author_avatar']),
                              child: (post['author_avatar'] == null || post['author_avatar'] == '') ? Text(getFirstChar(post['author_name'])) : null,
                            ),
                            title: Row(
                              children: [
                                Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                if (isFounder) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('المؤسس ⚡', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text('${formatArabicTime(post['created_at'])} • ${post['visibility'] == 'friends' ? 'للأصدقاء فقط 👥' : 'عام 🌐'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            trailing: IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _showPostMenu(post)),
                          ),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4))),
                          renderUniversalImage(post['image_url'], height: 240, width: double.infinity),
                          const Divider(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onLongPress: () => _showReactionsOverlay(post),
                                  onTap: () => _handleReaction(post, 'like'),
                                  child: _buildReactionsSummary(post),
                                ),
                                InkWell(
                                  onTap: () => _openComments(post['id']),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.comment_rounded, size: 16, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text('تعليق', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر تطبيق أثير 🌌'));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور لمشاركته!')));
                                  },
                                  child: Row(
                                    children: const [
                                      Icon(Icons.share_rounded, size: 16, color: Colors.grey),
                                      SizedBox(width: 6),
                                      Text('مشاركة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setM) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_myProfile?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  DropdownButton<String>(
                    value: vis,
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('عام 🌐')),
                      DropdownMenuItem(value: 'friends', child: Text('للأصدقاء 👥')),
                    ],
                    onChanged: (v) {
                      if (v != null) setM(() => vis = v);
                    },
                  ),
                ],
              ),
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب أثرك هنا...', border: InputBorder.none)),
              if (b64 != null) renderUniversalImage(b64, height: 140, borderRadius: BorderRadius.circular(12)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Color(0xFF0084FF)),
                    onPressed: () async {
                      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 800);
                      if (f != null) {
                        final bytes = await File(f.path).readAsBytes();
                        setM(() => b64 = base64Encode(bytes));
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF)),
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
                          'reactions': {'like': 0, 'love': 0, 'scare': 0, 'angry': 0},
                        });
                        Navigator.pop(ctx);
                        _loadAll();
                      }
                    },
                    child: const Text('نشر في أثير', style: TextStyle(color: Colors.white)),
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
      builder: (ctx) => StatefulBuilder(
        builder: (c, setC) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
          child: Column(
            children: [
              const Text('التعليقات 💬', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: supabase.from('comments').select().eq('post_id', postId.toString()).order('created_at', ascending: true),
                  builder: (cx, AsyncSnapshot snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data as List;
                    if (list.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد!'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (cx, i) => ListTile(
                        leading: CircleAvatar(
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
                        hintText: 'اكتب تعليقك...',
                        filled: true,
                        fillColor: const Color(0xFF3A3B3C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0084FF)),
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
// عارض الستوري السينمائي مع تفاعلات الإيموجي والرد المباشر في الشات
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال تفاعل $emoji كرسالة خاصة لصاحب القصة! 💬')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ردك كرسالة خاصة لصاحب القصة بنجاح ✉️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Dialog(
      backgroundColor: const Color(0xFF18191A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if ((story['image_url'] ?? '').isNotEmpty)
                      renderUniversalImage(story['image_url'], width: double.infinity, fit: BoxFit.contain),
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3B3C),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'إرسال رد خاص لصاحب القصة...',
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
                    icon: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0084FF)))
                        : const Icon(Icons.send_rounded, color: Color(0xFF0084FF)),
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

// ==========================================
// 4. المجتمع والأصدقاء
// ==========================================
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
          indicatorColor: const Color(0xFF0084FF),
          tabs: [
            const Tab(text: 'استكشاف'),
            Tab(text: 'الطلبات (${_friendRequests.length})'),
            const Tab(text: 'أصدقائي'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
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
                      leading: CircleAvatar(
                        backgroundImage: getUniversalImageProvider(u['avatar_url']),
                        child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'])) : null,
                      ),
                      title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${u['location'] ?? ''} • ${u['work'] ?? ''}', maxLines: 1),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isFriend ? Icons.handshake : Icons.person_add_alt_1, color: isFriend ? Colors.green : const Color(0xFF0084FF)),
                            onPressed: isFriend ? null : () => _sendFriendRequest(uid),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isF ? Colors.grey.withOpacity(0.3) : const Color(0xFF0084FF)),
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
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF)),
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
                            leading: CircleAvatar(
                              backgroundImage: getUniversalImageProvider(u['avatar_url']),
                              child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'], 'ص')) : null,
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
// 5. منظومة محادثات Messenger المتطابقة
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
    _loadUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final myId = supabase.auth.currentUser?.id;
    final res = await supabase.from('profiles').select().neq('id', myId ?? '');

    final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId ?? '').eq('status', 'accepted');
    final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId ?? '').eq('status', 'accepted');
    final s = <String>{};
    for (var f in f1) { s.add(f['receiver_id'].toString()); }
    for (var f in f2) { s.add(f['sender_id'].toString()); }

    if (mounted) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(res);
        _friendIds = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsList = _users.where((u) => _friendIds.contains(u['id'])).toList();
    final nonFriendsList = _users.where((u) => !_friendIds.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات 💬', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF0084FF),
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
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 800);
    if (f != null) {
      final bytes = await File(f.path).readAsBytes();
      final b64 = base64Encode(bytes);
      _sendMessage(imageBase64: b64, customText: '📷 صورة');
    }
  }

  void _deleteMessageCheck(Map<String, dynamic> msg) async {
    final myId = supabase.auth.currentUser?.id;
    if (msg['sender_id'] != myId) return;

    if (msg['created_at'] == null) return;
    final createdAt = DateTime.parse(msg['created_at'].toString()).toLocal();
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عذراً! لا يمكن حذف الرسالة لدى الجميع بعد مرور 5 دقائق على إرسالها.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف لدى الجميع 🚫'),
        content: const Text('هل تريد حذف هذه الرسالة من المحادثة لدى الطرفين؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await supabase.from('messages').update({'is_deleted': true, 'content': 'تم حذف هذه الرسالة 🚫', 'image_url': ''}).eq('id', msg['id']);
              Navigator.pop(ctx);
              _fetchMessages();
            },
            child: const Text('حذف الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: getUniversalImageProvider(widget.targetUser['avatar_url']),
                  child: (widget.targetUser['avatar_url'] == null || widget.targetUser['avatar_url'] == '') ? Text(getFirstChar(widget.targetUser['name'])) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: const Color(0xFF31A24C), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 2)),
                  ),
                ),
              ],
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
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Color(0xFF0084FF)), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam, color: Color(0xFF0084FF)), onPressed: () {}),
        ],
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

                return GestureDetector(
                  onLongPress: () => _deleteMessageCheck(m),
                  child: Padding(
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
                              gradient: isMe && !isDeleted
                                  ? const LinearGradient(colors: [Color(0xFF0084FF), Color(0xFFA826C6)])
                                  : null,
                              color: isDeleted
                                  ? Colors.grey.withOpacity(0.2)
                                  : (isMe ? const Color(0xFF0084FF) : (isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB))),
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
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF0084FF), size: 24),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
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
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF0084FF), size: 26),
                      onPressed: () => _sendMessage(),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF0084FF), size: 26),
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

// ==========================================
// 6. شاشة الملف الشخصي
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    if (user != null) {
      final res = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      setState(() {
        _profile = res;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0084FF))));

    final name = _profile?['name'] ?? 'مستخدم أثير';
    final bio = _profile?['bio'] ?? '';
    final isFounder = _profile?['is_founder'] == true;
    final location = _profile?['location'] ?? '';
    final work = _profile?['work'] ?? '';
    final edu = _profile?['education'] ?? '';
    final birth = _profile?['birth_date'] ?? '';
    final avatar = _profile?['avatar_url'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF0084FF), size: 26),
            tooltip: 'إعدادات الحساب مثل فيسبوك',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FacebookSettingsHub(currentProfile: _profile ?? {})),
              );
              _loadProfile();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF0084FF),
              backgroundImage: getUniversalImageProvider(avatar),
              child: (avatar.isEmpty) ? Text(getFirstChar(name), style: const TextStyle(fontSize: 42, color: Colors.white)) : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              if (isFounder) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 22),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Center(child: Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF0084FF)))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0084FF).withOpacity(0.12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF0084FF), size: 20),
            label: const Text('مركز الإعدادات والخصوصية (مثل فيسبوك)', style: TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FacebookSettingsHub(currentProfile: _profile ?? {})),
              );
              _loadProfile();
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          if (location.isNotEmpty) ListTile(leading: const Icon(Icons.location_on, color: Color(0xFF0084FF)), title: const Text('الموقع الجغرافي والسكن'), subtitle: Text(location)),
          if (work.isNotEmpty) ListTile(leading: const Icon(Icons.work, color: Color(0xFF0084FF)), title: const Text('العمل'), subtitle: Text(work)),
          if (edu.isNotEmpty) ListTile(leading: const Icon(Icons.school, color: Color(0xFF0084FF)), title: const Text('التعليم والدراسة'), subtitle: Text(edu)),
          if (birth.isNotEmpty) ListTile(leading: const Icon(Icons.cake, color: Color(0xFF0084FF)), title: const Text('تاريخ الميلاد'), subtitle: Text(birth)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.15), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12)),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async => await supabase.auth.signOut(),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 7. مركز الإعدادات والخصوصية الكامل بنمط فيسبوك
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
        title: const Text('تغيير كلمة المرور 🔐'),
        content: TextField(
          controller: newPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', hintText: 'اكتب كلمة مرور قوية'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF)),
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
        content: const Text('هل أنت متأكد تماماً من رغبتك في حذف حسابك من فضاء أثير؟ هذا الإجراء سيحذف كافة بياناتك نهائياً!'),
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
            leading: const CircleAvatar(backgroundColor: Color(0xFF0084FF), child: Icon(Icons.person, color: Colors.white)),
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
            subtitle: const Text('تحديث وتغيير كلمة المرور الخاصة بحسابك'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showChangePasswordDialog,
          ),

          const Divider(),

          _buildHeader('التفضيلات والمظهر'),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.amber : const Color(0xFF0084FF)),
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
            leading: const Icon(Icons.public, color: Color(0xFF0084FF)),
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
            leading: const Icon(Icons.mark_chat_read, color: Color(0xFF0084FF)),
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
            secondary: const Icon(Icons.comment, color: Color(0xFF0084FF)),
            title: const Text('إشعارات التعليقات والتفاعلات'),
            value: _notifComments,
            onChanged: (val) {
              setState(() => _notifComments = val);
              _savePref('notif_comments', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat, color: Color(0xFF0084FF)),
            title: const Text('إشعارات الرسائل الفورية'),
            value: _notifMessages,
            onChanged: (val) {
              setState(() => _notifMessages = val);
              _savePref('notif_messages', val);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.person_add, color: Color(0xFF0084FF)),
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
            title: const Text('حذف أو تعطيل الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            subtitle: const Text('حذف حسابك وبياناتك نهائياً من السيرفر'),
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
      child: Text(title, style: const TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// ==========================================
// 8. شاشة تعديل الملف الشخصي الشاملة
// ==========================================
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
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40, maxWidth: 500);
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

  Future<void> _saveProfileSettings() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await supabase.from('profiles').update({
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'work': _workCtrl.text.trim(),
        'education': _eduCtrl.text.trim(),
        'country': _country,
        'city': _city,
        'location': '$_country، $_city',
        'birth_date': _birthDate,
        'avatar_url': _newAvatarBase64 ?? '',
      }).eq('id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ وتحديث بياناتك وصورتك في السيرفر بنجاح! 🎉')));
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
                    backgroundColor: const Color(0xFF0084FF),
                    backgroundImage: getUniversalImageProvider(_newAvatarBase64),
                    child: (_newAvatarBase64 == null || _newAvatarBase64!.isEmpty) ? Text(getFirstChar(_nameCtrl.text), style: const TextStyle(fontSize: 42, color: Colors.white)) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(color: Color(0xFF0084FF), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('انقر لتغيير صورتك وحفظها سحابياً لكافة المستخدمين', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0084FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _saving ? null : _saveProfileSettings,
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ التعديلات في السيرفر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
