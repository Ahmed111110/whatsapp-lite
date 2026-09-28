import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);
final supabase = Supabase.instance.client;

// قاعدة بيانات المواقع الجغرافية الموحدة
const Map<String, List<String>> locationsData = {
  'فلسطين': ['غزة', 'خان يونس', 'رفح', 'القدس', 'رام الله', 'نابلس', 'الخليل', 'جنين', 'طولكرم'],
  'مصر': ['القاهرة', 'الإسكندرية', 'الجيزة', 'المنصورة', 'طنطا', 'أسوان', 'بور سعيد'],
  'الأردن': ['عمّان', 'إربد', 'الزرقاء', 'العقبة', 'السلط'],
  'تونس': ['تونس العاصمة', 'منوبة', 'صفاقس', 'سوسة', 'أريانة', 'بنزرت'],
  'السعودية': ['الرياض', 'جدة', 'مكة المكرمة', 'المدينة المنورة', 'الدمام'],
  'الجزائر': ['الجزائر العاصمة', 'وهران', 'قسنطينة', 'عنابة'],
  'المغرب': ['الرباط', 'الدار البيضاء', 'مراكش', 'طنجة', 'فاس'],
  'أخرى': ['دولة أخرى / غير محدد'],
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

String formatArabicTime(String? timestamp) {
  if (timestamp == null) return 'الآن';
  try {
    final date = DateTime.parse(timestamp).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.year}/${date.month}/${date.day}';
  } catch (_) {
    return 'مؤخراً';
  }
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
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            primaryColor: const Color(0xFF7C3AED),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Color(0xFF1E293B)),
              titleTextStyle: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF090D16),
            primaryColor: const Color(0xFF7C3AED),
            cardColor: const Color(0xFF121826),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0F1523),
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
// 1. نظام التسجيل الموسّع الموحد مع صورة البروفايل
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
  String? _avatarPath;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _avatarPath = file.path);
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF7C3AED), onPrimary: Colors.white, surface: Color(0xFF121826)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى كتابة اسمك وتحديد تاريخ ميلادك')));
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
            'avatar_url': _avatarPath ?? '',
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
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                ),
                child: const Icon(Icons.bubble_chart_rounded, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('أَثِـيـر', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              const Text('فضاء التواصل السحابي المضيء', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF1F293D),
                          backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                          child: _avatarPath == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.camera_alt, color: Color(0xFF8B5CF6), size: 24), Text('صورتك', style: TextStyle(fontSize: 10, color: Colors.white70))],
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
                              value: _selectedCountry,
                              dropdownColor: const Color(0xFF1A2338),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDecor('الدولة', Icons.flag_outlined),
                              items: locationsData.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                              value: _selectedCity,
                              dropdownColor: const Color(0xFF1A2338),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDecor('المدينة', Icons.location_city_outlined),
                              items: locationsData[_selectedCountry]!.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                          decoration: BoxDecoration(color: const Color(0xFF1A2338), borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: Color(0xFF8B5CF6), size: 20),
                              const SizedBox(width: 10),
                              Text(_selectedBirthDate.isEmpty ? 'تاريخ الميلاد (اختر من الروزنامة)' : _selectedBirthDate, style: TextStyle(color: _selectedBirthDate.isEmpty ? Colors.white38 : Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: _workCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor('العمل والمهنة (اختياري)', Icons.work_outline)),
                      const SizedBox(height: 10),
                      TextField(controller: _eduCtrl, style: const TextStyle(color: Colors.white), decoration: _inputDecor('التعليم والدراسة (اختياري)', Icons.school_outlined)),
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
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
                child: Text(_isLogin ? 'ليس لديك حساب؟ أنشئ حسابك بكامل بياناتك الآن' : 'لديك حساب بالفعل؟ سجّل دخولك', style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.bold)),
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
      fillColor: const Color(0xFF1A2338),
      prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}

// ==========================================
// 2. الهيكل الرئيسي المطور مع الدردشات
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
          color: isDark ? const Color(0xFF0F1523) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: 'المجتمع والأصدقاء'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'الدردشات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. الخلاصة + الستوري + المعاينة والتفاعلات
