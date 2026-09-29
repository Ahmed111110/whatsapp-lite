import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initialProfile;

  const ProfileScreen({super.key, this.userId, this.initialProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _userPosts = [];
  bool _loading = true;
  String _friendshipStatus = 'none';
  final ImagePicker _picker = ImagePicker();

  String get _effectiveUserId => widget.userId ?? supabase.auth.currentUser?.id ?? '';
  bool get _isMe => _effectiveUserId == (supabase.auth.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _loading = false;
    }
    _fetchProfile();
    _fetchUserPosts();
    if (!_isMe) _checkFriendship();
  }

  Future<void> _fetchProfile() async {
    if (_effectiveUserId.isEmpty) return;
    try {
      final res = await supabase.from('profiles').select().eq('id', _effectiveUserId).maybeSingle();
      if (res != null && mounted) {
        setState(() {
          _profile = res;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchUserPosts() async {
    if (_effectiveUserId.isEmpty) return;
    try {
      final res = await supabase
          .from('posts')
          .select()
          .eq('user_id', _effectiveUserId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _userPosts = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (_) {}
  }

  Future<void> _checkFriendship() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null || _effectiveUserId.isEmpty) return;
    try {
      final res = await supabase
          .from('friendships')
          .select()
          .or('and(sender_id.eq.$myId,receiver_id.eq.$_effectiveUserId),and(sender_id.eq.$_effectiveUserId,receiver_id.eq.$myId)')
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (res == null) {
            _friendshipStatus = 'none';
          } else if (res['status'] == 'accepted') {
            _friendshipStatus = 'friends';
          } else if (res['sender_id'] == myId) {
            _friendshipStatus = 'sent';
          } else {
            _friendshipStatus = 'received';
          }
        });
      }
    } catch (_) {}
  }

  void _openAvatarConfirmationDialog(File imageFile) {
    final captionCtrl = TextEditingController();
    bool isFitCover = true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Text('معاينة وتأكيد الصورة 👑', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FBColors.royalGold,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setM(() => isSaving = true);
                              final url = await StorageService.uploadImage(file: imageFile, folder: 'avatars');
                              if (url != null) {
                                await supabase.from('profiles').update({'avatar_url': url}).eq('id', _effectiveUserId);

                                if (captionCtrl.text.trim().isNotEmpty) {
                                  await supabase.from('posts').insert({
                                    'user_id': _effectiveUserId,
                                    'text': captionCtrl.text.trim(),
                                    'image_url': url,
                                    'likes': [],
                                  });
                                }

                                Navigator.pop(ctx);
                                _fetchProfile();
                                _fetchUserPosts();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح! 🎉')),
                                );
                              }
                              setM(() => isSaving = false);
                            },
                      child: isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('حفظ وتأكيد', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 14),

                Center(
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: FBColors.royalGold, width: 3),
                      boxShadow: [
                        BoxShadow(color: FBColors.royalGold.withOpacity(0.3), blurRadius: 16, spreadRadius: 2),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.file(
                        imageFile,
                        width: 210,
                        height: 210,
                        fit: isFitCover ? BoxFit.cover : BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: FBColors.royalGold),
                  icon: Icon(isFitCover ? Icons.aspect_ratio : Icons.crop),
                  label: Text(isFitCover ? 'ضبط الأبعاد (ملاءمة كاملة)' : 'ملء الإطار الدائري (توسيع)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => setM(() => isFitCover = !isFitCover),
                ),

                const SizedBox(height: 10),
                TextField(
                  controller: captionCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'اكتب وصفاً أو تعليقاً على صورتك الشخصية...',
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final bioCtrl = TextEditingController(text: _profile?['bio'] ?? '');
    final locationCtrl = TextEditingController(text: _profile?['location'] ?? 'فلسطين، خان يونس');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('تعديل الملف الشخصي ✏️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text('الاسم الكامل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('النبذة التعريفية (Bio):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('مكان الإقامة / المدينة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FBColors.royalGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            setM(() => saving = true);
                            await supabase.from('profiles').update({
                              'name': nameCtrl.text.trim(),
                              'bio': bioCtrl.text.trim(),
                              'location': locationCtrl.text.trim(),
                            }).eq('id', _effectiveUserId);

                            Navigator.pop(ctx);
                            _fetchProfile();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح! ✨')));
                          },
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (f != null) {
      _openAvatarConfirmationDialog(File(f.path));
    }
  }

  Future<void> _pickCover() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري رفع صورة الغلاف... ⏳')));
    final url = await StorageService.uploadImage(file: File(f.path), folder: 'covers');
    if (url != null) {
      await supabase.from('profiles').update({'cover_url': url}).eq('id', _effectiveUserId);
      _fetchProfile();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث صورة الغلاف!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FBColors.royalGold)));
    }

    final p = _profile ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goldAccent = isDark ? FBColors.royalGold : FBColors.darkAntiqueGold;

    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] ?? 'الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold, color: goldAccent)),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 245,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 175,
                  child: Container(
                    color: isDark ? const Color(0xFF232328) : const Color(0xFFE5E2DA),
                    child: (p['cover_url'] != null && (p['cover_url'] as String).isNotEmpty)
                        ? renderUniversalImage(p['cover_url'], fit: BoxFit.cover, width: double.infinity, height: 175)
                        : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
                ),

                if (_isMe)
                  Positioned(
                    top: 125,
                    right: 14,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: _pickCover,
                      ),
                    ),
                  ),

                Positioned(
                  top: 105,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _isMe ? _pickAvatar : null,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: FBColors.goldGradient,
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundImage: getUniversalImageProvider(p['avatar_url']),
                                child: (p['avatar_url'] == null || p['avatar_url'] == '')
                                    ? Text(getFirstChar(p['name'] ?? 'أ'), style: const TextStyle(fontSize: 36, color: Colors.black, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          ),
                          if (_isMe)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: FBColors.royalGold,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Column(
              children: [
                Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                if ((p['bio'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(p['bio'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isMe
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FBColors.royalGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text('إضافة إلى القصة', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يمكنك إضافة قصة مباشرة من الشاشة الرئيسية 🌟')));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF26262B) : const Color(0xFFE8E5DD),
                            foregroundColor: isDark ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('تعديل الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _openEditProfileDialog,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _friendshipStatus == 'friends' ? Colors.grey.shade400 : FBColors.royalGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(_friendshipStatus == 'friends' ? Icons.check : Icons.person_add),
                          label: Text(_friendshipStatus == 'friends'
                              ? 'أصدقاء'
                              : (_friendshipStatus == 'sent' ? 'تم إرسال الطلب' : 'إضافة صديق'),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final myId = supabase.auth.currentUser?.id;
                            if (myId == null) return;
                            if (_friendshipStatus == 'none') {
                              await supabase.from('friendships').insert({
                                'sender_id': myId,
                                'receiver_id': _effectiveUserId,
                                'status': 'pending',
                              });
                              setState(() => _friendshipStatus = 'sent');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF26262B) : const Color(0xFFE8E5DD),
                            foregroundColor: isDark ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('مراسلة', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: p))),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FBColors.royalGold.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('التفاصيل 📌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: FBColors.royalGold, size: 18),
                    const SizedBox(width: 8),
                    Text('يقيم في ${p['location'] ?? 'فلسطين، خان يونس'}', style: const TextStyle(fontSize: 13.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: FBColors.royalGold, size: 18),
                    const SizedBox(width: 8),
                    Text('انضم إلى منصة أثير ${formatArabicTime(p['created_at'])}', style: const TextStyle(fontSize: 13.5)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(thickness: 0.5, height: 26),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المنشورات (${_userPosts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_isMe)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: FBColors.royalGold),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('تعديل'),
                    onPressed: _openEditProfileDialog,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          if (_userPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('لا توجد منشورات لهذا المستخدم بعد')),
            )
          else
            ..._userPosts.map((post) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: getUniversalImageProvider(p['avatar_url']),
                          child: (p['avatar_url'] == null || p['avatar_url'] == '') ? Text(getFirstChar(p['name'])) : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text(formatArabicTime(post['created_at']), style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((post['text'] ?? '').isNotEmpty)
                      Text(post['text'] ?? '', style: const TextStyle(fontSize: 14)),
                    if ((post['image_url'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: renderUniversalImage(post['image_url'], width: double.infinity, fit: BoxFit.cover, borderRadius: BorderRadius.circular(8)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
