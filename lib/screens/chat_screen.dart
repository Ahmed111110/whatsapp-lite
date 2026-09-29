import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';

final supabase = Supabase.instance.client;

// ==========================================
// 1. قائمة المحادثات
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
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: getUniversalImageProvider(u['avatar_url']),
            child: (u['avatar_url'] == null || u['avatar_url'] == '') ? Text(getFirstChar(u['name'])) : null,
          ),
          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(isRequest ? 'طلب محادثة' : (u['bio'] ?? 'انقر لفتح المحادثة'), maxLines: 1),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: u))),
        );
      },
    );
  }
}

// ==========================================
// 2. شاشة المحادثة المتقدمة
// ==========================================
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

  String get _tId => widget.targetUser['id']?.toString() ?? '';
  String get _tName => widget.targetUser['name']?.toString() ?? 'مستخدم أثير';
  String get _tAvatar => widget.targetUser['avatar_url']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(_onTypingChanged);
    _updateMyPresence();
    _fetchMessages();
    _checkStatus();
    _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      _fetchMessages(silent: true);
      _checkStatus();
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
      if (diff.inMinutes < 60) return 'نشط منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'نشط منذ ${diff.inHours} ساعة';
      if (diff.inDays == 1) return 'نشط بالأمس';
      if (diff.inDays < 7) return 'نشط منذ ${diff.inDays} أيام';
      return 'نشط في ${seenTime.day}/${seenTime.month}';
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

      final unread = raw
          .where((m) => m['sender_id'] == _tId && m['receiver_id'] == myId && m['is_read'] != true)
          .map((m) => m['id'])
          .toList();

      if (unread.isNotEmpty) {
        await supabase.from('messages').update({'is_read': true, 'is_delivered': true}).filter('id', 'in', unread);
      }

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
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send({String? imgUrl, String? text, bool forwarded = false, String? targetId}) async {
    final content = text ?? _msgCtrl.text.trim();
    if (content.isEmpty && imgUrl == null) return;
    final myId = supabase.auth.currentUser?.id;
    final dest = targetId ?? _tId;
    if (myId == null || dest.isEmpty) return;

    if (targetId == null) {
      _msgCtrl.clear();
      _setTyping(false);
    }

    bool isOnline = false;
    try {
      final target = await supabase.from('profiles').select('last_seen').eq('id', dest).maybeSingle();
      if (target != null && target['last_seen'] != null) {
        final diff = DateTime.now().difference(DateTime.parse(target['last_seen'].toString()).toLocal()).inMinutes;
        isOnline = diff < 3;
      }
    } catch (_) {}

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': dest,
      'content': content,
      'image_url': imgUrl ?? '',
      'is_deleted': false,
      'is_forwarded': forwarded,
      'is_delivered': isOnline,
      'is_read': false,
      'reaction': '',
    });

    if (targetId == null) _fetchMessages();
  }

  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 900);
    if (f == null) return;
    setState(() => _uploadingImage = true);
    final url = await StorageService.uploadImage(file: File(f.path), folder: 'chats');
    setState(() => _uploadingImage = false);
    if (url != null) _send(imgUrl: url, text: '📷 صورة');
  }

  void _showMsgMenu(Map<String, dynamic> msg) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMe = msg['sender_id'] == myId;
    final bool isDel = msg['is_deleted'] == true;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDel)
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
            if (!isDel)
              ListTile(
                leading: const Icon(Icons.reply, color: FBColors.primaryBlue),
                title: const Text('إعادة توجيه ↪️'),
                onTap: () {
                  Navigator.pop(ctx);
                  _forwardMsg(msg);
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
            if (isMe && !isDel)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('حذف لدى الجميع 🚫', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('messages').update({
                    'is_deleted': true,
                    'content': 'تم حذف هذه الرسالة 🚫',
                    'image_url': '',
                    'reaction': '',
                  }).eq('id', msg['id']);
                  _fetchMessages();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _forwardMsg(Map<String, dynamic> msg) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId).eq('status', 'accepted');
    final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId).eq('status', 'accepted');
    final ids = <String>{};
    for (var f in f1) { ids.add(f['receiver_id'].toString()); }
    for (var f in f2) { ids.add(f['sender_id'].toString()); }

    if (ids.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ليس لديك أصدقاء بعد لإعادة التوجيه لهم!')));
      return;
    }

    final friends = await supabase.from('profiles').select().filter('id', 'in', ids.toList());
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => ListView.builder(
        itemCount: friends.length,
        itemBuilder: (c, i) {
          final fr = friends[i];
          return ListTile(
            leading: CircleAvatar(backgroundImage: getUniversalImageProvider(fr['avatar_url'])),
            title: Text(fr['name'] ?? ''),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
              child: const Text('إرسال', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.pop(ctx);
                await _send(text: msg['content'], imgUrl: msg['image_url'], forwarded: true, targetId: fr['id']);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة التوجيه بنجاح!')));
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicks(Map<String, dynamic> m) {
    if (m['is_read'] == true) {
      return const Icon(Icons.done_all, size: 14, color: Color(0xFF31A24C));
    } else if (m['is_delivered'] == true) {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    }
    return const Icon(Icons.done, size: 14, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser?.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusText = _formatStatusText();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: getUniversalImageProvider(_tAvatar)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusText.contains('نشط الآن') || statusText.contains('الكتابة')
                        ? const Color(0xFF31A24C)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
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

                return GestureDetector(
                  onLongPress: () => _showMsgMenu(m),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isDel ? Colors.grey.withOpacity(0.2) : (isMe ? FBColors.primaryBlue : (isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB))),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if ((m['image_url'] ?? '').isNotEmpty && !isDel)
                                Padding(padding: const EdgeInsets.only(bottom: 4), child: renderUniversalImage(m['image_url'], height: 160, width: double.infinity, borderRadius: BorderRadius.circular(8))),
                              if ((m['content'] ?? '').isNotEmpty)
                                Text(m['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black), fontSize: 14)),
                              if (m['is_forwarded'] == true && !isDel)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.reply, size: 10, color: Colors.grey),
                                      SizedBox(width: 2),
                                      Text('رسالة موجّهة', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(formatArabicTime(m['created_at']), style: TextStyle(fontSize: 8.5, color: isMe ? Colors.white70 : Colors.grey)),
                                  if (isMe && !isDel) ...[const SizedBox(width: 4), _buildTicks(m)],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (reaction.isNotEmpty)
                          Positioned(
                            bottom: -4,
                            right: isMe ? 0 : null,
                            left: isMe ? null : 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                              child: Text(reaction, style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_uploadingImage)
            const Padding(padding: EdgeInsets.all(4), child: Text('جاري رفع الصورة...', style: TextStyle(fontSize: 11, color: Colors.grey))),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.image, color: FBColors.primaryBlue), onPressed: _uploadingImage ? null : _pickImage),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: isDark ? FBColors.darkInput : FBColors.lightInput, borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(hintText: 'اكتب رسالة...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isTyping ? Icons.send : Icons.thumb_up, color: FBColors.primaryBlue),
                    onPressed: () => _send(text: _isTyping ? null : '👍'),
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
