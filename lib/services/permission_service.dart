import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

  // Add this method to your PermissionService class
  Future<bool> requestDownloadPermission() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      
      // Android 13+ (API 33+) doesn't need storage permission for downloads
      if (androidVersion >= 33) {
        return true;
      }
      
      // Android 10-12 (API 29-32)
      if (androidVersion >= 29) {
        // Scoped storage - no permission needed for app-specific directory
        return true;
      }
      
      // Android 9 and below (API 28-)
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    
    return true; // iOS doesn't need this permission
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }
}