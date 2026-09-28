import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// متحكم المظهر العام (نهاري / ليلي)
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);

// عميل الاتصال السحابي
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الاتصال بمشروعك السحابي
  await Supabase.initialize(
    url: 'https://jflrgszsqhptcxsxbaej.supabase.co',
    anonKey: 'sb_publishable_wgWmv7UJ4lbH_5m3UZ8FSg_l8rbAADB',
  );

  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('atheer_theme_dark') ?? true;

  runApp(const AtheerApp());
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
          // فحص حالة الجلسة: إذا كان المستخدم مسجلاً يفتح التطبيق مباشرة وإلا تظهر شاشة الدخول
          home: const AuthGate(),
        );
      },
    );
  }
}

// ==========================================
// 1. بوابة فحص المستخدم (Auth Gate)
// ==========================================
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

// ==========================================
// 2. شاشة تسجيل الدخول وإنشاء الحساب
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
            'bio': isFounder ? 'المؤسس والمطور لمنصة وشبكة أثير 👑⚡' : 'عضو في فضاء أثير 🌌',
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
              const Text(
                'أَثِـيـر',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 6),
              const Text(
                'فضاء التواصل السحابي المضيء',
                style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13),
              ),
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
                            : Text(
                                _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
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

// ==========================================
// 3. الشاشة الرئيسية والتبويبات
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
// 4. الخلاصة السحابية المباشرة (Cloud Feed)
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
              left: 18,
              right: 18,
              top: 20,
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
                  maxLines: 3,
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

  void _likePost(Map<String, dynamic> post) async {
    final int currentLikes = post['likes_count'] ?? 0;
    await supabase.from('posts').update({'likes_count': currentLikes + 1}).eq('id', post['id']);
    _loadPosts();
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
                  // شريط إنشاء المنشور
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

                  // قائمة المنشورات السحابية
                  if (_posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('لا توجد منشورات سحابية بعد! كن أول من ينشر أثراً.')),
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
                              subtitle: const Text('سحابي • 🌐 عام', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
                            ),
                            const Divider(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
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
                                  const Text('تعليق 💬', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
// 5. استكشاف ومتابعة الأصدقاء (Follow System)
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

// ==========================================
// 6. الإشعارات والحساب الشخصي مع تسجيل الخروج
// ==========================================
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'مستخدم أثير';
  String _bio = 'عضو في شبكة أثير 🌌';
  bool _isFounder = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final res = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      if (res != null) {
        setState(() {
          _name = res['name'] ?? 'مستخدم أثير';
          _bio = res['bio'] ?? '';
          _isFounder = res['is_founder'] ?? false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('ملفي السحابي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(_name.isNotEmpty ? _name[0] : 'أ', style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (_isFounder) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Center(child: Text(_bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 13))),
          const SizedBox(height: 10),
          Center(child: Text(user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12))),
          const SizedBox(height: 28),
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
