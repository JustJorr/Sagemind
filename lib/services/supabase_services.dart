import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadVideo(File file, String materialId) async {
    final fileName = 'video_$materialId.mp4';
    final path = 'materials/$fileName';

    // Upload to bucket "Video_Materi"
    final res = await _client.storage
        .from('Video_Materi')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    if (res.isEmpty) return null;

    // Return public URL
    return _client.storage
        .from('Video_Materi')
        .getPublicUrl(path);
  }
}
