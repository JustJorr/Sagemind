import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadVideo(File file, String materialId) async {
    final fileName = 'video_$materialId.mp4';
    final filePath = 'materials/$fileName';

    try {
      final res = await _client.storage
          .from('Video_Materi')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      if (res.isEmpty) return null;

      return _client.storage
          .from('Video_Materi')
          .getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  /// Upload document (PDF, DOCX, DOC, etc.)
  Future<String?> uploadDocument(File file, String materialId) async {
    final fileExtension = path.extension(file.path).replaceFirst('.', '');
    final fileName = 'doc_$materialId.$fileExtension';
    final filePath = 'materials/$fileName';

    try {
      final res = await _client.storage
          .from('Document_Materi')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      if (res.isEmpty) return null;

      return _client.storage
          .from('Documents')
          .getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }

  /// Delete document from storage
  Future<bool> deleteDocument(String documentUrl) async {
    try {
      final uri = Uri.parse(documentUrl);
      final pathSegments = uri.pathSegments;
      
      // Extract file path from URL
      final filePath = pathSegments.sublist(pathSegments.indexOf('Document_Materi') + 1).join('/');
      
      await _client.storage
          .from('Document_Materi')
          .remove([filePath]);
      
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
}