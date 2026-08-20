import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_art_illustration.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        );
    if (!mounted) return;
    if (success) {
      context.go('/');
    } else {
      final error = ref.read(authProvider).error ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: const Color(0xFF111111), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const AuthArtIllustration(isLogin: false)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  const Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                  ).animate(delay: 100.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a Landlord account to get started.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8A8A86),
                    ),
                  ).animate(delay: 150.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 20),

                  // Full Name input container
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCDCD8), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Color(0xFF9A9A96), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Full Name',
                              hintStyle: TextStyle(color: Color(0xFF9A9A96), fontSize: 13.5),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter your name';
                              if (v.trim().length < 2) return 'Name too short';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 12),

                  // Mobile number input container
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCDCD8), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, color: Color(0xFF9A9A96), size: 19),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Mobile Number',
                              hintStyle: TextStyle(color: Color(0xFF9A9A96), fontSize: 13.5),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 230.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 12),

                  // Email input container
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCDCD8), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Color(0xFF9A9A96), size: 19),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Email address',
                              hintStyle: TextStyle(color: Color(0xFF9A9A96), fontSize: 13.5),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter your email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 260.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 12),

                  // Password input container
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCDCD8), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Color(0xFF9A9A96), size: 19),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Password (min 8 chars)',
                              hintStyle: TextStyle(color: Color(0xFF9A9A96), fontSize: 13.5),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter a password';
                              if (v.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF9A9A96),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 300.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 18),

                  // Remember me Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Remember me',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF8A8A86), fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 20,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: _rememberMe ? const Color(0xFF111111) : const Color(0xFFDCDCD8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: _rememberMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 350.ms).fadeIn(),
                  const SizedBox(height: 22),

                  // Sign Up Action Button
                  GestureDetector(
                    onTap: loading ? null : _register,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ).animate(delay: 400.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 20),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF8A8A86)),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 450.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
