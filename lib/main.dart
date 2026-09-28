import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'utils/constants.dart';
import 'services/storage_service.dart';
import 'screens/feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';

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
              titleTextStyle: TextStyle(color: FBColors.primaryBlue, fontSize: 24, fontWeight: FontWeight.w900),
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
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
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
// 1. شاشة تسجيل الدخول وإنشاء الحساب بهوية "أثير"
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
  File? _avatarFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 600);
    if (file != null) {
      setState(() => _avatarFile = File(file.path));
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
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
          String? avatarCloudUrl;
          if (_avatarFile != null) {
            avatarCloudUrl = await StorageService.uploadImage(file: _avatarFile!, folder: 'avatars');
          }

          final isFounder = email.toLowerCase().contains('anas') || name.contains('أنس');
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'name': name,
            'avatar_url': avatarCloudUrl ?? '',
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
                          backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                          child: _avatarFile == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [Icon(Icons.camera_alt, color: FBColors.primaryBlue, size: 24), Text('صورتك', style: TextStyle(fontSize: 10, color: Colors.white70))],
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: _fbInputDecor('الاسم الكامل المعروض', Icons.person_outline)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: locationsData.containsKey(_selectedCountry) ? _selectedCountry : 'فلسطين',
                              dropdownColor: const Color(0xFF242526),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _fbInputDecor('الدولة', Icons.flag_outlined),
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
                              value: safeCity,
                              dropdownColor: const Color(0xFF242526),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _fbInputDecor('المدينة', Icons.location_city_outlined),
                              items: currentCities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                              Text(_selectedBirthDate.isEmpty ? 'تاريخ الميلاد' : _selectedBirthDate, style: TextStyle(color: _selectedBirthDate.isEmpty ? Colors.white38 : Colors.white, fontSize: 13)),
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

// ==========================================
// 2. الهيكل الرئيسي وربط الشاشات
// ==========================================
class FacebookStyleMain extends StatefulWidget {
  const FacebookStyleMain({super.key});

  @override
  State<FacebookStyleMain> createState() => _FacebookStyleMainState();
}

class _FacebookStyleMainState extends State<FacebookStyleMain> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      FeedScreen(
        onOpenProfile: (uid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)));
        },
        onOpenChat: () {
          setState(() => _tabIndex = 2);
        },
      ),
      SocialHubScreen(
        onOpenProfile: (uid) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)));
        },
      ),
      const ChatsListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_tabIndex],
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
            BottomNavigationBarItem(icon: Icon(Icons.person, size: 26), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. شاشة المجتمع واستكشاف الأصدقاء
// ==========================================
class SocialHubScreen extends StatefulWidget {
  final Function(String userId)? onOpenProfile;
  const SocialHubScreen({super.key, this.onOpenProfile});

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
                        onTap: () {
                          if (widget.onOpenProfile != null) widget.onOpenProfile!(uid);
                        },
                        child: CircleAvatar(
                          backgroundImage: getUniversalImageProvider(u['avatar_url']),
                          child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'])) : null,
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          if (widget.onOpenProfile != null) widget.onOpenProfile!(uid);
                        },
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
                              onTap: () {
                                if (widget.onOpenProfile != null) widget.onOpenProfile!(u['id']);
                              },
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
