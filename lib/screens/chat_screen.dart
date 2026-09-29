import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'chat_details_screen.dart';

final supabase = Supabase.instance.client;

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _users = [];
  Set<String> _friendIds = {};
  bool _loading = true;

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
    if (myId == null) return;
    try {
      final res = await supabase.from('profiles').select().neq('id', myId);
      final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId).eq('status', 'accepted');
      final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId).eq('status', 'accepted');
      
      final s = <String>{};
      for (var f in f1) { s.add(f['receiver_id'].toString()); }
      for (var f in f2) { s.add(f['sender_id'].toString()); }

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(res);
          _friendIds = s;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isOnline(dynamic lastSeen) {
    if (lastSeen == null) return false;
    try {
      final t = DateTime.parse(lastSeen.toString()).toLocal();
      return DateTime.now().difference(t).inMinutes < 2;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsList = _users.where((u) => _friendIds.contains(u['id'])).toList();
    final reqsList = _users.where((u) => !_friendIds.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات 💬', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FBColors.primaryBlue,
          tabs: [
            Tab(text: "الأصدقاء (${friendsList.length})"),
            Tab(text: "طلبات المراسلة (${reqsList.length})"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(friendsList, false),
                _buildList(reqsList, true),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, bool isRequest) {
    if (list.isEmpty) {
      return Center(child: Text(isRequest ? 'لا توجد طلبات مراسلة' : 'ابدأ محادثة مع أصدقائك', style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final u = list[i];
        final online = _isOnline(u['last_seen']);

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: getUniversalImageProvider(u['avatar_url']),
                child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'])) : null,
              ),
              if (online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF31A24C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isRequest ? 'طلب محادثة' : (u['bio'] ?? 'انقر لفتح المحادثة'), maxLines: 1),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: u))),
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final dynamic targetUser;
  const ChatScreen({super.key, required this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  bool _isTyping = false;
  bool _targetIsTyping = false;
  String? _targetLastSeen;
  bool _uploadingImage = false;

  String _activeThemeHex = '0xFF0084FF';
  String _quickEmoji = '👍';
  Map<String, dynamic>? _replyMessage;

  String get _tId => widget.targetUser['id']?.toString() ?? '';
  String get _tName => widget.targetUser['name']?.toString() ?? 'مستخدم أثير';
  String get _tAvatar => widget.targetUser['avatar_url']?.toString() ?? '';

  Color get _themeColor => Color(int.parse(_activeThemeHex));

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(_onTypingChanged);
    _loadCloudSettings();
    _updateMyPresence();
    _fetchMessages();
    _checkStatus();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      _fetchMessages(silent: true);
      _checkStatus();
      _loadCloudSettings(silent: true);
      _updateMyPresence();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _setTyping(false);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCloudSettings({bool silent = false}) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;

    try {
      final res = await supabase
          .from('conversation_settings')
          .select('theme_color, quick_emoji')
          .or('and(user1_id.eq.$myId,user2_id.eq.$_tId),and(user1_id.eq.$_tId,user2_id.eq.$myId)')
          .maybeSingle();

      if (res != null && mounted) {
        final c = res['theme_color'] ?? '0xFF0084FF';
        final e = res['quick_emoji'] ?? '👍';
        if (c != _activeThemeHex || e != _quickEmoji) {
          setState(() {
            _activeThemeHex = c;
            _quickEmoji = e;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveQuickSettings(String hex, String emoji) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;

    setState(() {
      _activeThemeHex = hex;
      _quickEmoji = emoji;
    });

    try {
      final existing = await supabase
          .from('conversation_settings')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.$_tId),and(user1_id.eq.$_tId,user2_id.eq.$myId)')
          .maybeSingle();

      if (existing != null) {
        await supabase.from('conversation_settings').update({
          'theme_color': hex,
          'quick_emoji': emoji,
        }).eq('id', existing['id']);
      } else {
        await supabase.from('conversation_settings').insert({
          'user1_id': myId,
          'user2_id': _tId,
          'theme_color': hex,
          'quick_emoji': emoji,
        });
      }
    } catch (_) {}
  }

  Future<void> _updateMyPresence() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase.from('profiles').update({'last_seen': DateTime.now().toIso8601String()}).eq('id', myId);
    } catch (_) {}
  }

  void _onTypingChanged() {
    final has = _msgCtrl.text.trim().isNotEmpty;
    if (has != _isTyping) {
      setState(() => _isTyping = has);
      _setTyping(has);
    }
  }

  Future<void> _setTyping(bool typing) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase.from('profiles').update({
        'typing_to': typing ? _tId : null,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', myId);
    } catch (_) {}
  }

  Future<void> _checkStatus() async {
    if (_tId.isEmpty) return;
    try {
      final t = await supabase.from('profiles').select('typing_to, last_seen').eq('id', _tId).maybeSingle();
      if (t != null && mounted) {
        final myId = supabase.auth.currentUser?.id;
        final bool typing = t['typing_to'] == myId;
        setState(() {
          _targetIsTyping = typing;
          _targetLastSeen = t['last_seen']?.toString();
        });
      }
    } catch (_) {}
  }

  String _formatStatusText() {
    if (_targetIsTyping) return 'جاري الكتابة... ✍️';
    if (_targetLastSeen == null || _targetLastSeen!.isEmpty) return 'غير متصل';

    try {
      final seenTime = DateTime.parse(_targetLastSeen!).toLocal();
      final diff = DateTime.now().difference(seenTime);

      if (diff.inMinutes < 2) return 'نشط الآن 🟢';
      if (diff.inMinutes < 60) return 'نشط منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'نشط منذ ${diff.inHours} س';
      return 'نشط سابقاً';
    } catch (_) {
      return 'غير متصل';
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;
    try {
      final res = await supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$_tId),and(sender_id.eq.$_tId,receiver_id.eq.$myId)')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> raw = List<Map<String, dynamic>>.from(res);
      final filtered = raw.where((m) {
        final isMe = m['sender_id'] == myId;
        if (isMe && m['deleted_by_sender'] == true) return false;
        if (!isMe && m['deleted_by_receiver'] == true) return false;
        return true;
      }).toList();

      if (filtered.length != _messages.length || !silent) {
        if (mounted) {
          setState(() => _messages = filtered);
          _scrollToEnd();
        }
      }
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send({String? imgUrl, String? text, bool isBigEmoji = false}) async {
    String content = text ?? _msgCtrl.text.trim();
    if (content.isEmpty && imgUrl == null) return;
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;

    if (_replyMessage != null) {
      final author = _replyMessage!['sender_id'] == myId ? 'أنت' : _tName;
      final snippet = _replyMessage!['content'] ?? 'صورة';
      content = '↩️ ردًا على $author: "$snippet"\n$content';
    }

    _msgCtrl.clear();
    setState(() => _replyMessage = null);
    _setTyping(false);

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': _tId,
      'content': content,
      'image_url': imgUrl ?? '',
      'is_deleted': false,
      'is_read': false,
      'reaction': isBigEmoji ? 'BIG_EMOJI' : '',
    });

    _fetchMessages();
  }

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 900);
    if (f == null) return;
    setState(() => _uploadingImage = true);
    final url = await StorageService.uploadImage(file: File(f.path), folder: 'chats');
    setState(() => _uploadingImage = false);
    if (url != null) _send(imgUrl: url, text: '📷 صورة');
  }

  // قائمة الإعدادات السريعة بضغطة زر داخل الشات
  void _openQuickMessengerSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تخصيص ماسنجر السريع 🎨', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              const Text('اختر لون المحادثة:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  '0xFF0084FF', // Blue
                  '0xFF833AB4', // Purple
                  '0xFFFF5722', // Orange
                  '0xFF00897B', // Emerald
                  '0xFFE91E63', // Pink
                ].map((hex) {
                  return GestureDetector(
                    onTap: () {
                      _saveQuickSettings(hex, _quickEmoji);
                      Navigator.pop(ctx);
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(int.parse(hex)),
                      child: _activeThemeHex == hex ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('اختر الإيموجي السريع:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '🔥', '😂', '🎉'].map((e) {
                  return GestureDetector(
                    onTap: () {
                      _saveQuickSettings(_activeThemeHex, e);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _quickEmoji == e ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 26)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMsgMenu(Map<String, dynamic> msg) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMe = msg['sender_id'] == myId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['👍', '❤️', '😂', '😮', '😢', '😡', '🔥'].map((emoji) {
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final cur = msg['reaction'] ?? '';
                      await supabase.from('messages').update({'reaction': cur == emoji ? '' : emoji}).eq('id', msg['id']);
                      _fetchMessages();
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.reply, color: _themeColor),
              title: const Text('رد على هذه الرسالة 💬'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyMessage = msg);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('حذف لدي فقط'),
              onTap: () async {
                Navigator.pop(ctx);
                await supabase.from('messages').update({isMe ? 'deleted_by_sender' : 'deleted_by_receiver': true}).eq('id', msg['id']);
                _fetchMessages();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusText = _formatStatusText();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailsScreen(
                  targetUser: widget.targetUser,
                  currentTheme: _activeThemeHex,
                  currentEmoji: _quickEmoji,
                  onSettingsChanged: (hex, em) => _saveQuickSettings(hex, em),
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: getUniversalImageProvider(_tAvatar)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_tName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusText.contains('نشط الآن') || statusText.contains('الكتابة') ? const Color(0xFF31A24C) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            color: _themeColor,
            tooltip: 'تغيير السمة السريعة',
            onPressed: _openQuickMessengerSettings,
          ),
          IconButton(
            icon: Icon(Icons.info, color: _themeColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailsScreen(
                    targetUser: widget.targetUser,
                    currentTheme: _activeThemeHex,
                    currentEmoji: _quickEmoji,
                    onSettingsChanged: (hex, em) => _saveQuickSettings(hex, em),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final m = _messages[i];
                final isMe = m['sender_id'] == myId;
                final isDel = m['is_deleted'] == true;
                final String reaction = m['reaction'] ?? '';
                final bool isBig = reaction == 'BIG_EMOJI';

                // إذا كان إيموجي ضخم
                if (isBig) {
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: Text(m['content'] ?? '', style: const TextStyle(fontSize: 48)),
                    ),
                  );
                }

                // سحب ذكي في كلا الاتجاهين يعمل 100% مع العربي
                return GestureDetector(
                  onHorizontalDragEnd: (details) {
                    HapticFeedback.lightImpact();
                    setState(() => _replyMessage = m);
                  },
                  onLongPress: () => _showMsgMenu(m),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: isDel
                            ? Colors.grey.withOpacity(0.2)
                            : (isMe ? _themeColor : (isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB))),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if ((m['image_url'] ?? '').isNotEmpty && !isDel)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: renderUniversalImage(m['image_url'], height: 160, width: double.infinity, borderRadius: BorderRadius.circular(8)),
                            ),
                          if ((m['content'] ?? '').isNotEmpty)
                            Text(
                              m['content'] ?? '',
                              style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 14),
                            ),
                          const SizedBox(height: 2),
                          Text(formatArabicTime(m['created_at']), style: TextStyle(fontSize: 8.5, color: isMe ? Colors.white70 : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // شريط الرد المعلق
          if (_replyMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5),
              child: Row(
                children: [
                  Icon(Icons.reply, color: _themeColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'رد على: ${_replyMessage!['content'] ?? 'صورة'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyMessage = null),
                  ),
                ],
              ),
            ),

          if (_uploadingImage)
            const Padding(padding: EdgeInsets.all(4), child: Text('جاري رفع الصورة...', style: TextStyle(fontSize: 11, color: Colors.grey))),

          // شريط إدخال الرسائل بنمط ماسنجر
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.image, color: _themeColor), onPressed: _uploadingImage ? null : _pickImage),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? FBColors.darkInput : FBColors.lightInput,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isTyping
                        ? Icon(Icons.send, color: _themeColor)
                        : Text(_quickEmoji, style: const TextStyle(fontSize: 24)),
                    onPressed: () => _send(text: _isTyping ? null : _quickEmoji, isBigEmoji: !_isTyping),
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
