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
          .select('*, profiles(name, avatar_url)')
          .eq('user_id', _effectiveUserId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _userPosts = List<Map<String, dynamic>>.from(res));
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    const Text('معاينة الصورة الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton(
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
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FBColors.primaryBlue)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: FBColors.primaryBlue, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.file(
                            imageFile,
                            width: 220,
                            height: 220,
                            fit: isFitCover ? BoxFit.cover : BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  icon: Icon(isFitCover ? Icons.aspect_ratio : Icons.crop),
                  label: Text(isFitCover ? 'ضبط الأبعاد (ملاءمة كاملة)' : 'ملء الإطار الدائري'),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FBColors.primaryBlue)));
    }

    final p = _profile ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] ?? 'الملف الشخصي', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 180,
                width: double.infinity,
                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFCCD0D5),
                child: (p['cover_url'] != null && (p['cover_url'] as String).isNotEmpty)
                    ? renderUniversalImage(p['cover_url'], fit: BoxFit.cover, width: double.infinity, height: 180)
                    : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
              ),
              if (_isMe)
                Positioned(
                  bottom: 10,
                  right: 10,
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
                bottom: -50,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: getUniversalImageProvider(p['avatar_url']),
                        child: (p['avatar_url'] == null || p['avatar_url'] == '')
                            ? Text(getFirstChar(p['name'] ?? 'أ'), style: const TextStyle(fontSize: 34))
                            : null,
                      ),
                    ),
                    if (_isMe)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: FBColors.primaryBlue,
                          radius: 16,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            onPressed: _pickAvatar,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 56),

          Center(
            child: Column(
              children: [
                Text(p['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if ((p['bio'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(p['bio'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (!_isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _friendshipStatus == 'friends' ? Colors.grey.shade300 : FBColors.primaryBlue,
                        foregroundColor: _friendshipStatus == 'friends' ? Colors.black87 : Colors.white,
                      ),
                      icon: Icon(_friendshipStatus == 'friends' ? Icons.check : Icons.person_add),
                      label: Text(_friendshipStatus == 'friends'
                          ? 'أصدقاء'
                          : (_friendshipStatus == 'sent' ? 'تم إرسال الطلب' : 'إضافة صديق')),
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
                      style: ElevatedButton.styleFrom(backgroundColor: isDark ? const Color(0xFF3E4042) : const Color(0xFFE4E6EB)),
                      icon: Icon(Icons.chat, color: isDark ? Colors.white : Colors.black),
                      label: Text('مراسلة', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(targetUser: p))),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(thickness: 0.5, height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('المنشورات (${_userPosts.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          const SizedBox(height: 8),

          if (_userPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
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
                    Text(formatArabicTime(post['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 6),
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
