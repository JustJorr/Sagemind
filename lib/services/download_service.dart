import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  /// Download a document from URL and save it to device
  Future<String?> downloadDocument(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Get the downloads directory
      Directory? directory;
      
      if (Platform.isAndroid) {
        // For Android, use the Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        
        // Fallback to app's external storage if Downloads folder doesn't exist
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        // For iOS, use app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file path
      final filePath = '${directory.path}/$fileName';
      
      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        // Add timestamp to make filename unique
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final parts = fileName.split('.');
        final extension = parts.length > 1 ? parts.last : '';
        final nameWithoutExt = parts.length > 1 
            ? parts.sublist(0, parts.length - 1).join('.')
            : fileName;
        final newFilePath = '${directory.path}/${nameWithoutExt}_$timestamp.$extension';
        
        // Download to new file path
        await _dio.download(
          url,
          newFilePath,
          onReceiveProgress: onProgress,
        );
        
        return newFilePath;
      }

      // Download the file
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
      );

      return filePath;
    } catch (e) {
      print('[DOWNLOAD] Error downloading document: $e');
      return null;
    }
  }

  /// Open a downloaded file using the system's default app
  Future<bool> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // You'll need to add open_file package for this
      // Or use url_launcher with file:// URI
      return true;
    } catch (e) {
      print('[DOWNLOAD] Error opening file: $e');
      return false;
    }
  }
}