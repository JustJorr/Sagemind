import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  /// Request video/storage permissions
  Future<bool> requestVideoPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      // Try READ_MEDIA_VIDEO first (Android 13+)
      var status = await Permission.videos.request();
      if (status.isGranted) {
        return true;
      }
      
      // Fall back to storage permission (Android 12 and below)
      status = await Permission.storage.request();
      return status.isGranted;
    }

    return false;
  }

  /// Check if video permission is already granted
  Future<bool> isVideoPermissionGranted() async {
    if (Platform.isIOS) {
      return (await Permission.photos.status).isGranted;
    }

    if (Platform.isAndroid) {
      final videoStatus = await Permission.videos.status;
      if (videoStatus.isGranted) {
        return true;
      }
      
      final storageStatus = await Permission.storage.status;
      return storageStatus.isGranted;
    }

    return false;
  }

  /// Request file/document permissions (PDF, DOC, DOCX, etc.)
    Future<bool> requestFilePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      // Try READ_MEDIA_VISUAL_USER_SELECTED first (Android 14+)
      var status = await Permission.mediaLibrary.request();
      if (status.isGranted) {
        return true;
      }
      
      // Fall back to storage permission (Android 13 and below)
      status = await Permission.storage.request();
      return status.isGranted;
    }

    return false;
  }
}