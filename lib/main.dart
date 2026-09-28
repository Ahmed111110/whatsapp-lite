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
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        primaryColor: const Color(0xFF7C3AED),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ChatsFeedScreen(),
    MomentsScreen(),
    CallsScreen(),
    ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131A2A),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8B5CF6),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded),
              label: 'الدردشات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.motion_photos_on_rounded),
              label: 'الأثر',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone_in_talk_rounded),
              label: 'المكالمات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. شاشة المحادثات مع البحث وإضافة شات جديد
// ==========================================
class ChatsFeedScreen extends StatefulWidget {
  const ChatsFeedScreen({super.key});

  @override
  State<ChatsFeedScreen> createState() => _ChatsFeedScreenState();
}

class _ChatsFeedScreenState extends State<ChatsFeedScreen> {
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _chats = [];

  final List<Map<String, dynamic>> _defaultChats = [
    {
      'name': 'أحمد قديح',
      'lastMsg': 'تم مراجعة فكرة النظام والتصميم ممتاز جداً 🚀',
      'time': '10:45 ص',
      'unread': 2,
      'online': true,
    },
    {
      'name': 'مجموعة التطوير والنقاش',
      'lastMsg': 'صوتية: 0:15 دقيقة 🎙️',
      'time': '09:20 ص',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'مهندس جهاد',
      'lastMsg': 'إن شاء الله نلتقي اليوم على الموعد المحدد',
      'time': 'أمس',
      'unread': 0,
      'online': true,
    },
    {
      'name': 'سليمان أبو الفهد',
      'lastMsg': 'السلام عليكم، طمني كيف الأخبار عندك؟',
      'time': 'الأحد',
      'unread': 1,
      'online': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadChatsList();
  }

  Future<void> _loadChatsList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('atheer_chats_index');
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      setState(() {
        _chats = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      setState(() {
        _chats = List.from(_defaultChats);
      });
      await prefs.setString('atheer_chats_index', jsonEncode(_chats));
    }
  }

  Future<void> _saveChatsList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atheer_chats_index', jsonEncode(_chats));
  }

