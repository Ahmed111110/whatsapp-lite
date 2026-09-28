import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// متحكم المظهر العام (ليلي / نهاري)
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          // المظهر النهاري
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3AED),
              secondary: Color(0xFF06B6D4),
              surface: Colors.white,
            ),
          ),
          // المظهر الليلي النيوني
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
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C3AED),
              secondary: Color(0xFF06B6D4),
              surface: Color(0xFF121826),
            ),
          ),
          home: const FacebookStyleMain(),
        );
      },
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
    WatchScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.ondemand_video_rounded), label: 'المقاطع'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'الإشعارات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. شاشة المنشورات والخلاصة مع رفع الصور من المعرض
// ==========================================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _defaultPosts = [
    {
      'id': 'p1',
      'author': 'أنس قديح',
      'isFounder': true,
      'time': 'منذ 10 دقائق',
      'text': 'أهلاً بكم في الإصدار المتكامل من "أَثِـير"! تمت إضافة ميزة استعراض صور الهاتف الحقيقية والتبديل بين الوضع الليلي والنهاري 🚀☀️🌙',
      'image': 'https://picsum.photos/600/350?random=11',
      'likes': 48,
      'isLiked': false,
      'comments': ['إنجاز جبار ومميز جداً!'],
    },
    {
      'id': 'p2',
      'author': 'أحمد علي',
      'isFounder': false,
      'time': 'منذ ساعة',
      'text': 'الوضع النهاري مريح جداً ونظيف، والتطبيق سريع الاستجابة!',
      'image': '',
      'likes': 22,
      'isLiked': true,
      'comments': ['أوافقك الرأي تماماً'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('atheer_feed_posts_v2');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _posts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _posts = List.from(_defaultPosts);
        _isLoading = false;
      });
      await prefs.setString('atheer_feed_posts_v2', jsonEncode(_posts));
    }
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atheer_feed_posts_v2', jsonEncode(_posts));
  }

  // تبديل المظهر وحفظه
  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final nextState = !isDarkModeNotifier.value;
    isDarkModeNotifier.value = nextState;
    await prefs.setBool('atheer_theme_dark', nextState);
  }

  // فتح نافذة إنشاء منشور مع اختيار صورة من الهاتف
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
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF7C3AED),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('أنس قديح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('مشاركة عامة 🌐', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'بِمَ تفكّر يا أنس؟ انشر أثراً جديداً...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    border: InputBorder.none,
                  ),
                ),
                // معاينة الصورة المختارة من المعرض
                if (selectedImagePath != null && selectedImagePath!.isNotEmpty)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(selectedImagePath!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                        onPressed: () => setModalState(() => selectedImagePath = null),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                // أزرار المرفقات لاختيار صورة حقيقية من الجهاز
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED).withOpacity(0.12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED), size: 20),
                      label: const Text('معرض الصور', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                        if (file != null) {
                          setModalState(() => selectedImagePath = file.path);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.withOpacity(0.12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.teal, size: 20),
                      label: const Text('الكاميرا', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final XFile? file = await _picker.pickImage(source: ImageSource.camera);
                        if (file != null) {
                          setModalState(() => selectedImagePath = file.path);
                        }
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
                    onPressed: () {
                      final text = textCtrl.text.trim();
                      if (text.isNotEmpty || selectedImagePath != null) {
                        setState(() {
                          _posts.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'author': 'أنس قديح',
                            'isFounder': true,
                            'time': 'الآن',
                            'text': text,
                            'image': selectedImagePath ?? '',
                            'likes': 0,
                            'isLiked': false,
                            'comments': [],
                          });
                        });
                        _savePosts();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('نـشـر الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      final post = _posts[index];
      final bool liked = post['isLiked'] == true;
      post['isLiked'] = !liked;
      post['likes'] = (post['likes'] as int) + (liked ? -1 : 1);
    });
    _savePosts();
  }

  void _deletePost(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنشور', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من حذف هذا المنشور نهائياً من أثير؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() => _posts.removeAt(index));
              _savePosts();
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _openCommentsModal(int index) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final List comments = _posts[index]['comments'] as List;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: SizedBox(
              height: 380,
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  const Text('التعليقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('كن أول من يترك أثراً في هذا المنشور!'))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (ctx, i) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161F32) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(comments[i].toString()),
                            ),
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
                            fillColor: isDark ? const Color(0xFF1A2338) : const Color(0xFFE2E8F0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF7C3AED)),
                        onPressed: () {
                          final c = commentCtrl.text.trim();
                          if (c.isNotEmpty) {
                            setState(() {
                              (_posts[index]['comments'] as List).add(c);
                            });
                            setModalState(() {});
                            _savePosts();
                            commentCtrl.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
          // زر التبديل بين الوضع النهاري والليلي
          IconButton(
            tooltip: 'تبديل المظهر',
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: isDark ? Colors.amber : const Color(0xFF7C3AED)),
            onPressed: _toggleTheme,
          ),
          // زر ماسنجر أثير
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const MessengerListScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : ListView(
              children: [
                // شريط إنشاء منشور سريع
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 20, backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.person, color: Colors.white)),
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
                                child: Text('بِمَ تفكّر يا أنس؟ انشر أثراً جديداً...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickPostBtn(Icons.image_rounded, 'معرض الصور', const Color(0xFF7C3AED), _createPostModal),
                          _buildQuickPostBtn(Icons.camera_alt_rounded, 'الكاميرا', Colors.teal, _createPostModal),
                          _buildQuickPostBtn(Icons.location_on_rounded, 'الموقع', Colors.pinkAccent, _createPostModal),
                        ],
                      ),
                    ],
                  ),
                ),

                // قصص الأثر
                SizedBox(
                  height: 165,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildAddStoryCard(isDark),
                      _buildStoryCard('سليمان', 'https://picsum.photos/200/300?random=1'),
                      _buildStoryCard('محمود', 'https://picsum.photos/200/300?random=2'),
                      _buildStoryCard('جهاد', 'https://picsum.photos/200/300?random=3'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // بطاقات المنشورات
                ...List.generate(_posts.length, (index) {
                  final post = _posts[index];
                  return _buildPostCard(post, index, isDark);
                }),
              ],
            ),
    );
  }

  Widget _buildQuickPostBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddStoryCard(bool isDark) {
    return Container(
      width: 105,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2338) : const Color(0xFFE2E8F0),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(child: Icon(Icons.person, size: 36, color: Colors.grey)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 10),
                  child: const Text('أضف قصة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 34,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(String name, String imgUrl) {
    return Container(
      width: 105,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)])),
              child: const CircleAvatar(radius: 13, backgroundColor: Colors.black54, child: Icon(Icons.person, size: 14, color: Colors.white)),
            ),
            Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index, bool isDark) {
    final bool isLiked = post['isLiked'] == true;
    final bool isFounder = post['isFounder'] == true;
    final String img = post['image'] ?? '';
    final List comments = post['comments'] as List;

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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFounder ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)]) : null,
                  ),
                  child: const CircleAvatar(radius: 20, backgroundColor: Color(0xFF1E283F), child: Icon(Icons.person, color: Colors.white)),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(post['author'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            subtitle: Text('${post['time']} • 🌐 عام', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 11)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (val) {
                if (val == 'delete') _deletePost(index);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'delete', child: Text('حذف المنشور', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ),
          if ((post['text'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          // عرض الصورة سواء كانت من ألبوم الهاتف أو رابط خارجي
          if (img.isNotEmpty) ...[
            const SizedBox(height: 8),
            _renderPostImage(img),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                      child: const Icon(Icons.thumb_up_rounded, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('${post['likes']}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ),
                Text('${comments.length} تعليقات', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionBtn(
                  icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                  label: 'أعجبني',
                  color: isLiked ? const Color(0xFF7C3AED) : (isDark ? Colors.white60 : Colors.black54),
                  onTap: () => _toggleLike(index),
                ),
                _buildActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'تعليق',
                  color: isDark ? Colors.white60 : Colors.black54,
                  onTap: () => _openCommentsModal(index),
                ),
                _buildActionBtn(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  color: isDark ? Colors.white60 : Colors.black54,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت مشاركة المنشور في أثرك بنجاح!')));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderPostImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, width: double.infinity, height: 220, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox());
    } else {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: double.infinity, height: 240, fit: BoxFit.cover);
      }
      return const SizedBox();
    }
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. شاشات المقاطع، الإشعارات، والماسنجر
// ==========================================
class WatchScreen extends StatelessWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أثير Watch 📺', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _videoItem(context, 'إطلاق الإصدار النهائي من شبكة أثير 🌌', 'https://picsum.photos/600/350?random=21'),
          _videoItem(context, 'كواليس تطوير واجهة المنشورات المزدوجة', 'https://picsum.photos/600/350?random=22'),
        ],
      ),
    );
  }

  Widget _videoItem(BuildContext ctx, String title, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(img, height: 190, width: double.infinity, fit: BoxFit.cover),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
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
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.favorite, color: Colors.white, size: 18)),
            title: Text('أحمد علي أعجب بمنشورك الأخير'),
            subtitle: Text('منذ بضع دقائق'),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF06B6D4), child: Icon(Icons.comment, color: Colors.white, size: 18)),
            title: Text('مهندس جهاد أضاف تعليقاً على أثرك'),
            subtitle: Text('منذ ساعتين'),
          ),
        ],
      ),
    );
  }
}

