import 'package:flutter/material.dart';

void main() {
  runApp(const WhatsAppLiteApp());
}

class WhatsAppLiteApp extends StatelessWidget {
  const WhatsAppLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'واتساب لايت',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121B22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2C34),
          elevation: 0,
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'واتساب',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00A884),
          indicatorWeight: 3.5,
          labelColor: const Color(0xFF00A884),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: 'الدردشات'),
            Tab(text: 'المستجدات'),
            Tab(text: 'المكالمات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ChatsTab(),
          StatusTab(),
          CallsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00A884),
        onPressed: () {},
        child: const Icon(Icons.chat, color: Colors.black),
      ),
    );
  }
}

// ----------------- تبويب الدردشات -----------------
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  final List<Map<String, dynamic>> chats = const [
    {
      'name': 'أحمد علي',
      'message': 'السلام عليكم، كيف الأمور معك؟',
      'time': '10:42 ص',
      'unread': 2,
    },
    {
      'name': 'مجموعة العمل',
      'message': 'تم رفع النسخة الجديدة للتجربة 👍',
      'time': '09:15 ص',
      'unread': 0,
    },
    {
      'name': 'محمود',
      'message': 'تمام، بنحكي بالليل إن شاء الله',
      'time': 'أمس',
      'unread': 0,
    },
    {
      'name': 'خالد سليم',
      'message': 'صورة 📷',
      'time': 'الأحد',
      'unread': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white10,
        indent: 75,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF00A884),
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          title: Text(
            chat['name'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            chat['message'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                chat['time'],
                style: TextStyle(
                  fontSize: 12,
                  color: chat['unread'] > 0 ? const Color(0xFF00A884) : Colors.white38,
                ),
              ),
              if (chat['unread'] > 0) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${chat['unread']}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(userName: chat['name']),
              ),
            );
          },
        );
      },
    );
  }
}

// ----------------- تبويب الحالات (المستجدات) -----------------
class StatusTab extends StatelessWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // حالتي
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF00A884),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.add, size: 18, color: Colors.black),
                ),
              ),
            ],
          ),
          title: const Text('حالتي', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('انقر لإضافة تحديث للحالة', style: TextStyle(color: Colors.white54)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'آخر المستجدات',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        // قائمة حالات الأصدقاء
        _buildStatusItem('أحمد علي', 'منذ 15 دقيقة'),
        _buildStatusItem('محمود', 'منذ ساعة'),
        _buildStatusItem('سارة إبراهيم', 'اليوم 8:30 ص'),
      ],
    );
  }

  Widget _buildStatusItem(String name, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00A884), width: 2.5),
        ),
        child: const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFF1F2C34),
          child: Icon(Icons.person, color: Colors.white70),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(time, style: const TextStyle(color: Colors.white54)),
    );
  }
}

// ----------------- تبويب المكالمات -----------------
class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFF00A884),
            child: Icon(Icons.link, color: Colors.black),
          ),
          title: Text('إنشاء رابط مكالمة', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('شارك رابطاً لمكالمتك على واتساب', style: TextStyle(color: Colors.white54)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'الأخيرة',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        _CallItem(
          name: 'محمود',
          time: 'اليوم، 10:15 ص',
          isMissed: true,
          isVideo: false,
        ),
        _CallItem(
          name: 'أحمد علي',
          time: 'أمس، 8:20 م',
          isMissed: false,
          isVideo: true,
        ),
        _CallItem(
          name: 'خالد سليم',
          time: '24 سبتمبر، 11:00 ص',
          isMissed: false,
          isVideo: false,
        ),
      ],
    );
  }
}

class _CallItem extends StatelessWidget {
  final String name;
  final String time;
  final bool isMissed;
  final bool isVideo;

  const _CallItem({
    required this.name,
    required this.time,
    required this.isMissed,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isMissed ? Colors.redAccent : Colors.white,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(
            isMissed ? Icons.call_missed : Icons.call_received,
            size: 16,
            color: isMissed ? Colors.redAccent : const Color(0xFF00A884),
          ),
          const SizedBox(width: 5),
          Text(time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
      trailing: Icon(
        isVideo ? Icons.videocam : Icons.call,
        color: const Color(0xFF00A884),
      ),
    );
  }
}

// ----------------- شاشة المحادثة الفردية والرد التفاعلي -----------------
class ChatDetailScreen extends StatefulWidget {
  final String userName;
  const ChatDetailScreen({super.key, required this.userName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'أهلاً بك! كيف حالك؟', 'isMe': false, 'time': '10:30 ص'},
    {'text': 'الحمد لله تمام، كيفك أنت؟', 'isMe': true, 'time': '10:32 ص'},
    {'text': 'كل الأمور ماشية بالتمام إن شاء الله', 'isMe': false, 'time': '10:33 ص'},
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': 'الآن',
      });
      _controller.clear();
    });

    // رد تلقائي تفاعلي بعد ثانية واحدة لإعطاء شعور المحادثة الحقيقية
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text': 'وصلت رسالتك تمام: "$text" 👍',
          'isMe': false,
          'time': 'الآن',
        });
      });
    });
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttachBtn(Icons.insert_drive_file, 'مستند', Colors.indigo),
              _buildAttachBtn(Icons.camera_alt, 'كاميرا', Colors.pinkAccent),
              _buildAttachBtn(Icons.image, 'معرض', Colors.purpleAccent),
              _buildAttachBtn(Icons.location_on, 'موقع', Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachBtn(IconData icon, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFF00A884),
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'متصل الآن',
                    style: TextStyle(fontSize: 11, color: Color(0xFF00A884)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF005C4B) : const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: const TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg['time'],
                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFF1F2C34),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.white70),
                  onPressed: _showAttachmentSheet,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'مراسلة...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2A3942),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFF00A884),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 20),
                    onPressed: _sendMessage,
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
