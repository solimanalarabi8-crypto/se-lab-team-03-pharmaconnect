import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/reservation_model.dart';
import 'reservation_pass_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;
  Timer? _ticker;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _reservations = ApiService().cachedReservations;
    _isLoading = _reservations.isEmpty;
    ApiService().addListener(_onApiServiceChanged);

    _loadReservations(silent: _reservations.isNotEmpty);

    // تحديث عداد الثواني محلياً كل ثانية
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_reservations.any((r) => r.status == 'pending' && !r.isCurrentlyExpired)) {
        setState(() {});
      }
    });

    // مزامنة صامتة مع الخادم كل 3.5 ثوانٍ طالما توجد طلبات معلقة
    _pollTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_reservations.any((r) => r.status == 'pending')) {
        _loadReservations(silent: true);
      }
    });
  }

  void _onApiServiceChanged() {
    if (mounted) {
      setState(() {
        _reservations = ApiService().cachedReservations;
        if (_reservations.isNotEmpty) _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    ApiService().removeListener(_onApiServiceChanged);
    _ticker?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReservations({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    final results = await ApiService().getMyReservations();

    // فحص دقيق ومباشر لكل حجز ما زال بحالة معلقة (pending) لضمان التقاط التغيير فوراً
    final pendingItems = results.where((r) => r.status == 'pending').toList();
    for (final pending in pendingItems) {
      await ApiService().getReservationDetails(pending.reservationCode);
    }

    if (mounted) {
      setState(() {
        _reservations = ApiService().cachedReservations;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجوزاتي وطلباتي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReservations,
        color: PharmaTheme.primaryGreen,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: PharmaTheme.primaryGreen),
              )
            : _reservations.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد لديك طلبات حجز حالياً',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'عند حجز أي دواء من الصيدليات المتاحة سيظهر طلبك هنا مباشرة لمتابعة الاستلام والمهلة الزمنية.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF94A3B8)
                                  : PharmaTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final item = _reservations[index];
                      return _buildReservationCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildReservationCard(ReservationModel item) {
    final isPending = item.status == 'pending' && !item.isExpired;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isDark ? PharmaTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationPassScreen(reservation: item),
            ),
          ).then((_) => _loadReservations());
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPending
                                ? (isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPending ? Icons.timer_outlined : Icons.check_circle_outline,
                            color: isPending
                                ? (isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark)
                                : (isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.reservationCode,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                item.pharmacy.name,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(item, isDark),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(item),
                      style: TextStyle(
                        color: _getStatusTextColor(item, isDark),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 20, color: isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0)),
              ...item.items.map(
                (med) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${med.medicineName} (× ${med.quantity})',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${med.subtotal.toStringAsFixed(0)} ريال',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 20, color: isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0)),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'الإجمالي: ',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item.totalAmount.toStringAsFixed(0)} ريال',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreen,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReservationPassScreen(reservation: item),
                        ),
                      ).then((_) => _loadReservations());
                    },
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('عرض التذكرة والباركود'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusBgColor(ReservationModel item, bool isDark) {
    if (item.status == 'completed') {
      return isDark ? const Color(0xFF064E3B).withAlpha(120) : const Color(0xFFDCFCE7);
    }
    if (item.status == 'cancelled' || item.status == 'expired' || item.isCurrentlyExpired) {
      return isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
    }
    return isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent;
  }

  Color _getStatusTextColor(ReservationModel item, bool isDark) {
    if (item.status == 'completed') {
      return isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
    }
    if (item.status == 'cancelled' || item.status == 'expired' || item.isCurrentlyExpired) {
      return isDark ? const Color(0xFFF87171) : PharmaTheme.statusDanger;
    }
    return isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark;
  }

  String _getStatusLabel(ReservationModel item) {
    if (item.status == 'completed') {
      return 'تم الاستلام بنجاح ✓';
    }
    if (item.status == 'cancelled') {
      return 'ملغي';
    }
    if (item.status == 'expired' || item.isCurrentlyExpired) {
      return 'منتهي الصلاحية';
    }
    if (item.status == 'pending') {
      final rem = item.currentRemainingSeconds;
      final mins = rem ~/ 60;
      final secs = rem % 60;
      return 'نشط (${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')})';
    }
    return item.status;
  }
}
