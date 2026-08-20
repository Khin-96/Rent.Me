import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_art_illustration.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    if (success) {
      context.go('/');
    } else {
      final error = ref.read(authProvider).error ?? 'Authentication failed';
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
                  const AuthArtIllustration(isLogin: true)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                  ).animate(delay: 100.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to manage your properties.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8A8A86),
                    ),
                  ).animate(delay: 150.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 22),

                  // Username / Email input container
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
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Username or Email',
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
                              if (v == null || v.trim().isEmpty) return 'Enter username or email';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms).slideY(begin: 0.1).fadeIn(),
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
                              hintText: 'Password',
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
                              if (v == null || v.isEmpty) return 'Enter your password';
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
                  ).animate(delay: 250.ms).slideY(begin: 0.1).fadeIn(),
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
                  ).animate(delay: 300.ms).fadeIn(),
                  const SizedBox(height: 22),

                  // Sign In Action Button
                  GestureDetector(
                    onTap: loading ? null : _login,
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
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ).animate(delay: 350.ms).slideY(begin: 0.1).fadeIn(),
                  const SizedBox(height: 20),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Don\'t have an account? ',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF8A8A86)),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
