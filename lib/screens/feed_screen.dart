import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

final supabase = Supabase.instance.client;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  Map<String, dynamic>? _myProfile;
  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCache();
    _loadData();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPosts = prefs.getString('atheer_cached_posts');
    final cachedStories = prefs.getString('atheer_cached_stories');
    final cachedProfile = prefs.getString('atheer_cached_profile');

    if (mounted) {
      setState(() {
        if (cachedPosts != null) {
          _posts = List<Map<String, dynamic>>.from(jsonDecode(cachedPosts));
        }
        if (cachedStories != null) {
          _stories = List<Map<String, dynamic>>.from(jsonDecode(cachedStories));
        }
        if (cachedProfile != null) {
          _myProfile = jsonDecode(cachedProfile);
        }
        if (_posts.isNotEmpty) _loading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final myId = supabase.auth.currentUser?.id;
    try {
      if (myId != null) {
        final p = await supabase.from('profiles').select().eq('id', myId).maybeSingle();
        if (p != null) {
          _myProfile = p;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('atheer_cached_profile', jsonEncode(p));
        }
      }

      final postsRes = await supabase.from('posts').select('*, profiles(name, avatar_url)').order('created_at', ascending: false).limit(30);
      final storiesRes = await supabase.from('stories').select('*, profiles(name, avatar_url)').order('created_at', ascending: false).limit(20);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('atheer_cached_posts', jsonEncode(postsRes));
      await prefs.setString('atheer_cached_stories', jsonEncode(storiesRes));

      if (mounted) {
        setState(() {
          _posts = List<Map<String, dynamic>>.from(postsRes);
          _stories = List<Map<String, dynamic>>.from(storiesRes);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    final postId = post['id'];
    List likes = List.from(post['likes'] ?? []);
    bool isLiked = likes.contains(myId);

    if (isLiked) {
      likes.remove(myId);
    } else {
      likes.add(myId);
    }

    setState(() {
      post['likes'] = likes;
    });

    try {
      await supabase.from('posts').update({'likes': likes}).eq('id', postId);
    } catch (_) {}
  }

  void _openCreatePostDialog() {
    final textCtrl = TextEditingController();
    String? selectedImgPath;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setM) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url']),
                      child: (_myProfile?['avatar_url'] == null || _myProfile?['avatar_url'] == '')
                          ? Text(getFirstChar(_myProfile?['name'] ?? 'أ'))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(_myProfile?['name'] ?? 'مستخدم أثير', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'بماذا تفكر؟ ✍️',
                    border: InputBorder.none,
                  ),
                ),
                if (selectedImgPath != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(selectedImgPath!), height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setM(() => selectedImgPath = null),
                      ),
                    ],
                  ),
                const Divider(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.green),
                      onPressed: () async {
                        final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1000);
                        if (f != null) setM(() => selectedImgPath = f.path);
                      },
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                      onPressed: uploading
                          ? null
                          : () async {
                              final text = textCtrl.text.trim();
                              if (text.isEmpty && selectedImgPath == null) return;
                              setM(() => uploading = true);
                              String? imgUrl;
                              if (selectedImgPath != null) {
                                imgUrl = await StorageService.uploadImage(file: File(selectedImgPath!), folder: 'posts');
                              }
                              final myId = supabase.auth.currentUser?.id;
                              if (myId != null) {
                                await supabase.from('posts').insert({
                                  'user_id': myId,
                                  'text': text,
                                  'image_url': imgUrl ?? '',
                                  'likes': [],
                                });
                              }
                              Navigator.pop(ctx);
                              _loadData();
                            },
                      child: uploading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('نشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addStory() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1000);
    if (f == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري رفع القصة... ⏳')));
    final url = await StorageService.uploadImage(file: File(f.path), folder: 'stories');
    final myId = supabase.auth.currentUser?.id;
    if (url != null && myId != null) {
      await supabase.from('stories').insert({
        'user_id': myId,
        'media_url': url,
      });
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة القصة بنجاح! 🎉')));
    }
  }

  void _openStoryView(Map<String, dynamic> story) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMyStory = story['user_id'] == myId;
    final replyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: renderUniversalImage(story['media_url'], fit: BoxFit.contain, width: double.infinity),
            ),
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: getUniversalImageProvider(story['profiles']?['avatar_url'])),
                  const SizedBox(width: 8),
                  Text(story['profiles']?['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (isMyStory)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await supabase.from('stories').delete().eq('id', story['id']);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف قصتك بنجاح')));
                      },
                    ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: isMyStory
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('قصتك معروضة لجميع الأصدقاء 👁️', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'إرسال رد في رسالة...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white24,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            final text = replyCtrl.text.trim();
                            if (text.isEmpty || myId == null) return;
                            Navigator.pop(ctx);
                            await supabase.from('messages').insert({
                              'sender_id': myId,
                              'receiver_id': story['user_id'],
                              'content': 'رد على قصتك: $text',
                              'created_at': DateTime.now().toIso8601String(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرد في المحادثة! 💬')));
                          },
                        ),
                        IconButton(
                          icon: const Text('❤️', style: TextStyle(fontSize: 24)),
                          onPressed: () async {
                            if (myId == null) return;
                            Navigator.pop(ctx);
                            await supabase.from('messages').insert({
                              'sender_id': myId,
                              'receiver_id': story['user_id'],
                              'content': 'تفاعل مع قصتك ❤️',
                              'created_at': DateTime.now().toIso8601String(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التفاعل بنجاح!')));
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    final myId = supabase.auth.currentUser?.id;
    final bool isMe = post['user_id'] == myId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('حذف المنشور 🗑️', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('posts').delete().eq('id', post['id']);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور بنجاح')));
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('إبلاغ عن المنشور'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام بلاغك')));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openCommentsModal(Map<String, dynamic> post) {
    final commentCtrl = TextEditingController();
    final postId = post['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setM) => Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                const Text('التعليقات 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                Expanded(
                  child: FutureBuilder(
                    future: supabase.from('comments').select('*, profiles(name, avatar_url)').eq('post_id', postId).order('created_at', ascending: true),
                    builder: (ctx, AsyncSnapshot snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue));
                      final comments = List<Map<String, dynamic>>.from(snap.data);
                      if (comments.isEmpty) return const Center(child: Text('كن أول من يعلق!', style: TextStyle(color: Colors.grey)));
                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (cx, idx) {
                          final item = comments[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: getUniversalImageProvider(item['profiles']?['avatar_url']),
                            ),
                            title: Text(item['profiles']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(item['content'] ?? '', style: const TextStyle(fontSize: 13.5)),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          decoration: const InputDecoration(
                            hintText: 'اكتب تعليقاً...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: FBColors.primaryBlue),
                        onPressed: () async {
                          final text = commentCtrl.text.trim();
                          final myId = supabase.auth.currentUser?.id;
                          if (text.isEmpty || myId == null) return;
                          await supabase.from('comments').insert({
                            'post_id': postId,
                            'user_id': myId,
                            'content': text,
                          });
                          commentCtrl.clear();
                          setM(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myId = supabase.auth.currentUser?.id;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (myId != null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: myId)));
                            }
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url']),
                            child: (_myProfile?['avatar_url'] == null || _myProfile?['avatar_url'] == '')
                                ? Text(getFirstChar(_myProfile?['name'] ?? 'أ'))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openCreatePostDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? FBColors.darkInput : FBColors.lightInput,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text('بماذا تفكر يا ${_myProfile?['name'] ?? ''}؟', style: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 13.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.photo_library, color: Color(0xFF45BD62)),
                          onPressed: _openCreatePostDialog,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Theme.of(context).cardColor,
                    height: 190,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        GestureDetector(
                          onTap: _addStory,
                          child: Container(
                            width: 105,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: renderUniversalImage(_myProfile?['avatar_url'], width: double.infinity, fit: BoxFit.cover),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Positioned(
                                        top: -16,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                                          child: const CircleAvatar(
                                            radius: 14,
                                            backgroundColor: FBColors.primaryBlue,
                                            child: Icon(Icons.add, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                      const Positioned(
                                        bottom: 8,
                                        child: Text('إنشاء قصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ..._stories.map((st) {
                          final u = st['profiles'];
                          return GestureDetector(
                            onTap: () => _openStoryView(st),
                            child: Container(
                              width: 105,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: getUniversalImageProvider(st['media_url']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.black38, Colors.transparent, Colors.black87],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: FBColors.primaryBlue, width: 2),
                                      ),
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundImage: getUniversalImageProvider(u?['avatar_url']),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    left: 8,
                                    child: Text(
                                      u?['name'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (_posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('لا توجد منشورات حالياً، كن أول من ينشر!')),
                    )
                  else
                    ..._posts.map((post) {
                      final author = post['profiles'];
                      final likes = List.from(post['likes'] ?? []);
                      final bool hasLiked = myId != null && likes.contains(myId);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: GestureDetector(
                                onTap: () {
                                  if (post['user_id'] != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: post['user_id'])));
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: getUniversalImageProvider(author?['avatar_url']),
                                  child: (author?['avatar_url'] == null || author?['avatar_url'] == '') ? Text(getFirstChar(author?['name'] ?? 'أ')) : null,
                                ),
                              ),
                              title: Text(author?['name'] ?? 'مستخدم أثير', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                              subtitle: Text(formatArabicTime(post['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_horiz),
                                onPressed: () => _showPostOptions(post),
                              ),
                            ),

                            if ((post['text'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 14.5, height: 1.35)),
                              ),

                            if ((post['image_url'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: renderUniversalImage(post['image_url'], width: double.infinity, fit: BoxFit.cover),
                              ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  if (likes.isNotEmpty) ...[
                                    const Icon(Icons.thumb_up, color: FBColors.primaryBlue, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${likes.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _openCommentsModal(post),
                                    child: const Text('تعليقات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1),

                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    icon: Icon(
                                      hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                      color: hasLiked ? FBColors.primaryBlue : Colors.grey,
                                      size: 19,
                                    ),
                                    label: Text('أعجبني', style: TextStyle(color: hasLiked ? FBColors.primaryBlue : (isDark ? Colors.white70 : Colors.black87), fontSize: 13)),
                                    onPressed: () => _toggleLike(post),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 19),
                                    label: Text('تعليق', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                                    onPressed: () => _openCommentsModal(post),
                                  ),
                                ),
                                Expanded(
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.share_outlined, color: Colors.grey, size: 19),
                                    label: Text('مشاركة', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