  void _addNewChatDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('بدء محادثة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اكتب اسم جهة الاتصال...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1A2338),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _chats.insert(0, {
                    'name': name,
                    'lastMsg': 'محادثة جديدة نشطة في أثير',
                    'time': 'الآن',
                    'unread': 0,
                    'online': true,
                  });
                });
                _saveChatsList();
                Navigator.pop(ctx);
              }
            },
            child: const Text('إنشاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _chats.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن اسم أو محادثة...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(12),
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
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (!_isSearching) ...[
            SizedBox(
              height: 98,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _buildStoryAvatar('أنت', isUser: true),
                  _buildStoryAvatar('سليمان'),
                  _buildStoryAvatar('محمود'),
                  _buildStoryAvatar('إبراهيم'),
                  _buildStoryAvatar('جهاد'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('المحادثات المباشرة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${filteredChats.length} جهة اتصال', style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
          ...List.generate(filteredChats.length, (i) {
            final chat = filteredChats[i];
            final unreadCount = ((chat['unread'] as num?)?.toInt() ?? 0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                leading: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0xFF1E283F),
                      child: Icon(Icons.person_rounded, color: Colors.white70, size: 28),
                    ),
                    if (chat['online'] == true)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0B0F19), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Text(chat['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chat['lastMsg']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: unreadCount > 0 ? const Color(0xFFA78BFA) : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AtheerChatScreen(name: chat['name']?.toString() ?? ''),
                    ),
                  ).then((_) => _loadChatsList());
                },
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _addNewChatDialog,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _buildStoryAvatar(String name, {bool isUser = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUser ? null : const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
              border: isUser ? Border.all(color: Colors.white24, width: 1.5) : null,
            ),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: const Color(0xFF1B2438),
              child: Icon(
                isUser ? Icons.add_rounded : Icons.person_rounded,
                color: isUser ? const Color(0xFF8B5CF6) : Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ==========================================
// 2. شاشة المحادثة المتقدمة
// ==========================================
class AtheerChatScreen extends StatefulWidget {
  final String name;
  const AtheerChatScreen({super.key, required this.name});

  @override
  State<AtheerChatScreen> createState() => _AtheerChatScreenState();
}

class _AtheerChatScreenState extends State<AtheerChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  String? _currentlyPlayingId;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('chat_history_${widget.name}');
    if (savedData != null && savedData.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _messages = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _messages = [
          {
            'id': '1',
            'type': 'text',
            'text': 'مرحباً بك! فضاء أثير يربطك بأمان وحرية 🌌',
            'isMe': false,
            'time': '10:30 ص',
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history_${widget.name}', jsonEncode(_messages));
  }

  void _deleteMessage(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        title: const Text('حذف الرسالة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل ترغب في حذف هذه الرسالة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() => _messages.removeAt(index));
              _persist();
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _clearFullChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        title: const Text('مسح كامل المحادثة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('سيتم حذف جميع الرسائل المحفوظة في هذا الشات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          TextButton(
            onPressed: () {
              setState(() => _messages.clear());
              _persist();
              Navigator.pop(ctx);
            },
            child: const Text('مسح الكل', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _sendTextMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final newMsg = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': 'text',
      'text': text,
      'isMe': true,
      'time': 'الآن',
    };

    setState(() {
      _messages.add(newMsg);
      _msgCtrl.clear();
    });
    _persist();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      String smartReply = 'أثير استلم رسالتك: "$text" ✨';
      final lower = text.toLowerCase();

      if (lower.contains('سلام') || lower.contains('مرحبا') || lower.contains('أهلا')) {
        smartReply = 'وعليكم السلام ورحمة الله! كيف أمورك اليوم؟';
      } else if (lower.contains('كيفك') || lower.contains('كيف الحال') || lower.contains('شخبارك')) {
        smartReply = 'الحمد لله بألف خير، سعيد بالتواصل معك!';
      } else if (lower.contains('وين') || lower.contains('مكانك') || lower.contains('موقع')) {
        smartReply = 'أنا معك مباشرة عبر شبكة أثير السحابية 🛰️';
      } else if (lower.contains('شكرا') || lower.contains('يسلمو')) {
        smartReply = 'على الرحب والسعة دائماً وأبداً!';
      }

      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'text',
          'text': smartReply,
          'isMe': false,
          'time': 'الآن',
        });
      });
      _persist();
    });
  }

  void _toggleRecordAudio() {
    if (_isRecording) {
      _recordTimer?.cancel();
      final sec = _recordSeconds;
      setState(() {
        _isRecording = false;
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'audio',
          'duration': '0:${sec < 10 ? '0$sec' : sec}',
          'isMe': true,
          'time': 'الآن',
        });
        _recordSeconds = 0;
      });
      _persist();

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'type': 'text',
            'text': 'استمعت لرسالتك الصوتية بكل وضوح 🎙️👍',
            'isMe': false,
            'time': 'الآن',
          });
        });
        _persist();
      });
    } else {
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordSeconds++);
      });
    }
  }

  void _cancelRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendImage(String imageUrl, String caption) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'image',
        'url': imageUrl,
        'caption': caption,
        'isMe': true,
        'time': 'الآن',
      });
    });
    _persist();
  }

  void _sendVideo(String title, String duration) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'video',
        'title': title,
        'duration': duration,
        'isMe': true,
        'time': 'الآن',
      });
    });
    _persist();
  }

  void _sendLocation(String name, String coords) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'location',
        'name': name,
        'coords': coords,
        'isMe': true,
        'time': 'الآن',
      });
    });
    _persist();
  }

  void _openAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachIcon(Icons.image_rounded, 'معرض الصور', Colors.purpleAccent, () {
                  Navigator.pop(ctx);
                  _openGalleryPicker();
                }),
                _buildAttachIcon(Icons.videocam_rounded, 'فيديو', Colors.pinkAccent, () {
                  Navigator.pop(ctx);
                  _sendVideo('تسجيل فيديو بجودة فائقة', '0:34');
                }),
                _buildAttachIcon(Icons.location_on_rounded, 'موقع حي', Colors.tealAccent, () {
                  Navigator.pop(ctx);
                  _sendLocation('موقعي الحالي (نقطة اتصال نشطة)', '31.3458° N, 34.3045° E');
                }),
                _buildAttachIcon(Icons.insert_drive_file_rounded, 'مستند', Colors.indigoAccent, () {
                  Navigator.pop(ctx);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openGalleryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF101625),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر من الوسائط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _mediaItem(ctx, 'https://picsum.photos/400/300?random=1', 'منظر طبيعي خلاب'),
                  _mediaItem(ctx, 'https://picsum.photos/400/300?random=2', 'مشروع تقني حديث'),
                  _mediaItem(ctx, 'https://picsum.photos/400/300?random=3', 'لقطة مسائية'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaItem(BuildContext ctx, String url, String caption) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _sendImage(url, caption);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1F2C34),
            child: const Icon(Icons.image, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 28, backgroundColor: color.withOpacity(0.18), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101625),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFF1E283F),
              child: Icon(Icons.person, color: Colors.white70, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children: const [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('متصل في أثير', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone_rounded), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: const Color(0xFF131A2A),
            onSelected: (val) {
              if (val == 'clear') _clearFullChat();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('مسح كامل المحادثة', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['isMe'] == true;
                      return GestureDetector(
                        onLongPress: () => _deleteMessage(index),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: _buildBubble(msg, isMe),
                        ),
                      );
                    },
                  ),
                ),
                _isRecording ? _buildRecordingBar() : _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    final type = msg['type']?.toString() ?? 'text';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : const Color(0xFF161F32),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: isMe ? const Color(0xFF7C3AED).withOpacity(0.25) : Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (type == 'text')
            Text(msg['text']?.toString() ?? '', style: const TextStyle(fontSize: 14.5, color: Colors.white, height: 1.3))
          else if (type == 'audio')
            _buildAudioPlayer(msg['id']?.toString() ?? '', msg['duration']?.toString() ?? '0:15')
          else if (type == 'image')
            _buildImageBubble(msg['url']?.toString() ?? '', msg['caption']?.toString() ?? '')
          else if (type == 'video')
            _buildVideoBubble(msg['title']?.toString() ?? '', msg['duration']?.toString() ?? '0:30')
          else if (type == 'location')
            _buildLocationBubble(msg['name']?.toString() ?? '', msg['coords']?.toString() ?? ''),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg['time']?.toString() ?? 'الآن', style: const TextStyle(fontSize: 10, color: Colors.white54)),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(Icons.done_all_rounded, size: 14, color: Colors.cyanAccent),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(String id, String duration) {
    final bool isPlaying = _currentlyPlayingId == id;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
          color: Colors.white,
          iconSize: 34,
          onPressed: () {
            setState(() {
              _currentlyPlayingId = isPlaying ? null : id;
            });
          },
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                16,
                (i) => Container(
                  width: 3,
                  height: (i % 3 + 1) * 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: isPlaying ? Colors.cyanAccent : Colors.white60,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(duration, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _buildImageBubble(String url, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            height: 180,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              height: 140,
              color: Colors.black26,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
            ),
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(caption, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ],
      ],
    );
  }

  Widget _buildVideoBubble(String title, String duration) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFEC4899), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('فيديو • $duration', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBubble(String name, String coords) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(coords, style: const TextStyle(fontSize: 10, color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(color: Color(0xFF101625)),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFA78BFA), size: 26),
            onPressed: _openAttachmentSheet,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2338),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة في أثير...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleRecordAudio,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E283F),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFFA78BFA), size: 20),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendTextMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF101625),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            'جاري التسجيل: 0:${_recordSeconds < 10 ? '0$_recordSeconds' : _recordSeconds}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Spacer(),
          TextButton(
            onPressed: _cancelRecording,
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _toggleRecordAudio,
            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            label: const Text('إرسال الصوت', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. شاشات الأثر والمكالمات
// ==========================================
class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأثر والمستجدات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome_rounded, size: 60, color: Color(0xFF8B5CF6)),
            SizedBox(height: 14),
            Text('مساحة اللحظات والقصص المضيئة', style: TextStyle(fontSize: 16, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الاتصالات', style: TextStyle(fontWeight: FontWeight.bold))),
      body: const Center(
        child: Text('لا توجد مكالمات فائتة حالياً', style: TextStyle(color: Colors.white54)),
      ),
    );
  }
}

