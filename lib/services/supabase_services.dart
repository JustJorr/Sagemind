import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String?> uploadVideo(File file, String materialId) async {
    final fileName = 'video_$materialId.mp4';
    final filePath = 'materials/$fileName';

    try {
      print('[SUPABASE] Uploading video to bucket: Video_Materi');
      final res = await _client.storage
          .from('Video_Materi')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      if (res.isEmpty) {
        print('[SUPABASE] Video upload failed: response is empty');
        return null;
      }

      final publicUrl = _client.storage
          .from('Video_Materi')
          .getPublicUrl(filePath);
      
      print('[SUPABASE] Video uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('[SUPABASE] Error uploading video: $e');
      return null;
    }
  }

  /// Upload document (PDF, DOCX, DOC, etc.)
  Future<String?> uploadDocument(File file, String materialId) async {
    final fileExtension = path.extension(file.path).replaceFirst('.', '');
    final fileName = 'doc_$materialId.$fileExtension';
    final filePath = 'materials/$fileName';

    try {
      print('[SUPABASE] ========== DOCUMENT UPLOAD START ==========');
      print('[SUPABASE] Material ID: $materialId');
      print('[SUPABASE] File: ${file.path}');
      print('[SUPABASE] Extension: $fileExtension');
      print('[SUPABASE] File name: $fileName');
      print('[SUPABASE] File path: $filePath');
      print('[SUPABASE] File size: ${file.lengthSync()} bytes');
      
      final res = await _client.storage
          .from('Documents')
          .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

      print('[SUPABASE] Upload response: $res');

      if (res.isEmpty) {
        print('[SUPABASE] ERROR: Document upload failed - response is empty');
        return null;
      }

      final publicUrl = _client.storage
          .from('Documents')
          .getPublicUrl(filePath);
      
      print('[SUPABASE] Document uploaded successfully!');
      print('[SUPABASE] Public URL: $publicUrl');
      print('[SUPABASE] ========== DOCUMENT UPLOAD END ==========');
      return publicUrl;
    } catch (e) {
      print('[SUPABASE] ERROR uploading document: $e');
      print('[SUPABASE] Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Delete document from storage
  Future<bool> deleteDocument(String documentUrl) async {
    try {
      print('[SUPABASE] Deleting document: $documentUrl');

      final uri = Uri.parse(documentUrl);
      final pathSegments = uri.pathSegments;

      // Extract file path from URL
      final bucketIndex = pathSegments.indexOf('Documents');
      if (bucketIndex == -1) {
        print('[SUPABASE] Could not find documents in URL');
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print('[SUPABASE] Extracted file path: $filePath');

      await _client.storage
          .from('Documents')
          .remove([filePath]);

      print('[SUPABASE] Document deleted successfully');
      return true;
    } catch (e) {
      print('[SUPABASE] Error deleting document: $e');
      return false;
    }
  }

  Future<bool> deleteVideo(String videoUrl) async {
    try {
      print('[SUPABASE] Deleting video: $videoUrl');

      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;

      // Extract file path from URL
      final bucketIndex = pathSegments.indexOf('Video_Materi');
      if (bucketIndex == -1) {
        print('[SUPABASE] Could not find Video_Materi in URL');
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print('[SUPABASE] Extracted file path: $filePath');

      await _client.storage
          .from('Video_Materi')
          .remove([filePath]);

      print('[SUPABASE] Video deleted successfully');
      return true;
    } catch (e) {
      print('[SUPABASE] Error deleting video: $e');
      return false;
    }
  }
}