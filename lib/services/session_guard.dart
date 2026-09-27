import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../ui/player/player_controller.dart';

/// Keeps the login honest: checks with Firebase that the signed-in account
/// still exists, is enabled and has not had its sessions revoked. Runs at
/// launch, when the app returns to the foreground and every 10 minutes.
/// A revoked account is signed out and sent back to the login screen.
class SessionGuard {
  SessionGuard._();

  static Timer? _timer;
  static bool _checking = false;

  static Box get _prefs => Hive.box('AppPrefs');
  static bool get _firebaseReady => Firebase.apps.isNotEmpty;

  /// Start the periodic check (safe to call more than once).
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => verify());
    // first check shortly after launch, once the UI is up
    Future.delayed(const Duration(seconds: 3), verify);
  }

  /// Called after a successful sign-in.
  static Future<void> markSignedIn({required bool demo}) async {
    await _prefs.put('isLoggedIn', true);
    await _prefs.put('isDemoSession', demo);
  }

  /// Checks the current session; signs out if the account was removed,
  /// disabled or revoked. Network problems never sign the user out.
  static Future<void> verify() async {
    if (_checking || _prefs.get('isLoggedIn') != true) return;
    // demo sessions have no Firebase account to check
    if (_prefs.get('isDemoSession') == true) return;
    if (!_firebaseReady) return;
    _checking = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // logged-in flag without a Firebase account: not a valid session
        await logout(reason: 'Please sign in again.');
        return;
      }
      // reload fails for deleted/disabled users; a forced token refresh
      // fails once the admin revokes the user's sessions
      await user.reload();
      await user.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      const revoked = {
        'user-not-found',
        'user-disabled',
        'user-token-expired',
        'invalid-user-token',
        'invalid-credential',
      };
      if (revoked.contains(e.code)) {
        await logout(
            reason: e.code == 'user-disabled'
                ? 'Your access has been disabled. Contact your admin.'
                : 'Your access has been removed. Contact your admin.');
      }
    } catch (_) {
      // offline or transient error: keep the session, try again later
    } finally {
      _checking = false;
    }
  }

  /// Signs out everywhere and returns to the login screen.
  static Future<void> logout({String? reason}) async {
    try {
      if (Get.isRegistered<PlayerController>()) {
        Get.find<PlayerController>().pause();
      }
    } catch (_) {}
    try {
      if (_firebaseReady) await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _prefs.put('isLoggedIn', false);
    await _prefs.delete('isDemoSession');
    await _prefs.delete('appMode');
    Get.offAllNamed('/');
    if (reason != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        Get.snackbar('Signed out', reason,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
            backgroundColor: Colors.black87,
            colorText: Colors.white);
      });
    }
  }

  /// Asks before logging out.
  static Future<void> confirmLogout() async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to use Zuno.'),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Log out')),
      ],
    ));
    if (ok == true) await logout();
  }
}