// ==========================================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
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

    setState(() {
      _posts = List<Map<String, dynamic>>.from(postsRes);
      _stories = List<Map<String, dynamic>>.from(storiesRes);
      _loading = false;
    });
  }

  // إضافة ستوري جديدة
  void _addStory() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    final textCtrl = TextEditingController();

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
            if (file != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(file.path), height: 130, fit: BoxFit.cover)),
            const SizedBox(height: 10),
            TextField(controller: textCtrl, decoration: const InputDecoration(hintText: 'اكتب عبارة تظهر مع القصة...')),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () async {
              final user = supabase.auth.currentUser;
              await supabase.from('stories').insert({
                'user_id': user?.id,
                'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                'avatar_url': _myProfile?['avatar_url'] ?? '',
                'image_url': file?.path ?? '',
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

  // عرض القصة بملء الشاشة
  void _viewStory(Map<String, dynamic> story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: story['avatar_url'] != '' ? FileImage(File(story['avatar_url'])) : null, child: Text((story['author_name'] ?? 'أ')[0])),
                  const SizedBox(width: 8),
                  Text(story['author_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(formatArabicTime(story['created_at']), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 14),
              if (story['image_url'] != '') ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(story['image_url']), maxHeight: 300, fit: BoxFit.cover)),
              if (story['text'] != '') Padding(padding: const EdgeInsets.only(top: 12), child: Text(story['text'], style: const TextStyle(color: Colors.white, fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة المعاينة بالضغط المطول مع نسخ وتفاصيل
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Text((post['author_name'] ?? 'م')[0])),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${formatArabicTime(post['created_at'])} • ${post['visibility'] == 'friends' ? 'للأصدقاء فقط 👥' : 'عام 🌐'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(post['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.5)),
                  if ((post['image_url'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(post['image_url']), maxHeight: 220, width: double.infinity, fit: BoxFit.cover)),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.copy_rounded, color: Color(0xFF7C3AED), size: 18),
                          label: const Text('نسخ المنشور', style: TextStyle(color: Color(0xFF7C3AED))),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: post['text'] ?? ''));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص بنجاح!')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 18),
                          label: const Text('تفاصيل النشر', style: TextStyle(color: Colors.grey)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            showDialog(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('تفاصيل المنشور'),
                                content: Text('تاريخ النشر: ${post['created_at']}\nالكاتب: ${post['author_name']}\nالرؤية: ${post['visibility']}'),
                              ),
                            );
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

  // التفاعلات العائمة بالضغط المطول على الإعجاب
  void _showReactionsOverlay(BuildContext targetContext, Map<String, dynamic> post) {
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
                decoration: BoxDecoration(color: const Color(0xFF1F293D), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
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

  Widget _reactionItem(String emoji, String key, Map<String, dynamic> post, BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(ctx);
        final int current = post['likes_count'] ?? 0;
        await supabase.from('posts').update({'likes_count': current + 1}).eq('id', post['id']);
        _loadAll();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  // قائمة خيارات المنشور (حذف / تعديل / خصوصية)
  void _showPostMenu(Map<String, dynamic> post) {
    final myId = supabase.auth.currentUser?.id;
    final bool isOwner = post['user_id'] == myId;
    final bool isFounder = _myProfile?['is_founder'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwner)
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF7C3AED)),
              title: const Text('تعديل المنشور'),
              onTap: () {
                Navigator.pop(ctx);
                final editCtrl = TextEditingController(text: post['text']);
                showDialog(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('تعديل المنشور'),
                    content: TextField(controller: editCtrl),
                    actions: [
                      ElevatedButton(
                        onPressed: () async {
                          await supabase.from('posts').update({'text': editCtrl.text.trim()}).eq('id', post['id']);
                          Navigator.pop(d);
                          _loadAll();
                        },
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (isOwner)
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('تغيير الجمهور (عام 🌐 / للأصدقاء فقط 👥)'),
              onTap: () async {
                Navigator.pop(ctx);
                final nextVis = post['visibility'] == 'friends' ? 'public' : 'friends';
                await supabase.from('posts').update({'visibility': nextVis}).eq('id', post['id']);
                _loadAll();
              },
            ),
          if (isOwner || isFounder)
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('حذف المنشور نهائياً', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(ctx);
                await supabase.from('posts').delete().eq('id', post['id']);
                _loadAll();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أَثِـيـر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : const Color(0xFF7C3AED)),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  // 1. شريط الحالات / القصص
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
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7C3AED), width: 2)),
                                child: const Icon(Icons.add, color: Color(0xFF7C3AED), size: 30),
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
                                        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundImage: (st['avatar_url'] ?? '').isNotEmpty ? FileImage(File(st['avatar_url'])) : null,
                                        child: (st['avatar_url'] ?? '').isEmpty ? Text((st['author_name'] ?? 'أ')[0]) : null,
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

                  // 2. شريط النشر
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: (_myProfile?['avatar_url'] ?? '').isNotEmpty ? FileImage(File(_myProfile!['avatar_url'])) : null,
                          child: (_myProfile?['avatar_url'] ?? '').isEmpty ? Text((_myProfile?['name'] ?? 'أ')[0]) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showCreatePostModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(25)),
                              child: Text('بِمَ تفكّر يا ${_myProfile?['name'] ?? 'أنس'}؟ شارك العالم...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. المنشورات
                  ..._posts.map((post) {
                    final bool isFounder = post['is_founder'] == true;
                    return GestureDetector(
                      onLongPress: () => _showPostPreviewModal(post),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(child: Text((post['author_name'] ?? 'م')[0])),
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
                            if ((post['image_url'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Image.file(File(post['image_url']), maxHeight: 240, width: double.infinity, fit: BoxFit.cover),
                              ),
                            const Divider(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onLongPress: () => _showReactionsOverlay(context, post),
                                    onTap: () async {
                                      final c = post['likes_count'] ?? 0;
                                      await supabase.from('posts').update({'likes_count': c + 1}).eq('id', post['id']);
                                      _loadAll();
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.thumb_up_rounded, size: 16, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 6),
                                        Text('${post['likes_count'] ?? 0} تفاعل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _openComments(post['id']),
                                    child: const Row(children: [Icon(Icons.comment_rounded, size: 16, color: Colors.grey), SizedBox(width: 6), Text('تعليق', style: TextStyle(fontSize: 12, color: Colors.grey))]),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر تطبيق أثير 🌌'));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور لمشاركته!')));
                                    },
                                    child: const Row(children: [Icon(Icons.share_rounded, size: 16, color: Colors.grey), SizedBox(width: 6), Text('مشاركة', style: TextStyle(fontSize: 12, color: Colors.grey))]),
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

  void _showCreatePostModal() {
    final textCtrl = TextEditingController();
    String? img;
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
                    onChanged: (v) => setM(() => vis = v!),
                  ),
                ],
              ),
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب أثرك هنا...', border: InputBorder.none)),
              if (img != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(img!), height: 140, fit: BoxFit.cover)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Color(0xFF7C3AED)),
                    onPressed: () async {
                      final f = await _picker.pickImage(source: ImageSource.gallery);
                      if (f != null) setM(() => img = f.path);
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                    onPressed: () async {
                      if (textCtrl.text.trim().isNotEmpty) {
                        final user = supabase.auth.currentUser;
                        await supabase.from('posts').insert({
                          'user_id': user?.id,
                          'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                          'is_founder': _myProfile?['is_founder'] ?? false,
                          'text': textCtrl.text.trim(),
                          'image_url': img ?? '',
                          'visibility': vis,
                          'likes_count': 0,
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

  void _openComments(String postId) {
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
                  future: supabase.from('comments').select().eq('post_id', postId).order('created_at', ascending: true),
                  builder: (cx, AsyncSnapshot snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data as List;
                    if (list.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد!'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (cx, i) => ListTile(
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
                        fillColor: const Color(0xFF1A2338),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF7C3AED)),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isNotEmpty) {
                        final u = supabase.auth.currentUser;
                        await supabase.from('comments').insert({
                          'post_id': postId,
                          'user_id': u?.id,
                          'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
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

// ==========================================
// 4. مركز العلاقات (المتابعة vs الأصدقاء والطلبات)
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

  Future<void> _loadSocial() async {
    setState(() => _loading = true);
    final myId = supabase.auth.currentUser?.id;

    final users = await supabase.from('profiles').select().neq('id', myId ?? '');
    final follows = await supabase.from('follows').select('following_id').eq('follower_id', myId ?? '');

    // جلب الصداقات والطلبات
    final reqs = await supabase.from('friendships').select().eq('receiver_id', myId ?? '').eq('status', 'pending');
    final friends1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId ?? '').eq('status', 'accepted');
    final friends2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId ?? '').eq('status', 'accepted');

    final friendSet = <String>{};
    for (var f in friends1) { friendSet.add(f['receiver_id'].toString()); }
    for (var f in friends2) { friendSet.add(f['sender_id'].toString()); }

    setState(() {
      _allUsers = List<Map<String, dynamic>>.from(users);
      _friendRequests = List<Map<String, dynamic>>.from(reqs);
      _myFollowingIds = (follows as List).map((e) => e['following_id'].toString()).toSet();
      _myFriendIds = friendSet;
      _loading = false;
    });
  }

  Future<void> _toggleFollow(String id) async {
    final myId = supabase.auth.currentUser?.id;
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
          indicatorColor: const Color(0xFF7C3AED),
          tabs: [
            const Tab(text: 'استكشاف ومتابعة'),
            Tab(text: 'طلبات الصداقة (${_friendRequests.length})'),
            const Tab(text: 'أصدقائي'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                // 1. استكشاف الجميع والمتابعة
                ListView.builder(
                  itemCount: _allUsers.length,
                  itemBuilder: (ctx, i) {
                    final u = _allUsers[i];
                    final String uid = u['id'];
                    final bool isF = _myFollowingIds.contains(uid);
                    final bool isFriend = _myFriendIds.contains(uid);

                    return ListTile(
                      leading: CircleAvatar(child: Text((u['name'] ?? 'م')[0])),
                      title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${u['location'] ?? ''} • ${u['work'] ?? ''}', maxLines: 1),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(isFriend ? Icons.handshake : Icons.person_add_alt_1, color: isFriend ? Colors.green : const Color(0xFF7C3AED)),
                            onPressed: isFriend ? null : () => _sendFriendRequest(uid),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isF ? Colors.grey.withOpacity(0.3) : const Color(0xFF7C3AED)),
                            onPressed: () => _toggleFollow(uid),
                            child: Text(isF ? 'تتابعه' : 'متابعة', style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // 2. طلبات الصداقة الواردة
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
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
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

                // 3. قائمة الأصدقاء الحقيقيين
                _myFriendIds.isEmpty
                    ? const Center(child: Text('لم تقم بإضافة أصدقاء بعد'))
                    : ListView(
                        children: _allUsers.where((u) => _myFriendIds.contains(u['id'])).map((u) {
                          return ListTile(
                            leading: CircleAvatar(child: Text((u['name'] ?? 'ص')[0])),
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

// ==========================================
// 5. منظومة المحادثات وإرسال الصور وحذف الـ 5 دقائق
// ==========================================
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

  Future<void> _loadUsers() async {
    final myId = supabase.auth.currentUser?.id;
    final res = await supabase.from('profiles').select().neq('id', myId ?? '');

    // تمييز الأصدقاء عن غير الأصدقاء لصندوق طلبات المراسلة
    final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId ?? '').eq('status', 'accepted');
    final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId ?? '').eq('status', 'accepted');
    final s = <String>{};
    for (var f in f1) { s.add(f['receiver_id'].toString()); }
    for (var f in f2) { s.add(f['sender_id'].toString()); }

    setState(() {
      _users = List<Map<String, dynamic>>.from(res);
      _friendIds = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsList = _users.where((u) => _friendIds.contains(u['id'])).toList();
    final nonFriendsList = _users.where((u) => !_friendIds.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('رسائل أثير 💬'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF7C3AED),
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
          leading: CircleAvatar(child: Text((u['name'] ?? 'م')[0])),
          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isRequest ? 'طلب محادثة من غير الأصدقاء' : (u['bio'] ?? '')),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SingleChatScreen(targetUser: u))),
        );
      },
    );
  }
}

// شاشة المحادثة الفردية الحقيقية مع حذف الـ 5 دقائق
class SingleChatScreen extends StatefulWidget {
  final Map<String, dynamic> targetUser;
  const SingleChatScreen({super.key, required this.targetUser});

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final _msgCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    final myId = supabase.auth.currentUser?.id;
    final otherId = widget.targetUser['id'];

    final res = await supabase.from('messages')
        .select()
        .or('and(sender_id.eq.$myId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$myId)')
        .order('created_at', ascending: true);

    setState(() => _messages = List<Map<String, dynamic>>.from(res));
  }

  Future<void> _sendMessage({String? imagePath}) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && imagePath == null) return;

    final myId = supabase.auth.currentUser?.id;
    final otherId = widget.targetUser['id'];

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': otherId,
      'content': text.isNotEmpty ? text : '📷 صورة',
      'image_url': imagePath ?? '',
      'is_deleted': false,
    });

    _msgCtrl.clear();
    _fetchMessages();
  }

  // حذف الرسالة المقيد بشرط الـ 5 دقائق
  void _deleteMessageCheck(Map<String, dynamic> msg) async {
    final myId = supabase.auth.currentUser?.id;
    if (msg['sender_id'] != myId) return;

    final createdAt = DateTime.parse(msg['created_at']).toLocal();
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
        title: const Text('حذف لدى الجميع'),
        content: const Text('هل تريد حذف هذه الرسالة من الطرفين؟'),
        actions: [
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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 18, child: Text((widget.targetUser['name'] ?? 'م')[0])),
            const SizedBox(width: 10),
            Text(widget.targetUser['name'] ?? '', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m['sender_id'] == myId;
                final bool isDeleted = m['is_deleted'] == true;

                return GestureDetector(
                  onLongPress: () => _deleteMessageCheck(m),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDeleted ? Colors.grey.withOpacity(0.2) : (isMe ? const Color(0xFF7C3AED) : const Color(0xFF1E283F)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((m['image_url'] ?? '').isNotEmpty && !isDeleted)
                            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(m['image_url']), height: 150, fit: BoxFit.cover)),
                          Text(m['content'] ?? '', style: TextStyle(color: Colors.white, fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal)),
                          const SizedBox(height: 2),
                          Text(formatArabicTime(m['created_at']), style: const TextStyle(fontSize: 9, color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFF7C3AED)),
                  onPressed: () async {
                    final f = await _picker.pickImage(source: ImageSource.gallery);
                    if (f != null) _sendMessage(imagePath: f.path);
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'اكتب رسالتك...', border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF7C3AED)), onPressed: () => _sendMessage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. الملف الشخصي الشامل
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));

    final name = _profile?['name'] ?? 'مستخدم أثير';
    final bio = _profile?['bio'] ?? '';
    final isFounder = _profile?['is_founder'] == true;
    final location = _profile?['location'] ?? '';
    final work = _profile?['work'] ?? '';
    final edu = _profile?['education'] ?? '';
    final birth = _profile?['birth_date'] ?? '';
    final avatar = _profile?['avatar_url'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF7C3AED),
              backgroundImage: avatar.isNotEmpty ? FileImage(File(avatar)) : null,
              child: avatar.isEmpty ? Text(name.isNotEmpty ? name[0] : 'أ', style: const TextStyle(fontSize: 42, color: Colors.white)) : null,
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
          Center(child: Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7C3AED)))),
          const SizedBox(height: 20),
          const Divider(),
          if (location.isNotEmpty) ListTile(leading: const Icon(Icons.location_on, color: Color(0xFF7C3AED)), title: const Text('الموقع الجغرافي والسكن'), subtitle: Text(location)),
          if (work.isNotEmpty) ListTile(leading: const Icon(Icons.work, color: Color(0xFF7C3AED)), title: const Text('العمل'), subtitle: Text(work)),
          if (edu.isNotEmpty) ListTile(leading: const Icon(Icons.school, color: Color(0xFF7C3AED)), title: const Text('التعليم والدراسة'), subtitle: Text(edu)),
          if (birth.isNotEmpty) ListTile(leading: const Icon(Icons.cake, color: Color(0xFF7C3AED)), title: const Text('تاريخ الميلاد'), subtitle: Text(birth)),
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
