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

// =========================================================================
// شاشة قائمة المحادثات (Chats List Screen)
// =========================================================================
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
    _loadFromCache();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('atheer_cached_chat_users');
    if (cached != null && mounted) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(jsonDecode(cached));
        _loading = false;
      });
    }
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_cached_chat_users', jsonEncode(res));

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
    final nonFriendsList = _users.where((u) => !_friendIds.contains(u['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدردشات 💬', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FBColors.primaryBlue,
          tabs: [
            Tab(text: 'الأصدقاء (${friendsList.length})'),
            Tab(text: 'طلبات المراسلة (${nonFriendsList.length})'),
          ],
        ),
      ),
      body: _loading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _chatUserList(friendsList, false),
                _chatUserList(nonFriendsList, true),
              ],
            ),
    );
  }

  Widget _chatUserList(List<Map<String, dynamic>> list, bool isRequest) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isRequest ? 'لا توجد طلبات مراسلة حالياً' : 'ابدأ محادثة جديدة مع أحد أصدقائك',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final u = list[i];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: getUniversalImageProvider(u['avatar_url']),
                child: (u['avatar_url'] == null || u['avatar_url'] == '')
                    ? Text(getFirstChar(u['name']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF31A24C),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(
            isRequest ? 'طلب محادثة من غير الأصدقاء' : (u['bio'] ?? 'انقر لفتح المحادثة المباشرة'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(targetUser: u)),
            );
          },
        );
      },
    );
  }
}

