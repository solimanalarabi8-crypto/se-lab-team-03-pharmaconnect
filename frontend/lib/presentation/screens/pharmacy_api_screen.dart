import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// شاشة طلب مفتاح API للصيدليات - تربط الصيدليات بنظام PharmaConnect
class PharmacyApiScreen extends StatefulWidget {
  const PharmacyApiScreen({super.key});

  @override
  State<PharmacyApiScreen> createState() => _PharmacyApiScreenState();
}

class _PharmacyApiScreenState extends State<PharmacyApiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _pharmacyNameCtrl = TextEditingController();
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _systemCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _requestSubmitted = false;
  int _selectedPlan = 0;

  static const String _demoApiKey =
      'pk_live_pharma_xK9mN2vL8qR4sT7wY1jD3aF6hG0bC5eP';
  static const String _demoBaseUrl = 'https://api.pharmaconnect.ye/v1';

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'مجاني (تجريبي)',
      'price': 'مجاناً',
      'limit': '500 طلب / شهر',
      'color': 0xFF64748B,
    },
    {
      'name': 'احترافي',
      'price': '19,900 ريال / شهر',
      'limit': '50,000 طلب / شهر',
      'color': 0xFF059669,
    },
    {
      'name': 'مؤسسي',
      'price': '49,900 ريال / شهر',
      'limit': 'طلبات غير محدودة',
      'color': 0xFF7C3AED,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pharmacyNameCtrl.dispose();
    _licenseCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _systemCtrl.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _requestSubmitted = true;
      });
    }
  }

  void _copyToClipboard(BuildContext ctx, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('تم نسخ $label بنجاح'),
          ],
        ),
        backgroundColor: PharmaTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen;
    final bgCard = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderC = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);
    final textMain = isDark ? PharmaTheme.darkTextMain : PharmaTheme.textMain;
    final textMuted = isDark ? PharmaTheme.darkTextMuted : PharmaTheme.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.api_rounded, color: primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'ربط الصيدلية بـ PharmaConnect',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: textMuted,
          indicatorColor: primary,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'طلب ربط'),
            Tab(icon: Icon(Icons.code_rounded, size: 18), text: 'التوثيق'),
            Tab(
                icon: Icon(Icons.integration_instructions_rounded, size: 18),
                text: 'Endpoints'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestTab(isDark, bgCard, borderC, textMain, textMuted, primary),
          _buildDocsTab(isDark, bgCard, borderC, textMain, textMuted, primary),
          _buildEndpointsTab(isDark, bgCard, borderC, textMain, textMuted, primary),
        ],
      ),
    );
  }

  // ---- تبويب طلب الربط ----
  Widget _buildRequestTab(bool isDark, Color bgCard, Color borderC,
      Color textMain, Color textMuted, Color primary) {
    if (_requestSubmitted) {
      return _buildSuccessView(isDark, bgCard, borderC, textMain, textMuted, primary);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ترويسة تعريفية
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                    : [PharmaTheme.primaryGreen, PharmaTheme.primaryGreenDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.hub_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ربط صيدليتك بنظام PharmaConnect',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'مزامنة المخزون لحظياً عبر واجهة برمجية آمنة',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(Icons.sync_rounded, 'مزامنة فورية'),
                    _chip(Icons.security_rounded, 'OAuth2'),
                    _chip(Icons.inventory_2_rounded, 'إدارة مخزون'),
                    _chip(Icons.notifications_active_rounded, 'إشعارات'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('نموذج طلب مفتاح API للصيدلية',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textMain)),
          const SizedBox(height: 6),
          Text(
            'أدخل بيانات صيدليتك وسيتم مراجعة الطلب خلال 24 ساعة، ثم إرسال مفتاح API إلى بريدك الإلكتروني.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                    ctrl: _pharmacyNameCtrl,
                    label: 'اسم الصيدلية الرسمي',
                    hint: 'مثال: صيدلية الشفاء الحديثة',
                    icon: Icons.local_pharmacy_rounded,
                    isDark: isDark,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال اسم الصيدلية'
                        : null),
                const SizedBox(height: 14),
                _field(
                    ctrl: _licenseCtrl,
                    label: 'رقم الترخيص الصيدلاني',
                    hint: 'مثال: YE-PHRM-2024-00123',
                    icon: Icons.badge_rounded,
                    isDark: isDark,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'رقم الترخيص مطلوب'
                        : null),
                const SizedBox(height: 14),
                _field(
                    ctrl: _emailCtrl,
                    label: 'البريد الإلكتروني الرسمي',
                    hint: 'pharmacy@example.com',
                    icon: Icons.email_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'البريد الإلكتروني مطلوب';
                      }
                      if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    }),
                const SizedBox(height: 14),
                _field(
                    ctrl: _phoneCtrl,
                    label: 'رقم هاتف التقني المسؤول',
                    hint: '+967 71 234 5678',
                    icon: Icons.phone_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'رقم الهاتف مطلوب'
                        : null),
                const SizedBox(height: 14),
                _field(
                    ctrl: _systemCtrl,
                    label: 'نظام إدارة المخزون المستخدم (اختياري)',
                    hint: 'QuickBooks / نظام بالعربي / Excel',
                    icon: Icons.computer_rounded,
                    isDark: isDark,
                    maxLines: 2),
                const SizedBox(height: 24),

                Text('اختر خطة الاشتراك',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textMain)),
                const SizedBox(height: 12),

                // خيارات الخطة
                ..._plans.asMap().entries.map((entry) {
                  final i = entry.key;
                  final plan = entry.value;
                  final isSelected = _selectedPlan == i;
                  final planColor = Color(plan['color'] as int);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPlan = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? planColor.withAlpha(isDark ? 40 : 20)
                            : bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? planColor : borderC,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: planColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plan['name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected ? planColor : textMain,
                                  ),
                                ),
                                Text(plan['limit'] as String,
                                    style: TextStyle(
                                        fontSize: 11, color: textMuted)),
                              ],
                            ),
                          ),
                          Text(
                            plan['price'] as String,
                            style: TextStyle(
                                color: planColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _isSubmitting ? null : _submitRequest,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_isSubmitting
                        ? 'جارٍ إرسال الطلب...'
                        : 'إرسال طلب الربط الآن'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon,
            color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark, Color bgCard, Color borderC,
      Color textMain, Color textMuted, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderC),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF064E3B)
                        : PharmaTheme.mintAccent,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.check_circle_rounded, color: primary, size: 56),
                ),
                const SizedBox(height: 20),
                Text('تم إرسال طلبك بنجاح!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textMain)),
                const SizedBox(height: 10),
                Text(
                  'سيتم مراجعة بيانات صيدليتك خلال 24 ساعة، ثم إرسال مفتاح API ودليل الاندماج إلى بريدك الإلكتروني.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textMuted, height: 1.6, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B1120)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: primary.withAlpha(80)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.key_rounded, color: primary, size: 16),
                          const SizedBox(width: 6),
                          Text('مفتاح API الخاص بصيدليتك (نموذج توضيحي)',
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _demoApiKey,
                              style: TextStyle(
                                  color: textMain,
                                  fontSize: 10,
                                  fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy_rounded,
                                color: primary, size: 18),
                            onPressed: () =>
                                _copyToClipboard(context, _demoApiKey, 'مفتاح API'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _requestSubmitted = false),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('إرسال طلب آخر'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- تبويب التوثيق ----
  Widget _buildDocsTab(bool isDark, Color bgCard, Color borderC,
      Color textMain, Color textMuted, Color primary) {
    const sections = [
      {
        'icon': 0xE8B4,   // rocket_launch
        'title': 'البدء السريع (Quick Start)',
        'content': '''1. احصل على مفتاح API من تبويب "طلب ربط".
2. أضف المفتاح في ترويسة كل طلب:
   Authorization: Bearer YOUR_API_KEY
3. عنوان الـ API الأساسي:
   https://api.pharmaconnect.ye/v1
4. اضبط Content-Type على:
   application/json''',
      },
      {
        'icon': 0xE627,   // sync
        'title': 'مزامنة المخزون',
        'content': '''PATCH /api/v1/pharmacy/inventory/{stockId}
Body:
{
  "available_quantity": 150,
  "price": 2500,
  "is_available": true
}
Response 200:
{
  "success": true,
  "message": "تم تحديث المخزون بنجاح",
  "updated_at": "2025-01-01T12:00:00Z"
}''',
      },
      {
        'icon': 0xEF54,   // notifications
        'title': 'استقبال إشعارات الحجوزات (Webhooks)',
        'content': '''POST /api/v1/pharmacy/webhooks
{
  "url": "https://yourpharmacy.com/webhook",
  "events": [
    "reservation.created",
    "reservation.cancelled",
    "reservation.expired"
  ]
}
Payload عند الحجز:
{
  "event": "reservation.created",
  "reservation_id": 12345,
  "medicine_name": "Panadol Extra",
  "quantity": 2,
  "patient_name": "أحمد محمد",
  "expires_at": "2025-01-01T12:30:00Z"
}''',
      },
      {
        'icon': 0xE8D0,   // shield
        'title': 'الأمان و Rate Limits',
        'content': '''• جميع الطلبات مشفرة بـ HTTPS (TLS 1.3)
• استخدم Bearer Token في كل طلب
• حد الطلبات:
  - مجاني:      500 طلب/شهر
  - احترافي: 50,000 طلب/شهر
  - مؤسسي:   غير محدود
• عند التجاوز: HTTP 429
• صلاحية المفتاح: 365 يوماً (تجديد تلقائي)''',
      },
    ];

    final icons = [
      Icons.rocket_launch_rounded,
      Icons.sync_rounded,
      Icons.notifications_rounded,
      Icons.shield_rounded,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(sections.length, (i) {
          final s = sections[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderC),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B)
                                : PharmaTheme.mintAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icons[i], color: primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s['title']! as String,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textMain)),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderC),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SelectableText(
                            s['content']! as String,
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.7,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded,
                              color: primary, size: 16),
                          onPressed: () =>
                              _copyToClipboard(context, s['content']! as String, s['title']! as String),
                          tooltip: 'نسخ',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---- تبويب Endpoints ----
  Widget _buildEndpointsTab(bool isDark, Color bgCard, Color borderC,
      Color textMain, Color textMuted, Color primary) {
    final endpoints = [
      {'method': 'GET', 'path': '/pharmacy/inventory', 'desc': 'جلب قائمة مخزون الصيدلية', 'color': 0xFF059669},
      {'method': 'POST', 'path': '/pharmacy/inventory', 'desc': 'إضافة دواء جديد إلى المخزون', 'color': 0xFF3B82F6},
      {'method': 'PATCH', 'path': '/pharmacy/inventory/{id}', 'desc': 'تحديث كمية أو سعر دواء', 'color': 0xFFD97706},
      {'method': 'DELETE', 'path': '/pharmacy/inventory/{id}', 'desc': 'حذف دواء من المخزون', 'color': 0xFFDC2626},
      {'method': 'GET', 'path': '/pharmacy/reservations', 'desc': 'جلب قائمة الحجوزات النشطة والمنتهية', 'color': 0xFF059669},
      {'method': 'PATCH', 'path': '/pharmacy/reservations/{id}/confirm', 'desc': 'تأكيد استلام المريض للدواء', 'color': 0xFFD97706},
      {'method': 'PATCH', 'path': '/pharmacy/reservations/{id}/cancel', 'desc': 'إلغاء حجز وإعادة الكمية للمخزون', 'color': 0xFFDC2626},
      {'method': 'POST', 'path': '/pharmacy/webhooks', 'desc': 'تسجيل Webhook لاستقبال إشعارات الحجوزات', 'color': 0xFF7C3AED},
      {'method': 'GET', 'path': '/pharmacy/stats', 'desc': 'إحصائيات الصيدلية: حجوزات، مبيعات، أكثر طلباً', 'color': 0xFF059669},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base URL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0B1120)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base URL',
                          style: TextStyle(
                              color: primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_demoBaseUrl,
                          style: TextStyle(
                              color: textMain,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: primary, size: 18),
                  onPressed: () =>
                      _copyToClipboard(context, _demoBaseUrl, 'Base URL'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('الـ Endpoints المتاحة للصيدليات',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: textMain)),
          const SizedBox(height: 12),
          ...endpoints.map((ep) {
            final methodColor = Color(ep['color'] as int);
            final fullPath = '/api/v1${ep['path']}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderC),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: methodColor.withAlpha(isDark ? 50 : 25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: methodColor.withAlpha(80)),
                        ),
                        child: Text(
                          ep['method'] as String,
                          style: TextStyle(
                            color: methodColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fullPath,
                          style: TextStyle(
                            color: textMain,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 16, color: textMuted),
                        onPressed: () =>
                            _copyToClipboard(context, fullPath, 'Endpoint'),
                        tooltip: 'نسخ',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(ep['desc'] as String,
                      style: TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
