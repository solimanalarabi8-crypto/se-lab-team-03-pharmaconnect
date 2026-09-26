import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegistering = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'يرجى إدخال البريد الإلكتروني وكلمة المرور';
      });
      return;
    }

    AuthResult result;
    if (_isRegistering) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      if (name.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'يرجى إدخال الاسم الكامل للمريض';
        });
        return;
      }
      result = await ApiService().register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
    } else {
      result = await ApiService().login(email, password);
    }

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'بيانات الدخول غير صحيحة أو تعذر الاتصال بالخادم.';
      });
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);
    final tabBg = isDark ? PharmaTheme.darkSurfaceElevated : const Color(0xFFF1F5F9);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // زر تبديل الثيم في الزاوية العلوية
            Positioned(
              top: 12,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: IconButton(
                  tooltip: isDark ? 'التحويل إلى الوضع النهاري' : 'التحويل إلى الوضع الليلي',
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark,
                  ),
                  onPressed: () {
                    ThemeController().toggleTheme();
                    setState(() {});
                  },
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // شعار المنصة الطبية
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: PharmaTheme.primaryGreen.withAlpha(isDark ? 30 : 40),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.local_pharmacy_rounded,
                          size: 52,
                          color: isDark ? const Color(0xFF6EE7B7) : PharmaTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: isDark ? const Color(0xFF6EE7B7) : PharmaTheme.primaryGreenDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المنصة الذكية لتتبع وفرة الأدوية وإدارة الحجوزات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // بطاقة تسجيل الدخول أو إنشاء الحساب
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 35 : 8),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // أزرار التبديل العلوية (Tab Switcher)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: tabBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRegistering = false;
                                          _errorMessage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: !_isRegistering ? cardBg : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: !_isRegistering
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                                                    blurRadius: 4,
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          'تسجيل الدخول',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: !_isRegistering
                                                ? (isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark)
                                                : (isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRegistering = true;
                                          _errorMessage = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _isRegistering ? cardBg : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: _isRegistering
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                                                    blurRadius: 4,
                                                  )
                                                ]
                                              : null,
                                        ),
                                        child: Text(
                                          'إنشاء حساب جديد',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _isRegistering
                                                ? (isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark)
                                                : (isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: PharmaTheme.statusDanger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: PharmaTheme.statusDanger, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // حقول إنشاء الحساب الإضافية
                        if (_isRegistering) ...[
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'الاسم الكامل للعميل / المستخدم',
                              hintText: 'مثال: يعقوب خالد',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف للتواصل',
                              hintText: 'مثال: 771234567',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // حقول البريد وكلمة المرور
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'مثال: patient@pharmaconnect.ye',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // زر الإرسال
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _isLoading ? null : _submitAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  _isRegistering ? 'إنشاء الحساب والدخول' : 'تسجيل الدخول الآن',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                        if (!_isRegistering) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _emailController.text = 'patient@pharmaconnect.ye';
                              _passwordController.text = 'password123';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? PharmaTheme.darkSurfaceElevated : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 15,
                                    color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'تجربة سريعة: patient@pharmaconnect.ye (اضغط للتعبئة)',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زر الدخول كزائر / استعلام مباشر
                  TextButton.icon(
                    onPressed: _continueAsGuest,
                    icon: Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                    ),
                    label: Text(
                      'المتابعة كزائر والبحث عن الأدوية مباشرة',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
}
}