// =========================================================================
// شاشة المحادثة المتقدمة
// =========================================================================
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
  Timer? _pollingTimer;
  bool _isTyping = false;
  bool _targetIsTyping = false;
  bool _uploadingImage = false;

  String get _targetUserId => widget.targetUser['id']?.toString() ?? '';
  String get _targetUserName => widget.targetUser['name']?.toString() ?? 'مستخدم أثير';
  String get _targetUserAvatar => widget.targetUser['avatar_url']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(_onTextChanged);
    _loadCachedMessages();
    _fetchMessages();
    _updateMyPresence();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _fetchMessages(silent: true);
      _checkTargetTypingAndOnline();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _clearTypingStatus();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _msgCtrl.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() => _isTyping = hasText);
      _setTypingStatus(hasText);
    }
  }

  Future<void> _setTypingStatus(bool typing) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase.from('profiles').update({
        'typing_to': typing ? _targetUserId : null,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', myId);
    } catch (_) {}
  }

  Future<void> _clearTypingStatus() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase.from('profiles').update({'typing_to': null}).eq('id', myId);
    } catch (_) {}
  }

  Future<void> _updateMyPresence() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;
    try {
      await supabase.from('profiles').update({'last_seen': DateTime.now().toIso8601String()}).eq('id', myId);
    } catch (_) {}
  }

  Future<void> _checkTargetTypingAndOnline() async {
    if (_targetUserId.isEmpty) return;
    try {
      final target = await supabase.from('profiles').select('typing_to, last_seen').eq('id', _targetUserId).maybeSingle();
      if (target != null && mounted) {
        final myId = supabase.auth.currentUser?.id;
        final bool isTypingToMe = target['typing_to'] == myId;
        if (isTypingToMe != _targetIsTyping) {
          setState(() => _targetIsTyping = isTypingToMe);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCachedMessages() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _targetUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('atheer_chat_${myId}_$_targetUserId');
    if (cached != null && mounted) {
      setState(() => _messages = List<Map<String, dynamic>>.from(jsonDecode(cached)));
      _scrollToBottom();
    }
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _targetUserId.isEmpty) return;

    try {
      final res = await supabase.from('messages')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$_targetUserId),and(sender_id.eq.$_targetUserId,receiver_id.eq.$myId)')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> rawMsgs = List<Map<String, dynamic>>.from(res);

      final filteredMsgs = rawMsgs.where((m) {
        final isMe = m['sender_id'] == myId;
        if (isMe && (m['deleted_by_sender'] == true)) return false;
        if (!isMe && (m['deleted_by_receiver'] == true)) return false;
        return true;
      }).toList();

      final unreadIds = rawMsgs
          .where((m) => m['sender_id'] == _targetUserId && m['receiver_id'] == myId && m['is_read'] != true)
          .map((m) => m['id'])
          .toList();

      if (unreadIds.isNotEmpty) {
        await supabase.from('messages').update({
          'is_read': true,
          'is_delivered': true,
        }).filter('id', 'in', unreadIds);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_chat_${myId}_$_targetUserId', jsonEncode(filteredMsgs));

      if (filteredMsgs.length != _messages.length || !silent) {
        if (mounted) {
          setState(() => _messages = filteredMsgs);
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage({String? cloudImageUrl, String? customText, bool isForwarded = false, String? directReceiverId}) async {
    final text = customText ?? _msgCtrl.text.trim();
    if (text.isEmpty && cloudImageUrl == null) return;

    final myId = supabase.auth.currentUser?.id;
    final otherId = directReceiverId ?? _targetUserId;
    if (myId == null || otherId.isEmpty) return;

    if (directReceiverId == null) {
      _msgCtrl.clear();
      _setTypingStatus(false);
    }

    bool isOnline = false;
    try {
      final target = await supabase.from('profiles').select('last_seen').eq('id', otherId).maybeSingle();
      if (target != null && target['last_seen'] != null) {
        final lastSeen = DateTime.parse(target['last_seen'].toString()).toLocal();
        if (DateTime.now().difference(lastSeen).inMinutes < 3) {
          isOnline = true;
        }
      }
    } catch (_) {}

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': otherId,
      'content': text,
      'image_url': cloudImageUrl ?? '',
      'is_deleted': false,
      'is_forwarded': isForwarded,
      'is_delivered': isOnline,
      'is_read': false,
      'reaction': '',
    });

    if (directReceiverId == null) {
      _fetchMessages();
    }
  }

  void _pickAndSendImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 65, maxWidth: 900);
    if (f == null) return;

    setState(() => _uploadingImage = true);
    final cloudUrl = await StorageService.uploadImage(file: File(f.path), folder: 'chats');
    setState(() => _uploadingImage = false);

    if (cloudUrl != null) {
      _sendMessage(cloudImageUrl: cloudUrl, customText: '📷 صورة');
    }
  }

  void _showMessageOptions(Map<String, dynamic> msg) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMe = msg['sender_id'] == myId;
    final bool isDeleted = msg['is_deleted'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDeleted)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _emojiReactionBtn('👍', msg),
                    _emojiReactionBtn('❤️', msg),
                    _emojiReactionBtn('😂', msg),
                    _emojiReactionBtn('😮', msg),
                    _emojiReactionBtn('😢', msg),
                    _emojiReactionBtn('😡', msg),
                    _emojiReactionBtn('🔥', msg),
                  ],
                ),
              ),

            const Divider(height: 1),

            if (!isDeleted)
              ListTile(
                leading: const Icon(Icons.reply, color: FBColors.primaryBlue),
                title: const Text('إعادة توجيه ↪️', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('إرسال هذه الرسالة إلى صديق آخر دون اسم المرسل'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openForwardDialog(msg);
                },
              ),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('حذف لدي فقط', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('إخفاء الرسالة من جهازك فقط'),
              onTap: () async {
                Navigator.pop(ctx);
                if (isMe) {
                  await supabase.from('messages').update({'deleted_by_sender': true}).eq('id', msg['id']);
                } else {
                  await supabase.from('messages').update({'deleted_by_receiver': true}).eq('id', msg['id']);
                }
                _fetchMessages();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الرسالة لديك بنجاح')));
              },
            ),

            if (isMe && !isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('حذف لدى الجميع 🚫', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                subtitle: const Text('حذف الرسالة من عند الطرفين نهائياً'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('messages').update({
                    'is_deleted': true,
                    'content': 'تم حذف هذه الرسالة 🚫',
                    'image_url': '',
                    'reaction': '',
                  }).eq('id', msg['id']);
                  _fetchMessages();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الرسالة لدى الجميع!')));
                },
              ),

            if (!isDeleted && (msg['content'] ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.grey),
                title: const Text('نسخ نص الرسالة'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg['content'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص!')));
                },
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _emojiReactionBtn(String emoji, Map<String, dynamic> msg) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        final currentReaction = msg['reaction'] ?? '';
        final newReaction = (currentReaction == emoji) ? '' : emoji;
        await supabase.from('messages').update({'reaction': newReaction}).eq('id', msg['id']);
        _fetchMessages();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  Future<void> _openForwardDialog(Map<String, dynamic> msg) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    final f1 = await supabase.from('friendships').select('receiver_id').eq('sender_id', myId).eq('status', 'accepted');
    final f2 = await supabase.from('friendships').select('sender_id').eq('receiver_id', myId).eq('status', 'accepted');
    final friendIds = <String>{};
    for (var f in f1) { friendIds.add(f['receiver_id'].toString()); }
    for (var f in f2) { friendIds.add(f['sender_id'].toString()); }

    if (friendIds.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ليس لديك أصدقاء بعد لإعادة التوجيه لهم!')));
      return;
    }

    final friendsProfiles = await supabase.from('profiles').select().filter('id', 'in', friendIds.toList());

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('إعادة توجيه الرسالة إلى... ↪️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: friendsProfiles.length,
                itemBuilder: (c, i) {
                  final friend = friendsProfiles[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: getUniversalImageProvider(friend['avatar_url']),
                      child: (friend['avatar_url'] == null || friend['avatar_url'] == '') ? Text(getFirstChar(friend['name'])) : null,
                    ),
                    title: Text(friend['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                      child: const Text('إرسال', style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _sendMessage(
                          customText: msg['content'],
                          cloudImageUrl: msg['image_url'],
                          isForwarded: true,
                          directReceiverId: friend['id'],
                        );
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: 
