import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/constants/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isRegistering = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCity = 'صنعاء، اليمن';
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showEditProfileModal(dynamic user) {
    final nameEditController = TextEditingController(text: user.name);
    final phoneEditController = TextEditingController(text: user.phone ?? '');
    bool isSaving = false;
    String? editError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'تعديل البيانات الشخصية',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  if (editError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        editError!,
                        style: const TextStyle(color: PharmaTheme.statusDanger, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameEditController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneEditController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف للتواصل',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newName = nameEditController.text.trim();
                            final newPhone = phoneEditController.text.trim();
                            if (newName.isEmpty) {
                              setModalState(() {
                                editError = 'يرجى إدخال الاسم.';
                              });
                              return;
                            }

                            setModalState(() {
                              isSaving = true;
                              editError = null;
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(modalContext);
                            final res = await ApiService().updateProfile(
                              name: newName,
                              phone: newPhone,
                            );

                            if (res.success) {
                              if (mounted) {
                                navigator.pop();
                                setState(() {});
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('تم حفظ وتحديث بيانات الحساب بنجاح!'),
                                    backgroundColor: PharmaTheme.primaryGreen,
                                  ),
                                );
                              }
                            } else {
                              setModalState(() {
                                isSaving = false;
                                editError = res.errorMessage ?? 'تعذر حفظ البيانات.';
                              });
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('حفظ التعديلات الآن'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCitySelector() {
    final cities = [
      'صنعاء، اليمن',
      'عدن، اليمن',
      'تعز، اليمن',
      'إب، اليمن',
      'حضرموت / المكلا',
      'الحديدة، اليمن',
      'ذمار، اليمن',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر المدينة / النطاق الجغرافي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'يتم استخدام هذا النطاق لحساب المسافة للصيدليات الأقرب إليك',
                style: TextStyle(color: PharmaTheme.textMuted, fontSize: 12),
              ),
              const Divider(height: 20),
              ...cities.map((city) {
                final isSelected = city == _selectedCity;
                return ListTile(
                  leading: Icon(
                    Icons.location_city_rounded,
                    color: isSelected ? PharmaTheme.primaryGreen : PharmaTheme.textMuted,
                  ),
                  title: Text(
                    city,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? PharmaTheme.primaryGreenDark : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: PharmaTheme.primaryGreen)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCity = city;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تعيين النطاق الجغرافي: $city'),
                        backgroundColor: PharmaTheme.primaryGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTtlInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_outlined, color: PharmaTheme.primaryGreen),
            SizedBox(width: 8),
            Text('صلاحية الحجز (TTL)'),
          ],
        ),
        content: const Text(
          'تمنحك المنصة مهلة افتراضية قدرها 30 دقيقة للحجز المؤكد.\n\n'
          'خلال هذه المهلة يتم حجز كمية الدواء لك في مخزون الصيدلية تلقائياً ومنع بيعها لعميل آخر لحين وصولك واستلامها، لضمان عدم نفاد الدواء أثناء توجهك للصيدلية.',
          style: TextStyle(fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً، فهمت'),
          ),
        ],
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _notificationsEnabled
              ? 'تم تفعيل إشعارات وتنبيهات توفر الأدوية.'
              : 'تم تعطيل إشعارات توفر الأدوية مؤقتاً.',
        ),
        backgroundColor: _notificationsEnabled ? PharmaTheme.primaryGreen : PharmaTheme.statusDanger,
        duration: const Duration(seconds: 2),
      ),
    );
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
          _errorMessage = 'يرجى إدخال اسمك الكامل';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegistering ? 'تم إنشاء الحساب بنجاح!' : 'تم تسجيل الدخول بنجاح!'),
            backgroundColor: PharmaTheme.primaryGreen,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = result.errorMessage ?? 'تعذر المصادقة. يرجى التحقق من البيانات المدخلة.';
      });
    }
  }

  void _logout() async {
    final navigator = Navigator.of(context, rootNavigator: true);
    await ApiService().logout();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الخروج بنجاح')),
      );
    }
    navigator.pushNamedAndRemoveUntil(
      AppConstants.authRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;
    final isLoggedIn = ApiService().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي والحساب'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: isLoggedIn && user != null ? _buildProfileView(user) : _buildAuthForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView(dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // بطاقة الهوية الشخصية (عرض كامل موحد)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenLight,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: isDark ? const Color(0xFF6EE7B7) : PharmaTheme.primaryGreenDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                ),
              ),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  user.phone!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // شارة عميل موثّق
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withAlpha(140) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'عميل موثّق ومعتمد',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // زر تعديل البيانات الشخصية
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreen,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF047857) : PharmaTheme.primaryGreenLight,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => _showEditProfileModal(user),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'تعديل البيانات الشخصية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // بطاقة الإعدادات والخيارات (بنفس العرض والتباعد)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // تبديل المظهر الليلي / النهاري
              _buildSettingTile(
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: 'المظهر الليلي (Dark Mode)',
                subtitle: isDark ? 'مفعل (مريح للعينين)' : 'معطل (الثيم النهاري الطبي)',
                trailing: Switch(
                  value: ThemeController().isDarkMode,
                  activeThumbColor: PharmaTheme.primaryGreen,
                  activeTrackColor: PharmaTheme.mintAccent,
                  onChanged: (val) {
                    ThemeController().toggleTheme();
                    setState(() {});
                  },
                ),
              ),
              Divider(height: 1, indent: 64, endIndent: 16, color: borderColor),
              _buildSettingTile(
                icon: Icons.location_on_rounded,
                title: 'المدينة والنطاق الجغرافي',
                subtitle: 'اضغط لتغيير المدينة الحالية',
                trailing: _buildBadge(_selectedCity, isDark),
                onTap: _showCitySelector,
              ),
              Divider(height: 1, indent: 64, endIndent: 16, color: borderColor),
              _buildSettingTile(
                icon: Icons.timer_rounded,
                title: 'صلاحية الحجز الافتراضية',
                subtitle: 'المهلة الممنوحة للاستلام (TTL)',
                trailing: _buildBadge('30 دقيقة', isDark),
                onTap: _showTtlInfoDialog,
              ),
              Divider(height: 1, indent: 64, endIndent: 16, color: borderColor),
              _buildSettingTile(
                icon: Icons.notifications_active_rounded,
                title: 'إشعارات توفر الدواء',
                subtitle: 'اضغط للتبديل السريع',
                trailing: _buildBadge(
                  _notificationsEnabled ? 'مفعلة' : 'معطلة',
                  isDark,
                  isSuccess: _notificationsEnabled,
                ),
                onTap: _toggleNotifications,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // زر تسجيل الخروج
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
            foregroundColor: isDark ? const Color(0xFFFCA5A5) : PharmaTheme.statusDanger,
            minimumSize: const Size(double.infinity, 52),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: BorderSide(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA)),
          ),
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('تسجيل الخروج من الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: isDark ? const Color(0xFF6EE7B7) : PharmaTheme.primaryGreenDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRegistering ? 'إنشاء حساب جديد' : 'تسجيل الدخول للعميل',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'لحفظ ومتابعة حجوزاتك الدوائية بسهولة',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
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

          if (_isRegistering) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم الكامل',
                hintText: 'مثال: يعقوب خالد',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                hintText: 'مثال: 771234567',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'مثال: user@example.com',
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

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _isLoading ? null : _submitAuth,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(_isRegistering ? 'إنشاء الحساب الآن' : 'تسجيل الدخول'),
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isRegistering = !_isRegistering;
                  _errorMessage = null;
                });
              },
              child: Text(
                _isRegistering ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب جديد',
                style: const TextStyle(color: PharmaTheme.primaryGreenDark, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? const Color(0xFF334155) : PharmaTheme.mintAccent;
    final iconColor = isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }

  Widget _buildBadge(String text, bool isDark, {bool isSuccess = false}) {
    final bg = isSuccess
        ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final fg = isSuccess
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
