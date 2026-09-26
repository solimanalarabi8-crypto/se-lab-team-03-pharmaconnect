import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/medicine_search_model.dart';
import '../widgets/pharmacy_route_map_widget.dart';
import 'reservation_pass_screen.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final MedicineSearchItem item;

  const MedicineDetailsScreen({super.key, required this.item});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  int _quantity = 1;
  late int _availableQuantity;
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _availableQuantity = widget.item.availableQuantity;
    final user = ApiService().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      if (user.phone != null) {
        _phoneController.text = user.phone!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _reserveMedicine() async {
    setState(() {
      _isLoading = true;
    });

    final reservation = await ApiService().createReservation(
      stockId: widget.item.stockId,
      quantity: _quantity,
      ttlMinutes: 30,
      patientName: _nameController.text.trim(),
      patientPhone: _phoneController.text.trim(),
      pharmacy: widget.item.pharmacy,
      medicine: widget.item.medicine,
      unitPrice: widget.item.price,
    );

    if (mounted) {
      setState(() {
        _availableQuantity = (_availableQuantity - _quantity).clamp(0, 999999);
        _isLoading = false;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReservationPassScreen(reservation: reservation),
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.item.medicine;
    final pharma = widget.item.pharmacy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? PharmaTheme.darkSurface : Colors.white;
    final borderColor = isDark ? PharmaTheme.darkBorder : const Color(0xFFE2E8F0);
    final qtyBg = isDark ? PharmaTheme.darkSurfaceElevated : PharmaTheme.mintBackground;

    return Scaffold(
      appBar: AppBar(
        title: Text(med.tradeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة رأس الدواء
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          med.tradeName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : PharmaTheme.mintAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'متوفر $_availableQuantity علبة',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    med.scientificName,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Divider(height: 24, color: borderColor),
                  _buildDetailRow('الشكل الصيدلاني والتركيز:', '${med.dosageForm ?? 'أقراص'} - ${med.strength ?? ''}', isDark),
                  if (med.manufacturer != null)
                    _buildDetailRow('الشركة المصنعة:', med.manufacturer!, isDark),
                  if (med.category != null)
                    _buildDetailRow('التصنيف الطبي:', med.category!, isDark),
                  if (med.isPrescriptionRequired)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: PharmaTheme.statusDanger),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'يتطلب وصفة طبية معتمدة عند الاستلام',
                              style: TextStyle(color: PharmaTheme.statusDanger, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // بطاقة الصيدلية المتوفر لديها
            const Text('الصيدلية المحددة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_pharmacy, color: PharmaTheme.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pharma.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharma.address,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (widget.item.distanceKm != null)
                        Text('${widget.item.distanceKm} كم', style: const TextStyle(fontWeight: FontWeight.bold, color: PharmaTheme.primaryGreen)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // خريطة المسار المباشر من موقع المريض إلى الصيدلية
            PharmacyRouteMapWidget(
              pharmacy: pharma,
              distanceKm: widget.item.distanceKm ?? 1.2,
            ),
            const SizedBox(height: 20),

            // محدد الكمية والسعر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: qtyBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? PharmaTheme.darkBorder : PharmaTheme.mintAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سعر العبوة الواحدة:',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted),
                      ),
                      Text(
                        '${widget.item.price.toStringAsFixed(0)} ريال',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF34D399) : PharmaTheme.primaryGreenDark,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: PharmaTheme.primaryGreen,
                      ),
                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _quantity < _availableQuantity ? () => setState(() => _quantity++) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: PharmaTheme.primaryGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // بيانات المستلم / العميل
            const Text('بيانات المستلم (لتسجيل الحجز باسمك)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المستلم / العميل',
                      hintText: 'مثال: يعقوب خالد',
                      prefixIcon: Icon(Icons.person_outline, color: PharmaTheme.primaryGreen),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'رقم هاتف التواصل',
                      hintText: 'مثال: 771234567',
                      prefixIcon: Icon(Icons.phone_outlined, color: PharmaTheme.primaryGreen),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // زر الحجز
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: _isLoading ? null : _reserveMedicine,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('حجز مؤكد الآن (${(_quantity * widget.item.price).toStringAsFixed(0)} ريال)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? const Color(0xFF94A3B8) : PharmaTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
