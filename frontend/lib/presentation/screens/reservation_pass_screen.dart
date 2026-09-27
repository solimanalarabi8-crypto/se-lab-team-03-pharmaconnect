import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reservation_model.dart';
import '../widgets/pharmacy_route_map_widget.dart';

class ReservationPassScreen extends StatefulWidget {
  final ReservationModel reservation;

  const ReservationPassScreen({super.key, required this.reservation});

  @override
  State<ReservationPassScreen> createState() => _ReservationPassScreenState();
}

class _ReservationPassScreenState extends State<ReservationPassScreen> {
  late ReservationModel _reservation;
  late int _remainingSeconds;
  Timer? _timer;
  Timer? _pollTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
    _remainingSeconds = _reservation.currentRemainingSeconds;

    if (_reservation.status == 'pending') {
      if (_remainingSeconds > 0) {
        _startTimer();
      }
      _startPolling();
    }

    _checkServerStatus();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2, milliseconds: 500), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_reservation.status == 'pending') {
        await _checkServerStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkServerStatus() async {
    final prevStatus = _reservation.status;
    final isLocalMockCode = RegExp(r'^RES-\d+$').hasMatch(_reservation.reservationCode);

    ReservationModel? fresh;
    try {
      fresh = await ApiService().getReservationDetails(_reservation.reservationCode);
    } catch (_) {}

    // فقط إذا كان الرمز محلياً مؤقتاً (Mock) وفشل الاستعلام المباشر، نبحث في قائمة الحجوزات عن الحجز الحقيقي المقابل
    if (fresh == null && isLocalMockCode) {
      try {
        final myReservations = await ApiService().getMyReservations();
        for (final r in myReservations) {
          final matchesPharmacy = (r.pharmacy.id == _reservation.pharmacy.id) ||
              (r.pharmacy.name.trim() == _reservation.pharmacy.name.trim());
          if (matchesPharmacy && r.createdAt != null && DateTime.now().difference(r.createdAt!).inMinutes < 10) {
            fresh = r;
            break;
          }
        }
      } catch (_) {}
    }

    if (fresh != null && mounted) {
      // حماية صارمة ومطلقة: رمز الحجز ثابت تماماً للتذكرة الحالية ولا يتغير أبداً
      if (fresh.reservationCode != _reservation.reservationCode) {
        return;
      }

      final becameCompleted = (prevStatus != 'completed') && (fresh.status == 'completed');

      setState(() {
        _reservation = fresh!;
        _remainingSeconds = fresh.currentRemainingSeconds;
      });

      if (becameCompleted) {
        _timer?.cancel();
        _pollTimer?.cancel();
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.task_alt_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '🎉 تهانينا! أكد الصيدلي تسليم الدواء واستلام الحساب بنجاح.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (_reservation.status != 'pending' || _remainingSeconds <= 0) {
        _timer?.cancel();
        _pollTimer?.cancel();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _reservation.currentRemainingSeconds;
      setState(() {
        _remainingSeconds = remaining;
      });
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _copyCodeToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _reservation.reservationCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('تم نسخ رمز الحجز (${_reservation.reservationCode}) إلى الحافظة'),
          ],
        ),
        backgroundColor: PharmaTheme.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _callPharmacy(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (!await launchUrl(uri)) {
        // Fallback
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);
    final textMutedColor = isDark ? PharmaTheme.darkTextMuted : PharmaTheme.textMuted;
    final textMainColor = isDark ? PharmaTheme.darkTextMain : PharmaTheme.textMain;

    final status = _reservation.status;
    final isCompleted = status == 'completed';
    final isCancelled = status == 'cancelled';
    final isExpired = _reservation.isCurrentlyExpired || (!isCompleted && !isCancelled && _remainingSeconds <= 0);

    // تجهيز أيقونة وألوان الحالة بدقة طبية راقية
    final Color statusColor;
    final String statusBadgeTitle;
    final IconData statusIcon;

    if (isCompleted) {
      statusColor = const Color(0xFF10B981);
      statusBadgeTitle = 'تم استلام وتأكيد الطلب بنجاح ✓';
      statusIcon = Icons.task_alt_rounded;
    } else if (isCancelled) {
      statusColor = PharmaTheme.statusDanger;
      statusBadgeTitle = 'الحجز ملغي وتم فك حجز المخزون';
      statusIcon = Icons.cancel_outlined;
    } else if (isExpired) {
      statusColor = PharmaTheme.statusDanger;
      statusBadgeTitle = 'انتهت صلاحية مهلة الاستلام آلياً';
      statusIcon = Icons.hourglass_disabled_rounded;
    } else {
      statusColor = PharmaTheme.primaryGreen;
      statusBadgeTitle = 'تذكرة حجز دوائي صالحة ونشطة';
      statusIcon = Icons.verified_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تذكرة الحجز المؤكد'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث حالة الحجز اللحظية',
            onPressed: _isRefreshing
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _isRefreshing = true);
                    await _checkServerStatus();
                    if (!mounted) return;
                    setState(() => _isRefreshing = false);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          _reservation.status == 'completed'
                              ? 'الحجز مؤكد ومكتمل التسليم بنجاح ✓'
                              : 'تم تحديث حالة الحجز من الخادم المركزي.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
          children: [
            // ==================== بطاقة التذكرة الطبية (Boarding Pass) ====================
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // --- القسم العلوي: شارة الحالة وتاريخ الحجز ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? statusColor.withAlpha(35)
                          : statusColor.withAlpha(20),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withAlpha(150),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  statusBadgeTitle,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(statusIcon, color: statusColor, size: 20),
                      ],
                    ),
                  ),

                  // --- قسم الباركود / QR كود الموثق ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // إطار الماسح الضوئي الطبي للـ QR
                        Container(
                          width: 150,
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? PharmaTheme.darkNeonGreen.withAlpha(80) : PharmaTheme.primaryGreen.withAlpha(80),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen).withAlpha(25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 110,
                                color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                              ),
                              // زوايا الاستهداف البصري
                              Positioned(
                                top: 0,
                                right: 0,
                                child: _buildCornerTarget(isDark, true, true),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                child: _buildCornerTarget(isDark, true, false),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: _buildCornerTarget(isDark, false, true),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: _buildCornerTarget(isDark, false, false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // رمز الحجز مع زر النسخ السريع
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _reservation.reservationCode,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () => _copyCodeToClipboard(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen).withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أظهر هذا الرمز أو الكود للصيدلي لتأكيد الاستلام',
                          style: TextStyle(color: textMutedColor, fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        // --- مؤقت المهلة الزمنية المتبقية (TTL Countdown Pill) ---
                        if (!isCompleted && !isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                                  : (isDark ? const Color(0xFF064E3B).withAlpha(120) : PharmaTheme.mintBackground),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isExpired
                                    ? PharmaTheme.statusDanger.withAlpha(100)
                                    : (isDark ? PharmaTheme.darkNeonGreen.withAlpha(80) : PharmaTheme.primaryGreen.withAlpha(80)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpired ? Icons.timer_off_rounded : Icons.alarm_rounded,
                                  size: 18,
                                  color: isExpired
                                      ? PharmaTheme.statusDanger
                                      : (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    isExpired ? 'انتهت المهلة الزمنية' : 'المتبقي: ${_formatTime(_remainingSeconds)} دقيقة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: isExpired
                                          ? PharmaTheme.statusDanger
                                          : (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF064E3B).withAlpha(160) : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? PharmaTheme.darkNeonGreen : const Color(0xFF10B981),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 19,
                                  color: isDark ? PharmaTheme.darkNeonGreen : const Color(0xFF059669),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'تم استلام الدواء بنجاح ✓',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: isDark ? PharmaTheme.darkNeonGreen : const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- خط التمزيق والتثقيب التذكاري الفاخر (Perforated Tear Line) ---
                  _buildPerforatedDivider(isDark),

                  // --- القسم السفلي: تفاصيل الصيدلية والأصناف ---
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // بطاقة الصيدلية
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: PharmaTheme.primaryGreen.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.local_pharmacy_rounded, color: PharmaTheme.primaryGreen, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _reservation.pharmacy.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textMainColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _reservation.pharmacy.address,
                                      style: TextStyle(color: textMutedColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (_reservation.pharmacy.phone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk_rounded, color: PharmaTheme.primaryGreen),
                                  tooltip: 'اتصال بالصيدلية',
                                  onPressed: () => _callPharmacy(_reservation.pharmacy.phone),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // قائمة الأصناف
                        Text(
                          'تفاصيل الأصناف المحجوزة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textMainColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._reservation.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication_rounded, size: 16, color: PharmaTheme.primaryGreen),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicineName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: textMainColor,
                                        ),
                                      ),
                                      Text(
                                        'الكمية: ${item.quantity} عبوات',
                                        style: TextStyle(fontSize: 12, color: textMutedColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.subtotal.toStringAsFixed(0)} ريال',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: textMainColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 28, color: borderColor),

                        // الإجمالي النهائي
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'المبلغ الإجمالي للاستلام:',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textMainColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen).withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen).withAlpha(60),
                                ),
                              ),
                              child: Text(
                                '${_reservation.totalAmount.toStringAsFixed(0)} ريال',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreenDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==================== خريطة المسار المباشر الحقيقية ====================
            PharmacyRouteMapWidget(
              pharmacy: _reservation.pharmacy,
              initialDistanceKm: 1.2,
            ),
            const SizedBox(height: 24),

            // زر العودة والإنهاء
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                foregroundColor: textMainColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('العودة للبحث والأدوية', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildCornerTarget(bool isDark, bool isTop, bool isRight) {
    final color = isDark ? PharmaTheme.darkNeonGreen : PharmaTheme.primaryGreen;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: isRight ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: !isRight ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPerforatedDivider(bool isDark) {
    final bgScaffold = isDark ? PharmaTheme.darkBackground : PharmaTheme.backgroundLight;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFCBD5E1);

    return SizedBox(
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // خط منقط (Dashed Line)
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 6.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                    color: borderColor,
                  );
                }),
              );
            },
          ),
          // قَطع نصف دائري على اليمين (Right Notch)
          Positioned(
            right: -13,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: bgScaffold,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
            ),
          ),
          // قَطع نصف دائري على اليسار (Left Notch)
          Positioned(
            left: -13,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: bgScaffold,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
