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
                        _loadFeed();
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
