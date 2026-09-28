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
              activeIcon: Icon(Icons.chat_bubble_rounded, shadows: [Shadow(color: Color(0xFF8B5CF6), blurRadius: 10)]),
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

// ----------------- الشاشة الرئيسية للدردشات -----------------
class ChatsFeedScreen extends StatelessWidget {
  const ChatsFeedScreen({super.key});

  final List<Map<String, dynamic>> stories = const [
    {'name': 'أنت', 'isUser': true},
    {'name': 'سليمان', 'isUser': false},
    {'name': 'محمود', 'isUser': false},
    {'name': 'إبراهيم', 'isUser': false},
    {'name': 'عماد', 'isUser': false},
  ];

  final List<Map<String, dynamic>> chats = const [
    {
      'name': 'أحمد قديح',
      'lastMsg': 'تم مراجعة الفكرة والتصميم ممتاز جداً 🚀',
      'time': '10:45 ص',
      'unread': 2,
      'online': true,
    },
    {
      'name': 'مجموعة التطوير والنقاش',
      'lastMsg': 'صوتية: 0:24 دقيقة 🎙️',
      'time': '09:20 ص',
      'unread': 0,
      'online': false,
    },
    {
      'name': 'مهندس جهاد',
      'lastMsg': 'إن شاء الله نلتقي اليوم على الموعد',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bubble_chart_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'أَثِـيـر',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2438),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, size: 20, color: Colors.white70),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2438),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white70),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: stories.length,
              itemBuilder: (context, index) {
                final st = stories[index];
                final bool isUser = st['isUser'] as bool;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isUser
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                                ),
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
                      Text(
                        st['name'] as String,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المحادثات المباشرة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('4 نشطة', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11)),
                ),
              ],
            ),
          ),
          ...List.generate(chats.length, (i) {
            final chat = chats[i];
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
                    if (chat['online'] as bool)
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
                title: Text(
                  chat['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    chat['lastMsg'] as String,
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
                      chat['time'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: (chat['unread'] as int) > 0 ? const Color(0xFFA78BFA) : Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if ((chat['unread'] as int) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${chat['unread']}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AtheerChatScreen(name: chat['name'] as String),
                    ),
                  );
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
        child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
        onPressed: () {},
      ),
    );
  }
}

// ----------------- شاشة المحادثة مع ميزة الحفظ الدائم في الذاكرة -----------------
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

  @override
  void initState() {
    super.initState();
    _loadSavedMessages();
  }

  // تحميل الرسائل المحفوظة في ذاكرة الهاتف
  Future<void> _loadSavedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('chat_history_${widget.name}');
    if (savedData != null && savedData.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _messages = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        _isLoading = false;
      });
    } else {
      // رسائل افتراضية تظهر لأول مرة فقط
      setState(() {
        _messages = [
          {'text': 'مرحباً بك! فضاء أثير يحفظ محادثاتك بأمان ✨', 'isMe': false, 'time': '10:30 ص', 'isAudio': false},
        ];
        _isLoading = false;
      });
    }
  }

  // حفظ قائمة الرسائل تلقائياً في ذاكرة الهاتف
  Future<void> _persistMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history_${widget.name}', jsonEncode(_messages));
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'الآن',
        'isAudio': false,
      });
      _msgCtrl.clear();
    });
    _persistMessages();

    // رد تفاعلي ذكي
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': 'أثير استلم وحفظ في الذاكرة: "$text" 🔒',
          'isMe': false,
          'time': 'الآن',
          'isAudio': false,
        });
      });
      _persistMessages();
    });
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
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: const [
                    CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text('ذاكرة محلية نشطة 💾', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded, color: Colors.white70), onPressed: () {}),
          IconButton(icon: const Icon(Icons.phone_rounded, color: Colors.white70), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white70), onPressed: () {}),
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
                      final bool isMe = msg['isMe'] as bool;
                      final bool isAudio = msg['isAudio'] == true;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
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
                          child: isAudio
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Color(0xFF8B5CF6),
                                      child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.graphic_eq_rounded, color: Colors.cyanAccent, size: 28),
                                    SizedBox(width: 8),
                                    Text('0:18', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg['text'] as String,
                                      style: const TextStyle(fontSize: 14.5, color: Colors.white, height: 1.3),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          msg['time'] as String,
                                          style: const TextStyle(fontSize: 10, color: Colors.white54),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.done_all_rounded, size: 14, color: Colors.cyanAccent),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF101625),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFA78BFA), size: 26),
                        onPressed: () {},
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
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic_none_rounded, color: Colors.white54),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ----------------- الشاشات الفرعية -----------------
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

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
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
          const SizedBox(height: 14),
          const Center(
            child: Text('مستخدم أثير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('عضو نشط في شبكة أثير', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
