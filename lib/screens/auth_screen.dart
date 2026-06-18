import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/supabase_service.dart';
import '../services/biometric_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submitAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        // Integración de seguridad biométrica antes de iniciar sesión
        final isAuthenticated = await BiometricService.authenticate();
        if (!isAuthenticated) {
          throw Exception('Autenticación biométrica cancelada o fallida.');
        }

        await SupabaseService.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await SupabaseService.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Revisa tu correo para confirmar tu cuenta.',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              backgroundColor: Theme.of(context).cardColor,
            ),
          );
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Exception:')
                  ? e.toString().replaceAll('Exception: ', '')
                  : 'Ocurrió un error inesperado.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _socialLogin(OAuthProvider provider) async {
    try {
      // Integración de seguridad biométrica antes de iniciar sesión social
      final isAuthenticated = await BiometricService.authenticate();
      if (!isAuthenticated) {
        throw Exception('Autenticación biométrica cancelada o fallida.');
      }
      await SupabaseService.client.auth.signInWithOAuth(provider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error de autenticación: ${e.toString().replaceAll('Exception: ', '')}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(CupertinoIcons.book_solid, size: 80, color: primaryColor)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Bienvenido de\nvuelta' : 'Crea tu\ncuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.1,
                    color: primaryColor,
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  'OmniLibrary te conecta con el conocimiento del mundo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: primaryColor.withOpacity(0.6),
                  ),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 40),
                // Campos de texto estilo iOS
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    prefixIcon: Icon(
                      CupertinoIcons.mail,
                      color: primaryColor.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: primaryColor.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ).animate().fade(delay: 400.ms).slideX(begin: 0.05, end: 0),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    prefixIcon: Icon(
                      CupertinoIcons.lock,
                      color: primaryColor.withOpacity(0.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: primaryColor.withOpacity(0.5),
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: primaryColor.withOpacity(0.04),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ).animate().fade(delay: 500.ms).slideX(begin: 0.05, end: 0),
                const SizedBox(height: 24),
                // Botón principal de autenticación
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).cardColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                            ),
                          ),
                  ),
                ).animate().fade(delay: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: primaryColor.withOpacity(0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o continúa con',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: primaryColor.withOpacity(0.2)),
                    ),
                  ],
                ).animate().fade(delay: 700.ms),
                const SizedBox(height: 24),
                // Botones Sociales OAuth
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _SocialButton(
                      icon: Icons.g_mobiledata, // Google
                      label: 'Google',
                      onTap: () => _socialLogin(OAuthProvider.google),
                    ),
                    _SocialButton(
                      icon: Icons.window, // Microsoft
                      label: 'Microsoft',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'La integración con Microsoft estará disponible próximamente 🪟',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: const Color(
                              0xFF0078D4,
                            ), // Azul característico de Microsoft
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                    _SocialButton(
                      icon: Icons.apple, // Apple nativo
                      label: 'Apple',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'La integración con Apple estará disponible próximamente 🍏',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.black87,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                )
                    .animate()
                    .fade(delay: 800.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 40),
                // Alternar vista entre Login / Registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? '¿No tienes cuenta?' : '¿Ya tienes cuenta?',
                      style: TextStyle(color: primaryColor.withOpacity(0.7)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? 'Regístrate' : 'Inicia Sesión',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: primaryColor.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          mainAxisSize: MainAxisSize
              .min, // Evita crash por desbordamiento infinito en el Wrap
          children: [
            Icon(icon, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
