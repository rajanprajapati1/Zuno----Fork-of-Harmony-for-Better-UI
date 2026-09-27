import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '/native_bindings/andrid_utils.dart' show SDKInt;

class PermissionService {
  /// Storage access for saving downloads to a folder the user picked.
  /// Explains why before the system prompt, and offers App settings when
  /// the permission was denied for good.
  static Future<bool> getExtStoragePermission() async {
    // Desktop has no storage permission; iOS apps only write to their own
    // sandbox. SDKInt below is an Android-only JNI binding.
    if (!GetPlatform.isAndroid) {
      return Future.value(true);
    }
    final legacy = SDKInt.Companion.getSDKInt() < 30;
    final permission =
        legacy ? Permission.storage : Permission.manageExternalStorage;

    if (await permission.isGranted) return true;

    if (await permission.isPermanentlyDenied) {
      if (await _explain(settings: true)) await openAppSettings();
      return false;
    }

    if (!await _explain()) return false;

    final status = legacy
        ? (await [Permission.storage, Permission.accessMediaLocation]
                .request())[Permission.storage] ??
            PermissionStatus.denied
        : await permission.request();

    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (await _explain(settings: true)) await openAppSettings();
    }
    return false;
  }

  /// Rationale dialog. Returns true when the user chose to continue.
  static Future<bool> _explain({bool settings = false}) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        icon: const Icon(Icons.folder_open_rounded, size: 32),
        title: const Text("Allow storage access"),
        content: Text(settings
            ? "Storage access is turned off for Zuno. Open App settings and allow "
                "\"Files and media\" (or \"All files access\") to save songs to "
                "the folder you choose."
            : "Zuno needs storage access to save downloaded songs to the folder "
                "you choose, so you can find them in any music player or file "
                "manager."),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Not now")),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text(settings ? "Open settings" : "Continue")),
        ],
      ),
    );
    return ok ?? false;
  }
}
