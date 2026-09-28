'avatar_url': avatar}),
^^^^^^^^^
Target kernel_snapshot_program failed: Exception
```[span_1](start_span)[span_1](end_span)

### ما هو سبب الخطأ؟
في ملف **`lib/screens/profile_screen.dart`**، عند الضغط على زر "مراسلة"، كنا نمرر بيانات الحساب كـ:
`_profile ?? {'id': _targetId, 'name': name, 'avatar_url': avatar}`

فلاتر اعتبر القوس الثاني من نوع نصوص فقط (`Map<String, String>`) بينما شاشة الشات تطلب (`Map<String, dynamic>`)، وهذا أدى لتوقف بناء التطبيق فوراً[span_2](start_span)[span_2](end_span).

---

### الحل (خلال دقيقة واحدة):

سنقوم بتحديث ملف **`lib/screens/profile_screen.dart`** لضبط النوع البرمجي بدقة وتفادي هذا الخطأ نهائياً.

1. افتح مستودعك في **GitHub**.
2. ادخل إلى مجلد **`lib`** ثم مجلد **`screens`**.
3. اضغط على ملف **`profile_screen.dart`**.
4. اضغط على القلم **✏️**.
5. امسح الكود بالكامل وضع هذا الكود المصحح والمضبوط:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final Map<String, dynamic>? initialProfile;

  const ProfileScreen({
    super.key,
    this.userId,
    this.initialProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _friends = [];
  bool _loading = true;
  bool _isFriend = false;
  bool _requestPending = false;

  final ImagePicker _picker = ImagePicker();

  String get _targetId => widget.userId ?? supabase.auth.currentUser?.id ?? '';
  bool get _isMyProfile => _targetId == (supabase.auth.currentUser?.id ?? '');

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _loading = false;
    }
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final myId = supabase.auth.currentUser?.id;

      final p = await supabase.from('profiles').select().eq('id', _targetId).maybeSingle();
      final postsRes = await supabase.from('posts').select().eq('user_id', _targetId).order('created_at', ascending: false);

      if (!_isMyProfile && myId != null) {
        final rel = await supabase.from('friendships').select().or('and(sender_id.eq.$myId,receiver_id.eq.$_targetId),and(sender_id.eq.$_targetId,receiver_id.eq.$myId)').maybeSingle();
        if (rel != null) {
          _isFriend = rel['status'] == 'accepted';
          _requestPending = rel['status'] == 'pending';
        }
      }

      final friendsRel = await supabase.from('friendships').select('sender_id, receiver_id').or('sender_id.eq.$_targetId,receiver_id.eq.$_targetId').eq('status', 'accepted').limit(6);
      final List friendIds = [];
      for (var f in friendsRel) {
        final id = f['sender_id'] == _targetId ? f['receiver_id'] : f['sender_id'];
        friendIds.add(id);
      }
      if (friendIds.isNotEmpty) {
        final friendsData = await supabase.from('profiles').select('id, name, avatar_url').filter('id', 'in', friendIds);
        _friends = List<Map<String, dynamic>>.from(friendsData);
      }

      if (mounted) {
        setState(() {
          if (p != null) _profile = p;
          _userPosts = List<Map<String, dynamic>>.from(postsRes);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 600);
    if (picked == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري رفع صورتك الشخصية وتحديثها سحابياً... ⏳')));

    try {
      final cloudUrl = await StorageService.uploadImage(file: File(picked.path), folder: 'avatars');
      if (cloudUrl != null) {
        await supabase.from('profiles').update({'avatar_url': cloudUrl}).eq('id', _targetId);
        await supabase.from('posts').update({'author_avatar': cloudUrl}).eq('user_id', _targetId);

        setState(() {
          _profile?['avatar_url'] = cloudUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث صورتك الشخصية بنجاح! 🎉')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _changeCover() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1200);
    if (picked == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري رفع غلاف الصفحة... ⏳')));

    try {
      final cloudUrl = await StorageService.uploadImage(file: File(picked.path), folder: 'covers');
      if (cloudUrl != null) {
        await supabase.from('profiles').update({'cover_url': cloudUrl}).eq('id', _targetId);
        setState(() {
          _profile?['cover_url'] = cloudUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث صورة الغلاف بنجاح! 🖼️')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الغلاف: $e'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _handleFriendAction() async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    if (_isFriend) {
      await supabase.from('friendships').delete().or('and(sender_id.eq.$myId,receiver_id.eq.$_targetId),and(sender_id.eq.$_targetId,receiver_id.eq.$myId)');
      setState(() {
        _isFriend = false;
        _requestPending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الصداقة')));
    } else if (_requestPending) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('طلب الصداقة معلق بالفعل')));
    } else {
      await supabase.from('friendships').insert({
        'sender_id': myId,
        'receiver_id': _targetId,
        'status': 'pending',
      });
      setState(() => _requestPending = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الصداقة بنجاح!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _profile?['name'] ?? 'مستخدم أثير';
    final bio = _profile?['bio'] ?? '';
    final avatar = _profile?['avatar_url'] ?? '';
    final cover = _profile?['cover_url'] ?? '';
    final isFounder = _profile?['is_founder'] == true;
    final location = _profile?['location'] ?? '';
    final work = _profile?['work'] ?? '';
    final edu = _profile?['education'] ?? '';
    final birth = _profile?['birth_date'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: Navigator.canPop(context)
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          if (_isMyProfile)
            IconButton(
              icon: const Icon(Icons.settings, color: FBColors.primaryBlue),
              onPressed: () => _openSettingsModal(),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FBColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: ListView(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      GestureDetector(
                        onTap: _isMyProfile ? _changeCover : null,
                        child: Container(
                          height: 190,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                            gradient: cover.isEmpty
                                ? const LinearGradient(
                                    colors: [Color(0xFF0052D4), Color(0xFF4364F7), Color(0xFF6FB1FC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: cover.isNotEmpty
                              ? renderUniversalImage(cover, fit: BoxFit.cover, width: double.infinity)
                              : null,
                        ),
                      ),
                      if (_isMyProfile)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: GestureDetector(
                            onTap: _changeCover,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('تعديل الغلاف', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: -48,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: FBColors.primaryBlue,
                                backgroundImage: getUniversalImageProvider(avatar),
                                child: (avatar.isEmpty) ? Text(getFirstChar(name), style: const TextStyle(fontSize: 44, color: Colors.white)) : null,
                              ),
                            ),
                            if (_isMyProfile)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _changeAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 18),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                        if (isFounder) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: FBColors.primaryBlue, size: 22),
                        ],
                      ],
                    ),
                  ),
                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Text(bio, textAlign: TextAlign.center, style: TextStyle(color: isDark ? FBColors.darkSubText : FBColors.lightSubText, fontSize: 14)),
                    ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (_isMyProfile) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FBColors.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              label: const Text('إضافة إلى القصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? FBColors.darkInput : FBColors.lightInput,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black, size: 18),
                              label: Text('تعديل الملف', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () => _openFullEditModal(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _circleActionBtn(Icons.more_horiz, () => _openSettingsModal()),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFriend ? (isDark ? FBColors.darkInput : FBColors.lightInput) : FBColors.primaryBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              icon: Icon(
                                _isFriend ? Icons.people : (_requestPending ? Icons.hourglass_top : Icons.person_add),
                                color: _isFriend ? (isDark ? Colors.white : Colors.black) : Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                _isFriend ? 'أصدقاء 👥' : (_requestPending ? 'معلق ⏳' : 'إضافة صديق'),
                                style: TextStyle(
                                  color: _isFriend ? (isDark ? Colors.white : Colors.black) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: _handleFriendAction,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // هنا تم تصحيح نوع البيانات بدقة عالية
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? FBColors.darkInput : FBColors.lightInput,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 9),
                              ),
                              icon: const Icon(Icons.chat_bubble, color: FBColors.primaryBlue, size: 18),
                              label: Text('مراسلة', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                              onPressed: () {
                                final Map<String, dynamic> targetData = _profile != null
                                    ? Map<String, dynamic>.from(_profile!)
                                    : <String, dynamic>{'id': _targetId, 'name': name, 'avatar_url': avatar};
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(targetUser: targetData),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _circleActionBtn(Icons.more_horiz, () {}),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(thickness: 0.5),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('التفاصيل 📌', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        if (work.isNotEmpty) _fbDetailItem(Icons.work, 'يعمل لدى $work'),
                        if (edu.isNotEmpty) _fbDetailItem(Icons.school, 'درس في $edu'),
                        if (location.isNotEmpty) _fbDetailItem(Icons.home, 'يقيم في $location'),
                        if (birth.isNotEmpty) _fbDetailItem(Icons.cake, 'تاريخ الميلاد: $birth'),
                        const SizedBox(height: 10),
                        if (_isMyProfile)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FBColors.primaryBlue.withOpacity(0.12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openFullEditModal(),
                              child: const Text('تعديل التفاصيل العامة', style: TextStyle(color: FBColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(thickness: 0.5),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الأصدقاء', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                Text('${_friends.length} من الأصدقاء', style: TextStyle(fontSize: 12, color: isDark ? FBColors.darkSubText : FBColors.lightSubText)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_friends.isEmpty)
                          const Text('لا يوجد أصدقاء للعرض حالياً.', style: TextStyle(fontSize: 12, color: Colors.grey))
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _friends.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (ctx, i) {
                              final f = _friends[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: f['id'], initialProfile: f)));
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: renderUniversalImage(f['avatar_url'], width: double.infinity, fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(f['name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const Divider(thickness: 0.5),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('منشورات $name', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),

                  if (_userPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('لا توجد منشورات لهذا المستخدم بعد.')),
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
                                CircleAvatar(radius: 18, backgroundImage: getUniversalImageProvider(avatar)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(formatArabicTime(post['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if ((post['text'] ?? '').isNotEmpty)
                              Text(post['text'] ?? '', style: const TextStyle(fontSize: 14.5, height: 1.35)),
                            if ((post['image_url'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: renderUniversalImage(post['image_url'], width: double.infinity, fit: BoxFit.cover),
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

  Widget _circleActionBtn(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isDark ? FBColors.darkInput : FBColors.lightInput,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _fbDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _openFullEditModal() {
    final nameCtrl = TextEditingController(text: _profile?['name'] ?? '');
    final bioCtrl = TextEditingController(text: _profile?['bio'] ?? '');
    final workCtrl = TextEditingController(text: _profile?['work'] ?? '');
    final eduCtrl = TextEditingController(text: _profile?['education'] ?? '');
    String country = _profile?['country'] ?? 'فلسطين';
    String city = _profile?['city'] ?? 'خان يونس';
    String birthDate = _profile?['birth_date'] ?? '';
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setM) {
          final cities = locationsData[country] ?? ['المركز'];
          final safeCity = cities.contains(city) ? city : cities.first;

          return Padding(
            padding: EdgeInsets.only(left: 18, right: 18, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('تعديل الملف الشخصي ✏️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم المعروض')),
                  TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'النبذة التعريفية (Bio)')),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: locationsData.containsKey(country) ? country : 'فلسطين',
                          decoration: const InputDecoration(labelText: 'الدولة'),
                          items: locationsData.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setM(() {
                                country = v;
                                city = locationsData[v]!.first;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: safeCity,
                          decoration: const InputDecoration(labelText: 'المدينة'),
                          items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) {
                            if (v != null) setM(() => city = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  TextField(controller: workCtrl, decoration: const InputDecoration(labelText: 'العمل')),
                  TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'التعليم')),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: FBColors.primaryBlue),
                      onPressed: saving
                          ? null
                          : () async {
                              setM(() => saving = true);
                              final updated = {
                                'name': nameCtrl.text.trim(),
                                'bio': bioCtrl.text.trim(),
                                'work': workCtrl.text.trim(),
                                'education': eduCtrl.text.trim(),
                                'country': country,
                                'city': city,
                                'location': '$country، $city',
                                'birth_date': birthDate,
                              };

                              await supabase.from('profiles').update(updated).eq('id', _targetId);
                              await supabase.from('posts').update({'author_name': nameCtrl.text.trim()}).eq('user_id', _targetId);

                              Navigator.pop(ctx);
                              _loadProfileData();
                            },
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: FBColors.primaryBlue),
              title: const Text('تعديل الملف الشخصي'),
              onTap: () {
                Navigator.pop(ctx);
                _openFullEditModal();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                await supabase.auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
