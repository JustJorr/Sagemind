import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  /// Request video/storage permissions based on Android version
  Future<bool> requestVideoPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdk = androidInfo.version.sdkInt;

      // Android 13+ → USE READ_MEDIA_VIDEO
      if (sdk >= 33) {
        final status = await Permission.videos.request();
        return status.isGranted;
      }

      // Android 12 and below → STORAGE permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }

    return false;
  }

  /// Check if permission is already granted
  Future<bool> isVideoPermissionGranted() async {
    if (Platform.isIOS) {
      return (await Permission.photos.status).isGranted;
    }

    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdk = androidInfo.version.sdkInt;

      if (sdk >= 33) {
        return (await Permission.videos.status).isGranted;
      }

      return (await Permission.storage.status).isGranted;
    }

    return false;
  }
}