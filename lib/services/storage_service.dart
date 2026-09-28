import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String bucketName = 'media';

  /// دالة رفع الصورة إلى سحابة Supabase والحصول على رابط سريع مباشر
  static Future<String?> uploadImage({
    required File file,
    required String folder, // 'posts' أو 'avatars' أو 'stories' أو 'chats'
  }) async {
    try {
      final userId = _client.auth.currentUser?.id ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExt = file.path.split('.').last.toLowerCase();
      
      // مسار منظم للملف داخل السحابة
      final filePath = '$folder/$userId/${timestamp}.$fileExt';
      final bytes = await file.readAsBytes();

      // رفع الملف إلى سلة التخزين السحابية
      await _client.storage.from(bucketName).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // جلب الرابط المباشر العام
      final publicUrl = _client.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('خطأ أثناء رفع الصورة إلى السحابة: $e');
      return null;
    }
  }
}
