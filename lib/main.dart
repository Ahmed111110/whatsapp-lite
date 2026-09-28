import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);
final supabase = Supabase.instance.client;

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

// دالة مساعدة لتنسيق توقيت المنشور بالعربية
String formatPostTime(String? timestamp) {
  if (timestamp == null) return 'الآن';
  try {
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

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
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const FacebookStyleMain();
        }
        return const AuthScreen();
      },
    );
  }
}

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

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
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
            'bio': isFounder ? 'المؤسس والمطور لمنصة أثير 👑⚡' : 'عضو في فضاء أثير 🌌',
            'is_founder': isFounder,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
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
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                ),
                child: const Icon(Icons.bubble_chart_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('أَثِـيـر', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 6),
              const Text('فضاء التواصل السحابي المضيء', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13)),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF121826),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'الاسم الكامل أو المستعار',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1A2338),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF8B5CF6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'البريد الإلكتروني',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1A2338),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF8B5CF6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF1A2338),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8B5CF6)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'ليس لديك حساب؟ أنشئ حسابك الآن' : 'لديك حساب بالفعل؟ سجّل دخولك',
                  style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FacebookStyleMain extends StatefulWidget {
  const FacebookStyleMain({super.key});

  @override
  State<FacebookStyleMain> createState() => _FacebookStyleMainState();
}

