import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';

final supabase = Supabase.instance.client;

class FeedScreen extends StatefulWidget {
  final Function(String userId)? onOpenProfile;
  final VoidCallback? onOpenChat;

  const FeedScreen({
    super.key,
    this.onOpenProfile,
    this.onOpenChat,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _stories = [];
  final Set<String> _hiddenPostIds = {};
  final Set<String> _savedPostIds = {};
  bool _loading = true;
  Map<String, dynamic>? _myProfile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFromCacheFirst();
    _loadAll();
  }

  // تحميل الكاش المحلي أوفلاين فوراً قبل أي اتصال
  Future<void> _loadFromCacheFirst() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPosts = prefs.getString('atheer_cached_posts');
    final cachedStories = prefs.getString('atheer_cached_stories');
    final cachedProfile = prefs.getString('atheer_cached_profile');

    if (cachedPosts != null && mounted) {
      setState(() {
        _posts = List<Map<String, dynamic>>.from(jsonDecode(cachedPosts));
        _loading = false;
      });
    }
    if (cachedStories != null && mounted) {
      setState(() => _stories = List<Map<String, dynamic>>.from(jsonDecode(cachedStories)));
    }
    if (cachedProfile != null && mounted) {
      setState(() => _myProfile = jsonDecode(cachedProfile));
    }
  }

