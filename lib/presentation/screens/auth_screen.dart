import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../core/services/auth_service.dart';
import '../../core/services/admin_service.dart';
import '../../logic/blocs/auth/auth_bloc.dart';
import '../../logic/blocs/auth/auth_event.dart';
import '../../logic/blocs/auth/auth_state.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isNavigating = false;
  bool _isAuthenticated = false;
  final _adminService = AdminService(Supabase.instance.client);
  bool? _cachedSuperAdminStatus;

  @override
  void initState() {
    super.initState();
    // Pre-cache admin status if possible
    _precacheAdminStatus();
  }

  Future<void> _precacheAdminStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _cachedSuperAdminStatus = await _adminService.isCurrentUserSuperAdmin();
      }
    } catch (_) {
      // Ignore errors during precaching
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(
        AuthService(Supabase.instance.client),
      )..add(const AuthCheckStarted()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated && !_isNavigating) {
            setState(() {
              _isNavigating = true; // Prevent multiple navigations
              _isAuthenticated = true; // Keep showing loading state
            });

            // Navigate immediately if we have cached status
            if (_cachedSuperAdminStatus != null) {
              _navigateBasedOnRole(context, _cachedSuperAdminStatus!);
              return;
            }

            // Otherwise check role and navigate
            _adminService.isCurrentUserSuperAdmin().then((isSuperAdmin) {
              _navigateBasedOnRole(context, isSuperAdmin);
            }).catchError((_) {
              // Default to regular dashboard on error
              _navigateBasedOnRole(context, false);
            });
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ: ${state.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Show loading during auth process or while navigating after authentication
            if (state is AuthLoading || _isAuthenticated) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const _AuthScreenContent();
          },
        ),
      ),
    );
  }

  void _navigateBasedOnRole(BuildContext context, bool isSuperAdmin) {
    if (!mounted) return;

    // Navigate to appropriate dashboard
    if (isSuperAdmin) {
      context.go('/super-admin');
    } else {
      context.go('/');
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم تسجيل الدخول بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _AuthScreenContent extends StatefulWidget {
  const _AuthScreenContent();

  @override
  State<_AuthScreenContent> createState() => _AuthScreenContentState();
}

class _AuthScreenContentState extends State<_AuthScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SignInRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A0A0A),
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    const Color(0xFFCBD5E1),
                  ],
          ),
        ),
        child: Stack(
          children: [
                  // Floating geometric shapes
                  Positioned(
                    top: screenHeight * 0.1,
                    right: screenWidth * 0.1,
                    child: _buildFloatingShape(
                      size: 120,
                      color: isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF6366F1),
                      opacity: 0.1,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.3,
                    left: -60,
                    child: _buildFloatingShape(
                      size: 200,
                      color: isDark
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFFEC4899),
                      opacity: 0.08,
                      isSquare: true,
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.2,
                    right: -40,
                    child: _buildFloatingShape(
                      size: 160,
                      color: isDark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF06B6D4),
                      opacity: 0.06,
                    ),
                  ),

            // Main content - Centered
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: _getHorizontalPadding(screenWidth),
                  vertical: _getVerticalPadding(screenHeight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Modern logo section with neumorphism
                    _buildModernLogo(screenWidth, isDark),
                    SizedBox(height: _getSpacing(screenWidth) * 1.5),

                    // Title with gradient text
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF60A5FA),
                                const Color(0xFFA78BFA)
                              ]
                            : [
                                const Color(0xFF3B82F6),
                                const Color(0xFF8B5CF6)
                              ],
                      ).createShader(bounds),
                      child: Text(
                        'Admin Portal',
                        style: TextStyle(
                          fontSize: _getTitleFontSize(screenWidth),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    SizedBox(height: _getSpacing(screenWidth) * 0.5),

                    // Subtitle with modern typography
                    Text(
                      'Secure access to your dashboard',
                      style: TextStyle(
                        fontSize: _getSubtitleFontSize(screenWidth),
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: _getSpacing(screenWidth) * 3),

                    // Modern authentication form with advanced glassmorphism
                    _buildModernForm(screenWidth, isDark),

                    SizedBox(height: _getSpacing(screenWidth) * 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive helper methods
  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth > 1200) return screenWidth * 0.3;
    if (screenWidth > 800) return screenWidth * 0.2;
    if (screenWidth > 600) return screenWidth * 0.15;
    return 16.0;
  }

  double _getVerticalPadding(double screenHeight) {
    if (screenHeight > 800) return 32.0;
    if (screenHeight > 600) return 24.0;
    return 16.0;
  }

  double _getContainerPadding(double screenWidth) {
    if (screenWidth > 800) return 32.0;
    if (screenWidth > 600) return 24.0;
    return 20.0;
  }

  double _getBorderRadius(double screenWidth) {
    if (screenWidth > 800) return 24.0;
    if (screenWidth > 600) return 20.0;
    return 16.0;
  }

  double _getIconPadding(double screenWidth) {
    if (screenWidth > 800) return 20.0;
    if (screenWidth > 600) return 16.0;
    return 12.0;
  }

  double _getIconSize(double screenWidth) {
    if (screenWidth > 800) return 60.0;
    if (screenWidth > 600) return 50.0;
    return 40.0;
  }

  double _getTitleFontSize(double screenWidth) {
    if (screenWidth > 800) return 32.0;
    if (screenWidth > 600) return 28.0;
    return 24.0;
  }

  double _getSubtitleFontSize(double screenWidth) {
    if (screenWidth > 800) return 18.0;
    if (screenWidth > 600) return 16.0;
    return 14.0;
  }

  double _getButtonFontSize(double screenWidth) {
    if (screenWidth > 800) return 18.0;
    if (screenWidth > 600) return 16.0;
    return 14.0;
  }

  double _getButtonHeight(double screenWidth) {
    if (screenWidth > 800) return 56.0;
    if (screenWidth > 600) return 52.0;
    return 48.0;
  }

  double _getFormMaxWidth(double screenWidth) {
    if (screenWidth > 1200) return 500.0;
    if (screenWidth > 800) return 450.0;
    return double.infinity;
  }

  double _getSpacing(double screenWidth, [double? baseSpacing]) {
    final spacing = baseSpacing ?? 24.0;
    if (screenWidth > 800) return spacing;
    if (screenWidth > 600) return spacing * 0.8;
    return spacing * 0.6;
  }

  Widget _buildFloatingShape({
    required double size,
    required Color color,
    required double opacity,
    bool isSquare = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isSquare ? BorderRadius.circular(size * 0.2) : null,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildModernLogo(double screenWidth, bool isDark) {
    return Container(
      width: _getIconSize(screenWidth) + 40,
      height: _getIconSize(screenWidth) + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF374151),
                  const Color(0xFF1F2937),
                  const Color(0xFF111827),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE2E8F0),
                ],
        ),
        boxShadow: [
          // Outer shadow
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(8, 8),
          ),
          // Inner highlight
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      child: Icon(
        Icons.admin_panel_settings_rounded,
        size: _getIconSize(screenWidth),
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
      ),
    );
  }

  Widget _buildModernForm(double screenWidth, bool isDark) {
    final isLoading = context.select(
      (AuthBloc bloc) => bloc.state is AuthLoading,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: _getFormMaxWidth(screenWidth),
      ),
      child: Container(
        padding: EdgeInsets.all(_getContainerPadding(screenWidth)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getBorderRadius(screenWidth)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF374151).withOpacity(0.3),
                    const Color(0xFF1F2937).withOpacity(0.2),
                  ]
                : [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.7),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0xFF64748B).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildModernTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                screenWidth: screenWidth,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: _getSpacing(screenWidth)),
              _buildModernTextField(
                controller: _passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                screenWidth: screenWidth,
                isDark: isDark,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submitForm(),
              ),
              SizedBox(height: _getSpacing(screenWidth) * 1.5),
              _buildModernButton(screenWidth, isDark, isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    required double screenWidth,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    final borderRadius = _getBorderRadius(screenWidth) * 0.7;
    final fontSize = _getTextFieldFontSize(screenWidth);

    return Container(
      // Add constraints to prevent NaN values in BoxConstraints
      constraints: const BoxConstraints(
        minHeight: 56.0, // Minimum height for text field
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1F2937).withOpacity(0.5),
                  const Color(0xFF111827).withOpacity(0.3),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  Colors.white,
                ],
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          // Inset shadow for depth
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : const Color(0xFF64748B).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onFieldSubmitted: onFieldSubmitted,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1F2937),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
            size: _getTextFieldIconSize(screenWidth),
          ),
          suffixIcon: suffixIcon != null
              ? Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  child: suffixIcon,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2,
            ),
          ),
          errorStyle: TextStyle(
            color: const Color(0xFFEF4444),
            fontSize: fontSize * 0.875,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _getTextFieldPadding(screenWidth),
            vertical: _getTextFieldPadding(screenWidth),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildModernButton(double screenWidth, bool isDark, bool isLoading) {
    return Container(
      width: double.infinity,
      height: _getButtonHeight(screenWidth),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(_getBorderRadius(screenWidth) * 0.7),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLoading
              ? [
                  const Color(0xFF9CA3AF),
                  const Color(0xFF6B7280),
                ]
              : [
                  const Color(0xFF3B82F6),
                  const Color(0xFF1D4ED8),
                  const Color(0xFF1E40AF),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
          onPressed: isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(_getBorderRadius(screenWidth) * 0.7),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'جاري تسجيل الدخول',
                      style: TextStyle(
                        fontSize: _getButtonFontSize(screenWidth),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: _getButtonFontSize(screenWidth),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                )),
    );
  }

  double _getTextFieldFontSize(double screenWidth) {
    if (screenWidth > 800) return 16.0;
    if (screenWidth > 600) return 15.0;
    return 14.0;
  }

  double _getTextFieldIconSize(double screenWidth) {
    if (screenWidth > 800) return 22.0;
    if (screenWidth > 600) return 20.0;
    return 18.0;
  }

  double _getTextFieldPadding(double screenWidth) {
    if (screenWidth > 800) return 20.0;
    if (screenWidth > 600) return 18.0;
    return 16.0;
  }
}
