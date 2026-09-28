import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AtheerApp());
}

class AtheerApp extends StatelessWidget {
  const AtheerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أَثِـيـر',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: const Color(0xFF7C3AED),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1523),
          elevation: 0,
        ),
      ),
      home: const FacebookStyleMain(),
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
    return Scaffold(
      body: _screens[_tabIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1523),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8B5CF6),
          unselectedItemColor: Colors.white38,
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
// 1. الخلاصة الرئيسية بنمط فيسبوك وألوان أثير
// ==========================================
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _initialPosts = [
    {
      'id': 'p1',
      'author': 'أنس قديح',
      'isFounder': true,
      'time': 'منذ 15 دقيقة',
      'text': 'أهلاً بكم في فضاء "أَثِـير"! قمنا بتطوير تجربة جديدة بالكامل تجمع بين قوة فيسبوك وهيبة التصميم النيوني الحديث. شاركونا آراءكم 🚀✨',
      'image': 'https://picsum.photos/600/350?random=11',
      'likes': 42,
      'isLiked': false,
      'comments': ['تصميم جبار وأنيق جداً!', 'ألف مبارك الانطلاقة القوية!'],
    },
    {
      'id': 'p2',
      'author': 'أحمد علي',
      'isFounder': false,
      'time': 'منذ ساعة',
      'text': 'الواجهة خرافية وسلسة بشكل غير مسبوق، ألوان النيون مع الوضع الليلي مريحة جداً للعين.',
      'image': '',
      'likes': 19,
      'isLiked': true,
      'comments': ['فعلاً تجربة ممتازة'],
    },
    {
      'id': 'p3',
      'author': 'مهندس جهاد',
      'isFounder': false,
      'time': 'منذ 3 ساعات',
      'text': 'صورة اليوم من كواليس العمل وتطوير المنظومة 💻⚡',
      'image': 'https://picsum.photos/600/350?random=12',
      'likes': 31,
      'isLiked': false,
      'comments': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('atheer_feed_posts');
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _posts = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _posts = List.from(_initialPosts);
        _isLoading = false;
      });
      await prefs.setString('atheer_feed_posts', jsonEncode(_posts));
    }
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atheer_feed_posts', jsonEncode(_posts));
  }

  void _createPostDialog() {
    final textCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131A2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
                  children: const [
                    Text('أنس قديح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('مشاركة للعامة 🌐', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'بِمَ تفكّر يا أنس؟ انشر أثرك هنا...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Colors.white12),
            TextField(
              controller: imgCtrl,
              decoration: const InputDecoration(
                hintText: 'رابط صورة (اختياري)...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: Icon(Icons.image_rounded, color: Color(0xFFA78BFA), size: 20),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 14),
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
                  if (text.isNotEmpty) {
                    setState(() {
                      _posts.insert(0, {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'author': 'أنس قديح',
                        'isFounder': true,
                        'time': 'الآن',
                        'text': text,
                        'image': imgCtrl.text.trim(),
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

  void _openCommentsModal(int index) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final List comments = _posts[index]['comments'] as List;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: SizedBox(
              height: 400,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  const Text('التعليقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: comments.isEmpty
                        ? const Center(child: Text('كن أول من يترك أثراً هنا!', style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (ctx, i) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161F32),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(comments[i].toString(), style: const TextStyle(fontSize: 13, color: Colors.white)),
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
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF1A2338),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send_rounded, color: Color(0xFF8B5CF6)),
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
            const Text(
              'أَثِـيـر',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: const Color(0xFF1A2338), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
            ),
            onPressed: () {},
          ),
          // زر ماسنجر أثير العلوي
          IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: const Color(0xFF1A2338), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chat_bubble_rounded, size: 20, color: Color(0xFFA78BFA)),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const MessengerListScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : ListView(
              children: [
                // 1. شريط "بِمَ تفكر؟" بنمط فيسبوك
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121826),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)]),
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFF1A2338),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _createPostDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2338),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Text(
                                  'بِمَ تفكّر يا أنس؟ انشر أثراً جديداً...',
                                  style: TextStyle(color: Colors.white38, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickAction(Icons.photo_library_rounded, 'صورة/فيديو', Colors.tealAccent, _createPostDialog),
                          _buildQuickAction(Icons.mic_rounded, 'صوتية', const Color(0xFFA78BFA), _createPostDialog),
                          _buildQuickAction(Icons.location_on_rounded, 'موقع حي', Colors.pinkAccent, _createPostDialog),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. قصص الأثر الرأسية (FB Stories)
                SizedBox(
                  height: 175,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildAddStoryCard(),
                      _buildStoryCard('سليمان', 'https://picsum.photos/200/300?random=1'),
                      _buildStoryCard('محمود', 'https://picsum.photos/200/300?random=2'),
                      _buildStoryCard('أحمد علي', 'https://picsum.photos/200/300?random=3'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 3. قائمة المنشورات (News Feed)
                ...List.generate(_posts.length, (index) {
                  final post = _posts[index];
                  return _buildPostCard(post, index);
                }),
              ],
            ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  // بطاقة إضافة قصة
  Widget _buildAddStoryCard() {
    return Container(
      width: 105,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A2338),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(child: Icon(Icons.person, size: 36, color: Colors.white54)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.only(top: 14),
                  child: const Text('أضف قصة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 36,
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

  // بطاقة قصة الأصدقاء
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
            colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
              ),
              child: const CircleAvatar(radius: 14, backgroundColor: Color(0xFF1A2338), child: Icon(Icons.person, size: 16)),
            ),
            Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // بطاقة المنشور المتكاملة
  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final bool isLiked = post['isLiked'] == true;
    final bool isFounder = post['isFounder'] == true;
    final String img = post['image'] ?? '';
    final List comments = post['comments'] as List;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isFounder ? const Color(0xFFF59E0B).withOpacity(0.3) : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFounder
                        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)])
                        : null,
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFF1E283F),
                    child: Icon(Icons.person, color: Colors.white70),
                  ),
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
            subtitle: Text('${post['time']} • 🌐 عام', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: const Icon(Icons.more_horiz_rounded, color: Colors.white54),
          ),

          // نص المنشور
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              post['text'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
            ),
          ),

          // صورة المنشور
          if (img.isNotEmpty) ...[
            const SizedBox(height: 10),
            Image.network(
              img,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ],

          // عداد التفاعل
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
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('${post['likes']}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
                Text('${comments.length} تعليقات', style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // شريط الأزرار التفاعلية بنمط فيسبوك
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPostAction(
                  icon: isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                  label: 'أعجبني',
                  color: isLiked ? const Color(0xFF8B5CF6) : Colors.white60,
                  onTap: () => _toggleLike(index),
                ),
                _buildPostAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'تعليق',
                  color: Colors.white60,
                  onTap: () => _openCommentsModal(index),
                ),
                _buildPostAction(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  color: Colors.white60,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت مشاركة المنشور في أثرك بنجاح!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
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
// 2. ماسنجر أثير (مركز المحادثات السريعة)
// ==========================================
class MessengerListScreen extends StatelessWidget {
  const MessengerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رسائل أثير ⚡', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _chatTile(context, 'أحمد قديح', 'تم مراجعة فكرة النظام والتصميم ممتاز جداً 🚀', '10:45 ص', true),
          _chatTile(context, 'مهندس جهاد', 'إن شاء الله نلتقي اليوم على الموعد المحدد', 'أمس', false),
          _chatTile(context, 'سليمان أبو الفهد', 'السلام عليكم، طمني كيف الأخبار عندك؟', 'الأحد', false),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext ctx, String name, String msg, String time, bool online) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF121826),
        borderRadius: BorderRadius.circular(16),
      ),
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
                  decoration: BoxDecoration(color: const Color(0xFF10B981), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF090D16), width: 2)),
                ),
              ),
          ],
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        trailing: Text(time, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ),
    );
  }
}

// ==========================================
// 3. شاشات المقاطع والإشعارات والحساب
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
          _videoCard('إطلاق مشروع شبكة أثير السحابية 🌌', 'https://picsum.photos/600/350?random=21'),
          _videoCard('تجربة أداء الواجهات والأنظمة الذكية', 'https://picsum.photos/600/350?random=22'),
        ],
      ),
    );
  }

  Widget _videoCard(String title, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: const Color(0xFF121826), borderRadius: BorderRadius.circular(16)),
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
            title: Text('أحمد علي تفاعل مع منشورك الأخير'),
            subtitle: Text('منذ 10 دقائق', style: TextStyle(color: Colors.white38)),
          ),
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFF06B6D4), child: Icon(Icons.comment, color: Colors.white, size: 18)),
            title: Text('مهندس جهاد علّق: "عمل رائع ومتقن"'),
            subtitle: Text('منذ ساعة', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي الشخصي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFF8B5CF6)]),
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
            children: const [
              Text('أنس قديح', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(width: 6),
              Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('المؤسس والمطور لشبكة أثير 👑', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13)),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('المنشورات', '14'),
              _statItem('المتابعون', '1.2K'),
              _statItem('يتابع', '280'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}
