import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zuno/services/session_guard.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/motion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin email — shown in "Contact Admin" link
// ─────────────────────────────────────────────────────────────────────────────
const _adminEmail = 'prajapatirajan776@gmail.com';

// ─────────────────────────────────────────────────────────────────────────────
// Login Screen — Firebase Email/Password Auth
// Only users manually created in Firebase Console can sign in.
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;

    // Static Dummy Login Bypass
    if ((email == 'demo@eg.com' || email == 'dmeo@eg.com') && password == 'neelma') {
      await SessionGuard.markSignedIn(demo: true);
      Get.offAllNamed('/');
      return;
    }

    try {
      // Sign in via Firebase — only admin-created accounts will work
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // ✅ Success — save session flag and navigate
      await SessionGuard.markSignedIn(demo: false);
      Get.offAllNamed('/');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        switch (e.code) {
          case 'user-not-found':
          case 'invalid-email':
          case 'user-disabled':
            _error =
                'This account is not registered.\nContact your admin for access.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            _error = 'Incorrect password. Please try again.';
            break;
          case 'too-many-requests':
            _error =
                'Too many attempts. Please wait a few minutes and try again.';
            break;
          case 'network-request-failed':
            _error = 'No internet connection. Please check your network.';
            break;
          default:
            _error = 'Login failed. Please try again.';
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }


  bool _showForm = false;

  Future<void> _contactAdmin() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _adminEmail,
      query: 'subject=Zuno%20App%20Access%20Request',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed photo with a slow drift
          Image.asset('assets/onboarding/login.jpg', fit: BoxFit.cover)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: const Duration(seconds: 14),
                  curve: Curves.easeInOut),
          // Legibility gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.35, 0.7, 1],
                colors: [
                  Color(0x55000000),
                  Color(0x11000000),
                  Color(0x99000000),
                  Color(0xEE000000),
                ],
              ),
            ),
          ),

          // Logo + tagline
          FadeTransition(
            opacity: _fade,
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              alignment: _showForm
                  ? const Alignment(0, -0.62)
                  : const Alignment(0, -0.05),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset('assets/logo.png', width: 64, height: 64),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Music for\nevery mood',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 16)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions / sign-in form
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                              begin: const Offset(0, 0.12), end: Offset.zero)
                          .animate(a),
                      child: child,
                    ),
                  ),
                  child: _showForm ? _form() : _actions(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Column(
      key: const ValueKey('actions'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(
          label: 'Sign in',
          light: true,
          onTap: () => setState(() => _showForm = true),
        ),
        const SizedBox(height: 12),
        _pill(
          label: 'Request access',
          icon: Icons.mail_outline_rounded,
          onTap: _contactAdmin,
        ),
      ],
    );
  }

  Widget _form() {
    return ClipRRect(
      key: const ValueKey('form'),
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Welcome back',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4)),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                      onPressed: () => setState(() {
                        _showForm = false;
                        _error = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: _emailCtrl,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 10),
                _inputField(
                  controller: _passCtrl,
                  hint: 'Password',
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white60,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFFF9A8F), fontSize: 13, height: 1.35)),
                ],
                const SizedBox(height: 16),
                _pill(
                  label: 'Continue',
                  light: true,
                  loading: _loading,
                  onTap: _loading ? null : _submit,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _contactAdmin,
                  child: Text("Don't have access? Contact admin",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full-width pill button: white (light) or black.
  Widget _pill({
    required String label,
    VoidCallback? onTap,
    bool light = false,
    bool loading = false,
    IconData? icon,
  }) {
    final fg = light ? Colors.black : Colors.white;
    return PressScale(
      child: Material(
        color: light ? Colors.white : Colors.black,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: loading
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: fg))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fg, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(label,
                            style: TextStyle(
                                color: fg,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    const radius = BorderRadius.all(Radius.circular(18));
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 15.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.35),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: const OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(
            borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: const OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: Colors.white54, width: 1.2)),
        errorBorder: const OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: Color(0xFFFF9A8F), width: 1)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: Color(0xFFFF9A8F), width: 1.2)),
        errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFFF9A8F)),
      ),
    );
  }
}