class _FacebookStyleMainState extends State<FacebookStyleMain> {
  int _tabIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    ExploreUsersScreen(),
    NotificationsScreen(),
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
          border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'الأصدقاء'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'الإشعارات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// الخلاصة السحابية المحدثة
// ==========================================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String _currentUserName = 'مستخدم أثير';
  bool _isFounder = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfileAndPosts();
  }

  Future<void> _fetchProfileAndPosts() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final profile = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profile != null) {
        _currentUserName = profile['name'] ?? 'مستخدم أثير';
        _isFounder = profile['is_founder'] ?? false;
      }
    }
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    try {
      final res = await supabase.from('posts').select().order('created_at', ascending: false);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _createPostModal() {
    final textCtrl = TextEditingController();
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 18, right: 18, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF7C3AED),
                      child: Text(_currentUserName.isNotEmpty ? _currentUserName[0] : 'أ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentUserName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('نشر سحابي عام 🌐', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'انشر أثرك في السيرفر السحابي...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
                if (selectedImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(selectedImagePath!), height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED), size: 20),
                      label: const Text('معرض الصور', style: TextStyle(color: Color(0xFF7C3AED))),
                      onPressed: () async {
                        final file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) setModalState(() => selectedImagePath = file.path);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final text = textCtrl.text.trim();
                      if (text.isNotEmpty) {
                        final user = supabase.auth.currentUser;
                        await supabase.from('posts').insert({
                          'user_id': user?.id,
                          'author_name': _currentUserName,
                          'is_founder': _isFounder,
                          'text': text,
                          'image_url': selectedImagePath ?? '',
                          'likes_count': 0,
                        });
                        Navigator.pop(ctx);
                        _loadPosts();
                      }
                    },
                    child: const Text('نـشـر في أثير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // نافذة التعليقات الحقيقية
  void _openCommentsModal(String postId) {
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Column(
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 12),
                const Text('التعليقات 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: supabase.from('comments').select().eq('post_id', postId).order('created_at', ascending: true),
                    builder: (context, AsyncSnapshot snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                      final comments = snapshot.data as List;
                      if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد، كن أول المعلقين!'));

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (c, i) {
                          final cm = comments[i];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF7C3AED),
                              child: Text((cm['author_name'] ?? 'م')[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            title: Text(cm['author_name'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(cm['content'] ?? '', style: const TextStyle(fontSize: 13)),
                            trailing: Text(formatPostTime(cm['created_at']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
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
                          hintText: 'اكتب تعليقك هنا...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1A2338) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED)),
                      onPressed: () async {
                        final val = commentCtrl.text.trim();
                        if (val.isNotEmpty) {
                          final user = supabase.auth.currentUser;
                          await supabase.from('comments').insert({
                            'post_id': postId,
                            'user_id': user?.id,
                            'author_name': _currentUserName,
                            'content': val,
                          });
                          commentCtrl.clear();
                          setModalState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _likePost(Map<String, dynamic> post) async {
    final int currentLikes = post['likes_count'] ?? 0;
    await supabase.from('posts').update({'likes_count': currentLikes + 1}).eq('id', post['id']);
    _loadPosts();
  }

  void _sharePost(Map<String, dynamic> post) {
    final text = '${post['author_name']}:\n${post['text']}\n\nنُشر عبر تطبيق أثير 🌌';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ نص المنشور بنجاح لمشاركته!'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bubble_chart_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('أَثِـيـر', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.amber : const Color(0xFF7C3AED)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final next = !isDarkModeNotifier.value;
              isDarkModeNotifier.value = next;
              await prefs.setBool('atheer_theme_dark', next);
            },
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadPosts),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView(
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFF7C3AED),
                          child: Text(_currentUserName.isNotEmpty ? _currentUserName[0] : 'أ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _createPostModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text('بِمَ تفكّر يا ${_currentUserName.split(' ').first}؟ شارك العالم...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('لا توجد منشورات بعد! كن أول من ينشر أثراً.')),
                    )
                  else
                    ..._posts.map((post) {
                      final bool isFounder = post['is_founder'] == true;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1E283F),
                                child: Text((post['author_name'] ?? 'م')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Row(
                                children: [
                                  Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (isFounder) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('المؤسس ⚡', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                  ],
                                ],
                              ),
                              // عرض توقيت النشر الحقيقي والتلقائي
                              subtitle: Text('${formatPostTime(post['created_at'])} • 🌐 عام', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                            ),
                            const Divider(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // زر الإعجاب
                                  InkWell(
                                    onTap: () => _likePost(post),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.thumb_up_rounded, size: 16, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 6),
                                        Text('${post['likes_count'] ?? 0} إعجاب', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  // زر التعليق الفعّال
                                  InkWell(
                                    onTap: () => _openCommentsModal(post['id']),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.comment_rounded, size: 16, color: Colors.grey),
                                        SizedBox(width: 6),
                                        Text('تعليق', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  // زر المشاركة
                                  InkWell(
                                    onTap: () => _sharePost(post),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.share_rounded, size: 16, color: Colors.grey),
                                        SizedBox(width: 6),
                                        Text('مشاركة', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
}

// ==========================================
// استكشاف ومتابعة الأصدقاء
// ==========================================
class ExploreUsersScreen extends StatefulWidget {
  const ExploreUsersScreen({super.key});

  @override
  State<ExploreUsersScreen> createState() => _ExploreUsersScreenState();
}

class _ExploreUsersScreenState extends State<ExploreUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  Set<String> _followingIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    setState(() => _loading = true);
    final myId = supabase.auth.currentUser?.id;

    final usersRes = await supabase.from('profiles').select().neq('id', myId ?? '');
    final followsRes = await supabase.from('follows').select('following_id').eq('follower_id', myId ?? '');

    setState(() {
      _users = List<Map<String, dynamic>>.from(usersRes);
      _followingIds = (followsRes as List).map((e) => e['following_id'].toString()).toSet();
      _loading = false;
    });
  }

  Future<void> _toggleFollow(String targetUserId) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    if (_followingIds.contains(targetUserId)) {
      await supabase.from('follows').delete().match({'follower_id': myId, 'following_id': targetUserId});
      setState(() => _followingIds.remove(targetUserId));
    } else {
      await supabase.from('follows').insert({'follower_id': myId, 'following_id': targetUserId});
      setState(() => _followingIds.add(targetUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أصدقاء ومجتمع أثير 👥', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : _users.isEmpty
              ? const Center(child: Text('شارك التطبيق مع أصدقائك ليظهروا هنا!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final u = _users[i];
                    final String uid = u['id'] ?? '';
                    final bool isFollowing = _followingIds.contains(uid);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF7C3AED),
                          child: Text((u['name'] ?? 'أ')[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(u['name'] ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(u['bio'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey.withOpacity(0.2) : const Color(0xFF7C3AED),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _toggleFollow(uid),
                          child: Text(
                            isFollowing ? 'تتابعه ✓' : 'متابعة +',
                            style: TextStyle(color: isFollowing ? Colors.grey : Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات 🔔', style: TextStyle(fontWeight: FontWeight.bold))),
      body: const Center(
        child: Text('أنت على اطلاع بكل جديد في شبكة أثير!'),
      ),
    );
  }
}

// ==========================================
// الملف الشخصي المتكامل مع تعديل البيانات
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

  void _editProfileModal() {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final bioCtrl = TextEditingController(text: _profile?['bio'] ?? '');
    final workCtrl = TextEditingController(text: _profile?['work'] ?? '');
    final eduCtrl = TextEditingController(text: _profile?['education'] ?? '');
    final locCtrl = TextEditingController(text: _profile?['location'] ?? '');
    final birthCtrl = TextEditingController(text: _profile?['birth_date'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 18, right: 18, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تعديل الملف الشخصي ✏️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioCtrl,
                decoration: const InputDecoration(labelText: 'نبذة عنك (Bio)', prefixIcon: Icon(Icons.info_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: workCtrl,
                decoration: const InputDecoration(labelText: 'العمل والمهنة', prefixIcon: Icon(Icons.work_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: eduCtrl,
                decoration: const InputDecoration(labelText: 'التعليم والدراسة', prefixIcon: Icon(Icons.school_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'مكان الإقامة والسكن', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: birthCtrl,
                decoration: const InputDecoration(labelText: 'تاريخ الميلاد', prefixIcon: Icon(Icons.cake_outlined)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () async {
                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      await supabase.from('profiles').upsert({
                        'id': user.id,
                        'name': nameCtrl.text.trim(),
                        'bio': bioCtrl.text.trim(),
                        'work': workCtrl.text.trim(),
                        'education': eduCtrl.text.trim(),
                        'location': locCtrl.text.trim(),
                        'birth_date': birthCtrl.text.trim(),
                      });
                      Navigator.pop(ctx);
                      _loadProfile();
                    }
                  },
                  child: const Text('حفظ التعديلات في السيرفر', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));

    final name = _profile?['name'] ?? 'مستخدم أثير';
    final bio = _profile?['bio'] ?? 'عضو في فضاء أثير';
    final bool isFounder = _profile?['is_founder'] ?? false;
    final work = _profile?['work'] ?? '';
    final edu = _profile?['education'] ?? '';
    final loc = _profile?['location'] ?? '';
    final birth = _profile?['birth_date'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF7C3AED), size: 28),
            onPressed: _editProfileModal,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(name.isNotEmpty ? name[0] : 'أ', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
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
          Center(child: Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 13))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.edit, color: Color(0xFF7C3AED), size: 18),
            label: const Text('تعديل بياناتي وصورتي', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
            onPressed: _editProfileModal,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text('معلومات الحساب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (work.isNotEmpty) ListTile(leading: const Icon(Icons.work_outline, color: Color(0xFF7C3AED)), title: const Text('العمل'), subtitle: Text(work)),
          if (edu.isNotEmpty) ListTile(leading: const Icon(Icons.school_outlined, color: Color(0xFF7C3AED)), title: const Text('الدراسة والتعليم'), subtitle: Text(edu)),
          if (loc.isNotEmpty) ListTile(leading: const Icon(Icons.location_on_outlined, color: Color(0xFF7C3AED)), title: const Text('مكان الإقامة'), subtitle: Text(loc)),
          if (birth.isNotEmpty) ListTile(leading: const Icon(Icons.cake_outlined, color: Color(0xFF7C3AED)), title: const Text('تاريخ الميلاد'), subtitle: Text(birth)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: const Text('تسجيل الخروج من الحساب', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
    );
  }
}