// ==========================================
// 4. الملف الشخصي التفاعلي مع الحفظ في الذاكرة
// ==========================================
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _name = 'أنس قديح';
  String _bio = 'عضو نشط في شبكة أثير الرقمية 🌌';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('profile_name') ?? 'أنس قديح';
      _bio = prefs.getString('profile_bio') ?? 'عضو نشط في شبكة أثير الرقمية 🌌';
      _isLoading = false;
    });
  }

  Future<void> _editProfileDialog() async {
    final nameCtrl = TextEditingController(text: _name);
    final bioCtrl = TextEditingController(text: _bio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تعديل الحساب الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'الاسم المستعار', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'النبذة الشخصية (الحالة)', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('profile_name', nameCtrl.text.trim());
              await prefs.setString('profile_bio', bioCtrl.text.trim());
              setState(() {
                _name = nameCtrl.text.trim();
                _bio = bioCtrl.text.trim();
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)]),
                        ),
                        child: const CircleAvatar(
                          radius: 46,
                          backgroundColor: Color(0xFF1E283F),
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Center(child: Text(_bio, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 13))),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2438),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _editProfileDialog,
                  icon: const Icon(Icons.edit_rounded, color: Color(0xFFA78BFA), size: 20),
                  label: const Text('تعديل البيانات الشخصية', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
    );
  }
}