  Future<void> _loadAll() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final p = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        if (p != null) {
          _myProfile = p;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('atheer_cached_profile', jsonEncode(p));
        }
      }
      final postsRes = await supabase.from('posts').select().order('created_at', ascending: false);
      final storiesRes = await supabase.from('stories').select().order('created_at', ascending: false);

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

  // رفع القصة سحابياً عبر StorageService
  void _addStory() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (file == null) return;

    final textCtrl = TextEditingController();
    bool uploading = false;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة إلى القصة 🌟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(file.path), height: 140, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              TextField(controller: textCtrl, decoration: const InputDecoration(hintText: 'اكتب نصاً لقصتك...')),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
              onPressed: uploading
                  ? null
                  : () async {
                      setD(() => uploading = true);
                      final user = supabase.auth.currentUser;
                      // رفع الصورة للسحابة والحصول على رابط مباشر
                      final cloudUrl = await StorageService.uploadImage(file: File(file.path), folder: 'stories');

                      await supabase.from('stories').insert({
                        'user_id': user?.id,
                        'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                        'avatar_url': _myProfile?['avatar_url'] ?? '',
                        'image_url': cloudUrl ?? '',
                        'text': textCtrl.text.trim(),
                      });
                      Navigator.pop(ctx);
                      _loadAll();
                    },
              child: uploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('مشاركة في القصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewStory(Map<String, dynamic> story) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StoryViewerDialog(story: story),
    );
  }

  // نظام الإعجاب الفردي الصحيح
  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    }

    List likedUsers = (reactions['liked_users'] is List) ? List.from(reactions['liked_users']) : [];
    int currentCount = post['likes_count'] ?? 0;

    final bool alreadyLiked = likedUsers.contains(myId);

    if (alreadyLiked) {
      likedUsers.remove(myId);
      currentCount = (currentCount > 0) ? currentCount - 1 : 0;
    } else {
      likedUsers.add(myId);
      currentCount = currentCount + 1;
    }

    reactions['liked_users'] = likedUsers;

    setState(() {
      post['likes_count'] = currentCount;
      post['reactions'] = reactions;
    });

    try {
      await supabase.from('posts').update({
        'likes_count': currentCount,
        'reactions': reactions,
      }).eq('id', post['id']);
    } catch (_) {}
  }

  Future<void> _handleReaction(Map<String, dynamic> post, String reactionType) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    Map<String, dynamic> reactions = {};
    if (post['reactions'] is Map) {
      reactions = Map<String, dynamic>.from(post['reactions']);
    }

    List likedUsers = (reactions['liked_users'] is List) ? List.from(reactions['liked_users']) : [];
    int totalLikes = post['likes_count'] ?? 0;

    if (!likedUsers.contains(myId)) {
      likedUsers.add(myId);
      totalLikes += 1;
    }

    reactions['liked_users'] = likedUsers;
    reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;

    setState(() {
      post['likes_count'] = totalLikes;
      post['reactions'] = reactions;
    });

    try {
      await supabase.from('posts').update({
        'likes_count': totalLikes,
        'reactions': reactions,
      }).eq('id', post['id']);
    } catch (_) {}
  }

  // معاينة المنشور بالضغط المطول
  void _showPostPreviewModal(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FBColors.primaryBlue.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: getUniversalImageProvider(post['author_avatar']),
                        child: (post['author_avatar'] == null || post['author_avatar'] == '') ? Text(getFirstChar(post['author_name'])) : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${formatArabicTime(post['created_at'])} • ${post['visibility'] == 'friends' ? 'للأصدقاء 👥' : 'عام 🌐'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if ((post['text'] ?? '').isNotEmpty)
                    Text(post['text'] ?? '', style: const TextStyle(fontSize: 16, height: 1.45)),
                  if ((post['image_url'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: renderUniversalImage(post['image_url'], height: 220, width: double.infinity, borderRadius: BorderRadius.circular(12)),
                    ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue.withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.copy_rounded, color: FBColors.primaryBlue, size: 18),
                          label: const Text('نسخ المنشور', style: TextStyle(color: FBColors.primaryBlue, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: post['text'] ?? ''));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور بنجاح!')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.withOpacity(0.15), elevation: 0),
                          icon: const Icon(Icons.share, color: Colors.grey, size: 18),
                          label: const Text('مشاركة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر أثير 🌌'));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تجهيز الرابط للمشاركة!')));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFBReactionsSummary(Map<String, dynamic> post) {
    final int count = post['likes_count'] ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.thumb_up, color: Colors.white, size: 11),
              ),
              Positioned(
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFFA3E3E), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Text('$count', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Text('تعليقات ومشاركات', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? FBColors.darkSubText : FBColors.lightSubText)),
        ],
      ),
    );
  }

  void _showReactionsOverlay(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            bottom: 120,
            right: 40,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF242526), borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
                child: Row(
                  children: [
                    _reactionItem('👍', 'like', post, ctx),
                    _reactionItem('❤️', 'love', post, ctx),
                    _reactionItem('😨', 'scare', post, ctx),
                    _reactionItem('😡', 'angry', post, ctx),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reactionItem(String emoji, String type, Map<String, dynamic> post, BuildContext ctx) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _handleReaction(post, type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  void _showPostMenu(Map<String, dynamic> post) {
    final myId = supabase.auth.currentUser?.id;
    final String? postUserId = post['user_id']?.toString();
    final bool isOwner = (myId != null && postUserId != null && myId == postUserId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(4)),
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: FBColors.primaryBlue),
                title: const Text('تعديل المنشور', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  final editCtrl = TextEditingController(text: post['text']);
                  showDialog(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('تعديل المنشور ✏️'),
                      content: TextField(controller: editCtrl, maxLines: 3),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                          onPressed: () async {
                            await supabase.from('posts').update({'text': editCtrl.text.trim()}).eq('id', post['id']);
                            Navigator.pop(d);
                            _loadAll();
                          },
                          child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Color(0xFF31A24C)),
                title: Text(post['visibility'] == 'friends' ? 'تغيير الجمهور إلى: عام 🌐' : 'تغيير الجمهور إلى: للأصدقاء فقط 👥', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final nextVis = post['visibility'] == 'friends' ? 'public' : 'friends';
                  await supabase.from('posts').update({'visibility': nextVis}).eq('id', post['id']);
                  _loadAll();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('حذف المنشور نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await supabase.from('posts').delete().eq('id', post['id']);
                  _loadAll();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded, color: FBColors.primaryBlue),
                title: Text(_savedPostIds.contains(post['id'].toString()) ? 'إلغاء حفظ المنشور' : 'حفظ المنشور 📌', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  final pid = post['id'].toString();
                  setState(() {
                    if (_savedPostIds.contains(pid)) {
                      _savedPostIds.remove(pid);
                    } else {
                      _savedPostIds.add(pid);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ المنشور في محفوظاتك! 📌')));
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined, color: Colors.amber),
                title: const Text('إخفاء المنشور 👁️', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _hiddenPostIds.add(post['id'].toString()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.grey),
                title: const Text('نسخ نص المنشور'),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: post['text'] ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص بنجاح!')));
                },
              ),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visiblePosts = _posts.where((p) => !_hiddenPostIds.contains(p['id'].toString())).toList();
    final dividerBg = isDark ? FBColors.darkBg : FBColors.lightBg;
    final myId = supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('أَثِـيـر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: FBColors.primaryBlue)),
        actions: [
          _fbCircleIcon(Icons.search, () {}),
          const SizedBox(width: 8),
          _fbCircleIcon(Icons.chat_bubble_rounded, () {
            if (widget.onOpenChat != null) widget.onOpenChat!();
          }),
          const SizedBox(width: 12),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.only(top: 12, left: 14, right: 14, bottom: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (_myProfile != null && widget.onOpenProfile != null) {
                                  widget.onOpenProfile!(_myProfile!['id']);
                                }
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url']),
                                child: (_myProfile?['avatar_url'] == null || _myProfile?['avatar_url'] == '') ? Text(getFirstChar(_myProfile?['name'])) : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _showCreatePostModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? FBColors.darkInput : FBColors.lightInput,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Text('بِمَ تفكّر؟', style: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 14.5)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _fbQuickAction(Icons.videocam, Colors.red, 'بث مباشر', () {}),
                            Container(width: 1, height: 18, color: Colors.grey.withOpacity(0.3)),
                            _fbQuickAction(Icons.photo_library, const Color(0xFF45BD62), 'صورة', _showCreatePostModal),
                            Container(width: 1, height: 18, color: Colors.grey.withOpacity(0.3)),
                            _fbQuickAction(Icons.emoji_emotions, const Color(0xFFF7B125), 'شعور/نشاط', () {}),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(height: 8, color: dividerBg),

                  Container(
                    color: Theme.of(context).cardColor,
                    height: 195,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        const SizedBox(width: 10),
                        _buildCreateStoryCard(isDark),
                        ..._stories.map((st) => _buildStoryCard(st, isDark)),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),

                  Container(height: 8, color: dividerBg),

                  ...visiblePosts.map((post) {
                    final bool isFounder = post['is_founder'] == true;
                    final Map reactions = (post['reactions'] is Map) ? post['reactions'] : {};
                    final List likedUsers = (reactions['liked_users'] is List) ? reactions['liked_users'] : [];
                    final bool isLikedByMe = (myId != null && likedUsers.contains(myId));

                    return GestureDetector(
                      onLongPress: () => _showPostPreviewModal(post),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 6),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.onOpenProfile != null) {
                                        widget.onOpenProfile!(post['user_id'] ?? '');
                                      }
                                    },
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundImage: getUniversalImageProvider(post['author_avatar']),
                                      child: (post['author_avatar'] == null || post['author_avatar'] == '') ? Text(getFirstChar(post['author_name'])) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (widget.onOpenProfile != null) {
                                              widget.onOpenProfile!(post['user_id'] ?? '');
                                            }
                                          },
                                          child: Row(
                                            children: [
                                              Text(post['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              if (isFounder) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: FBColors.primaryBlue, size: 16),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(formatArabicTime(post['created_at']), style: TextStyle(fontSize: 12, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                                            Icon(post['visibility'] == 'friends' ? Icons.group : Icons.public, size: 13, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                    onPressed: () => _showPostMenu(post),
                                  ),
                                ],
                              ),
                            ),

                            if ((post['text'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                child: Text(post['text'] ?? '', style: const TextStyle(fontSize: 15, height: 1.35)),
                              ),

                            if ((post['image_url'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: renderUniversalImage(post['image_url'], width: double.infinity, fit: BoxFit.cover),
                              ),

                            _buildFBReactionsSummary(post),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Divider(height: 1),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onLongPress: () => _showReactionsOverlay(post),
                                      onTap: () => _toggleLike(post),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isLikedByMe ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                                              size: 18,
                                              color: isLikedByMe ? FBColors.primaryBlue : (isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'أعجبني',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isLikedByMe ? FBColors.primaryBlue : (isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _openComments(post['id']),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.chat_bubble_outline, size: 18, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            const SizedBox(width: 6),
                                            Text('تعليق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: '${post['author_name']}:\n${post['text']}\n\nنشر عبر تطبيق أثير 🌌'));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ نص المنشور لمشاركته!')));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.share_outlined, size: 18, color: isDark ? FBColors.darkSubText : FBColors.lightSubText),
                                            const SizedBox(width: 6),
                                            Text('مشاركة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }

  Widget _fbCircleIcon(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _fbQuickAction(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard(bool isDark) {
    return Container(
      width: 105,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: _addStory,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 115,
                width: double.infinity,
                child: renderUniversalImage(_myProfile?['avatar_url'], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              bottom: 42,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
            const Positioned(
              bottom: 10,
              child: Text('إنشاء قصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> st, bool isDark) {
    return GestureDetector(
      onTap: () => _viewStory(st),
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF242526),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: renderUniversalImage(st['image_url'], fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: FBColors.primaryBlue, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: getUniversalImageProvider(st['avatar_url']),
                    child: (st['avatar_url'] == null || st['avatar_url'] == '') ? Text(getFirstChar(st['author_name']), style: const TextStyle(fontSize: 10)) : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  st['author_name'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نشر المنشور مع رفع الصورة سحابياً لـ Supabase Storage
  void _showCreatePostModal() {
    final textCtrl = TextEditingController();
    File? selectedImage;
    String vis = 'public';
    bool publishing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setM) => Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 20, backgroundImage: getUniversalImageProvider(_myProfile?['avatar_url'])),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_myProfile?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: vis,
                          underline: const SizedBox(),
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'public', child: Text('عام 🌐', style: TextStyle(fontSize: 11))),
                            DropdownMenuItem(value: 'friends', child: Text('الأصدقاء 👥', style: TextStyle(fontSize: 11))),
                          ],
                          onChanged: (v) {
                            if (v != null) setM(() => vis = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'بِمَ تفكّر؟', border: InputBorder.none)),
              if (selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(selectedImage!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Color(0xFF45BD62)),
                    onPressed: () async {
                      final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);
                      if (f != null) {
                        setM(() => selectedImage = File(f.path));
                      }
                    },
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: publishing
                        ? null
                        : () async {
                            if (textCtrl.text.trim().isNotEmpty || selectedImage != null) {
                              setM(() => publishing = true);
                              final user = supabase.auth.currentUser;
                              String? cloudImageUrl;

                              // رفع الصورة لسحابة Supabase إذا تم اختيارها
                              if (selectedImage != null) {
                                cloudImageUrl = await StorageService.uploadImage(file: selectedImage!, folder: 'posts');
                              }

                              await supabase.from('posts').insert({
                                'user_id': user?.id,
                                'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                                'author_avatar': _myProfile?['avatar_url'] ?? '',
                                'is_founder': _myProfile?['is_founder'] ?? false,
                                'text': textCtrl.text.trim(),
                                'image_url': cloudImageUrl ?? '',
                                'visibility': vis,
                                'likes_count': 0,
                                'reactions': {'like': 0, 'love': 0, 'scare': 0, 'angry': 0, 'liked_users': []},
                              });
                              Navigator.pop(ctx);
                              _loadAll();
                            }
                          },
                    child: publishing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('نشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openComments(dynamic postId) {
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setC) => Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
          child: Column(
            children: [
              const Text('التعليقات 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: FutureBuilder(
                  future: supabase.from('comments').select().eq('post_id', postId.toString()).order('created_at', ascending: true),
                  builder: (cx, AsyncSnapshot snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final list = snap.data as List;
                    if (list.isEmpty) return const Center(child: Text('كن أول من يعلّق على هذا المنشور!'));
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (cx, i) => ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage: getUniversalImageProvider(list[i]['author_avatar']),
                          child: (list[i]['author_avatar'] == null || list[i]['author_avatar'] == '') ? Text(getFirstChar(list[i]['author_name'])) : null,
                        ),
                        title: Text(list[i]['author_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(list[i]['content'] ?? ''),
                        trailing: Text(formatArabicTime(list[i]['created_at']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentCtrl,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً...',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? FBColors.darkInput : FBColors.lightInput,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: FBColors.primaryBlue),
                    onPressed: () async {
                      if (commentCtrl.text.trim().isNotEmpty) {
                        final u = supabase.auth.currentUser;
                        await supabase.from('comments').insert({
                          'post_id': postId.toString(),
                          'user_id': u?.id,
                          'author_name': _myProfile?['name'] ?? 'مستخدم أثير',
                          'author_avatar': _myProfile?['avatar_url'] ?? '',
                          'content': commentCtrl.text.trim(),
                        });
                        commentCtrl.clear();
                        setC(() {});
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// عارض الستوري السينمائي
class StoryViewerDialog extends StatefulWidget {
  final Map<String, dynamic> story;
  const StoryViewerDialog({super.key, required this.story});

  @override
  State<StoryViewerDialog> createState() => _StoryViewerDialogState();
}

class _StoryViewerDialogState extends State<StoryViewerDialog> {
  final TextEditingController _replyCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _sendStoryReaction(String emoji) async {
    final myId = supabase.auth.currentUser?.id;
    final targetId = widget.story['user_id'];
    if (myId == null || targetId == null) return;

    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': targetId,
      'content': '$emoji تفاعل مع قصتك',
      'image_url': widget.story['image_url'] ?? '',
      'is_deleted': false,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال تفاعل $emoji في الماسنجر! 💬')));
    }
  }

  Future<void> _sendStoryReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    final myId = supabase.auth.currentUser?.id;
    final targetId = widget.story['user_id'];
    if (myId == null || targetId == null) return;

    setState(() => _sending = true);
    await supabase.from('messages').insert({
      'sender_id': myId,
      'receiver_id': targetId,
      'content': 'رد على القصة: $text',
      'image_url': widget.story['image_url'] ?? '',
      'is_deleted': false,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ردك في رسائل الماسنجر! ✉️')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.story;

    return Dialog(
      backgroundColor: const Color(0xFF18191A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: getUniversalImageProvider(story['avatar_url']),
                    child: (story['avatar_url'] == null || story['avatar_url'] == '') ? Text(getFirstChar(story['author_name'])) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(story['author_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(formatArabicTime(story['created_at']), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if ((story['image_url'] ?? '').isNotEmpty) renderUniversalImage(story['image_url'], width: double.infinity, fit: BoxFit.contain),
                    if ((story['text'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(story['text'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _storyReactionBtn('❤️'),
                  _storyReactionBtn('🔥'),
                  _storyReactionBtn('😂'),
                  _storyReactionBtn('👏'),
                  _storyReactionBtn('😮'),
                  _storyReactionBtn('😢'),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 12, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: const Color(0xFF3A3B3C), borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _replyCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'إرسال رسالة إلى صاحب القصة...',
                          hintStyle: TextStyle(color: Colors.white54, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: FBColors.primaryBlue)) : const Icon(Icons.send_rounded, color: FBColors.primaryBlue),
                    onPressed: _sending ? null : _sendStoryReply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyReactionBtn(String emoji) {
    return InkWell(
      onTap: () => _sendStoryReaction(emoji),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}
