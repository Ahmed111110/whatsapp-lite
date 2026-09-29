import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'profile_screen.dart';

final supabase = Supabase.instance.client;

class ChatDetailsScreen extends StatefulWidget {
  final dynamic targetUser;
  final String currentTheme;
  final String currentEmoji;
  final Function(String colorHex, String emoji) onSettingsChanged;

  const ChatDetailsScreen({
    super.key,
    required this.targetUser,
    required this.currentTheme,
    required this.currentEmoji,
    required this.onSettingsChanged,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  late String _theme;
  late String _emoji;
  List<Map<String, dynamic>> _sharedMedia = [];
  bool _loadingMedia = true;

  String get _tId => widget.targetUser['id']?.toString() ?? '';
  String get _tName => widget.targetUser['name']?.toString() ?? 'مستخدم أثير';
  String get _tAvatar => widget.targetUser['avatar_url']?.toString() ?? '';

  final List<Map<String, dynamic>> _themesList = [
    {'name': 'فيسبوك الكلاسيكي', 'color': '0xFF0084FF', 'c': const Color(0xFF0084FF)},
    {'name': 'تدرج بنفسجي ووردي', 'color': '0xFF833AB4', 'c': const Color(0xFF833AB4)},
    {'name': 'غروب الشمس (برتقالي)', 'color': '0xFFFF5722', 'c': const Color(0xFFFF5722)},
    {'name': 'زمردي أنيق', 'color': '0xFF00897B', 'c': const Color(0xFF00897B)},
    {'name': 'الوضع المظلم الملكي', 'color': '0xFF2C3E50', 'c': const Color(0xFF2C3E50)},
  ];

  final List<String> _quickEmojis = ['👍', '❤️', '🔥', '😂', '🎉', '👏', '😍', '🚀', '💯'];

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _emoji = widget.currentEmoji;
    _loadSharedMedia();
  }

  Future<void> _syncToCloud(String newTheme, String newEmoji) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;

    try {
      final existing = await supabase
          .from('conversation_settings')
          .select('id')
          .or('and(user1_id.eq.$myId,user2_id.eq.$_tId),and(user1_id.eq.$_tId,user2_id.eq.$myId)')
          .maybeSingle();

      if (existing != null) {
        await supabase.from('conversation_settings').update({
          'theme_color': newTheme,
          'quick_emoji': newEmoji,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        await supabase.from('conversation_settings').insert({
          'user1_id': myId,
          'user2_id': _tId,
          'theme_color': newTheme,
          'quick_emoji': newEmoji,
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSharedMedia() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _tId.isEmpty) return;

    try {
      final res = await supabase
          .from('messages')
          .select('image_url, created_at')
          .neq('image_url', '')
          .or('and(sender_id.eq.$myId,receiver_id.eq.$_tId),and(sender_id.eq.$_tId,receiver_id.eq.$myId)')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _sharedMedia = List<Map<String, dynamic>>.from(res);
          _loadingMedia = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  void _openThemePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('اختر سمة المحادثة (اللون)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ..._themesList.map((t) => ListTile(
                  leading: CircleAvatar(backgroundColor: t['c'], radius: 14),
                  title: Text(t['name']),
                  trailing: _theme == t['color'] ? const Icon(Icons.check, color: Colors.blue) : null,
                  onTap: () async {
                    final sel = t['color'].toString();
                    setState(() => _theme = sel);
                    widget.onSettingsChanged(_theme, _emoji);
                    Navigator.pop(ctx);
                    await _syncToCloud(_theme, _emoji);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر الإيموجي السريع للمحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _quickEmojis.map((e) {
                  return InkWell(
                    onTap: () async {
                      setState(() => _emoji = e);
                      widget.onSettingsChanged(_theme, _emoji);
                      Navigator.pop(ctx);
                      await _syncToCloud(_theme, _emoji);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _emoji == e ? Colors.blue.withOpacity(0.15) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 32)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundImage: getUniversalImageProvider(_tAvatar),
              child: (_tAvatar.isEmpty) ? Text(getFirstChar(_tName), style: const TextStyle(fontSize: 32)) : null,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(_tName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _topActionItem(Icons.person, 'الملف الشخصي', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: _tId)));
              }),
              _topActionItem(Icons.notifications_off, 'كتم الصوت', () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم كتم إشعارات هذه المحادثة')));
              }),
              _topActionItem(Icons.search, 'بحث', () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ميزة البحث داخل الشات')));
              }),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 0.5),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('التخصيص 🎨', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Color(int.parse(_theme)).withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(Icons.palette, color: Color(int.parse(_theme))),
            ),
            title: const Text('السمة ولون المحادثة'),
            trailing: CircleAvatar(radius: 12, backgroundColor: Color(int.parse(_theme))),
            onTap: _openThemePicker,
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.thumb_up, color: Colors.amber),
            ),
            title: const Text('الإيموجي السريع'),
            trailing: Text(_emoji, style: const TextStyle(fontSize: 22)),
            onTap: _openEmojiPicker,
          ),

          const Divider(thickness: 0.5),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الصور والوسائط المشتركة 🖼️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                Text('${_sharedMedia.length} صورة', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (_loadingMedia)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_sharedMedia.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text('لا توجد صور متبادلة في هذه المحادثة حتى الآن.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            )
          else
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sharedMedia.length,
                itemBuilder: (ctx, i) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: renderUniversalImage(_sharedMedia[i]['image_url'], fit: BoxFit.cover, width: 100, height: 100),
                    ),
                  );
                },
              ),
            ),

          const Divider(thickness: 0.5),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('الخصوصية والدعم 🔒', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: Text('حظر $_tName', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حظر $_tName بنجاح')));
            },
          ),
        ],
      ),
    );
  }

  Widget _topActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.withOpacity(0.15),
            child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