class MessengerListScreen extends StatelessWidget {
  const MessengerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسائل أثير ⚡', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _chatTile(context, 'أحمد قديح', 'تم تجهيز الواجهة بالكامل بنجاح 🚀', '10:45 ص', true),
          _chatTile(context, 'مهندس جهاد', 'التطبيق أصبح سريعاً جداً وجاهز للإطلاق', 'أمس', false),
          _chatTile(context, 'سليمان أبو الفهد', 'الوضع النهاري فخم ومميز!', 'الأحد', false),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext ctx, String name, String msg, String time, bool online) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Stack(
          children: [
            const CircleAvatar(radius: 24, backgroundColor: Color(0xFF1E283F), child: Icon(Icons.person, color: Colors.white)),
            if (online)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ),
    );
  }
}

// ==========================================
// 3. شاشة الحساب وإعدادات التفنيش (Launch Wall)
// ==========================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'أنس قديح';
  String _bio = 'المؤسس والمطور لمنصة وشبكة أثير 👑⚡';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('profile_name') ?? 'أنس قديح';
      _bio = prefs.getString('profile_bio') ?? 'المؤسس والمطور لمنصة وشبكة أثير 👑⚡';
    });
  }

  void _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('atheer_feed_posts_v2');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفريغ الذاكرة المؤقتة بنجاح وإعادة ضبط الخلاصة!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي والإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final next = !isDarkModeNotifier.value;
              isDarkModeNotifier.value = next;
              await prefs.setBool('atheer_theme_dark', next);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFF7C3AED)]),
              ),
              child: const CircleAvatar(
                radius: 46,
                backgroundColor: Color(0xFF1E283F),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(_bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('المنشورات', '18'),
              _statItem('المتابعون', '1.4K'),
              _statItem('المتابَعين', '320'),
            ],
          ),
          const SizedBox(height: 28),
          const Text('إعدادات المنظومة (Atheer Hub)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_rounded, color: Color(0xFF7C3AED)),
                  title: const Text('مظهر التطبيق'),
                  subtitle: Text(isDark ? 'الوضع الليلي النيوني نشط' : 'الوضع النهاري الفاتح نشط'),
                  trailing: Switch(
                    activeColor: const Color(0xFF7C3AED),
                    value: isDark,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      isDarkModeNotifier.value = val;
                      await prefs.setBool('atheer_theme_dark', val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
                  title: const Text('تفريغ الذاكرة المؤقتة'),
                  subtitle: const Text('إعادة ضبط البيانات المحلية المؤقتة'),
                  onTap: _clearCache,
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: Colors.cyan),
                  title: Text('إصدار المنظومة'),
                  subtitle: Text('Atheer Platform v1.0.0 (Release Candidate)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
