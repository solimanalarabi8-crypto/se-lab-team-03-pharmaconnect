// التعدادات البرمجية (Enums) وفق مفاهيم المحاضرة الرابعة والعاشرة:
// - حصر الخيارات بقيم ثابتة ومنع الأخطاء الإملائية
// - معالجة القيم بجمل switch شاملة ودقيقة
// - الربط المباشر مع أدوات الاختيار (DropdownButton, RadioListTile)

/// تصنيفات الأدوية الطبية المعتمدة
enum MedicineCategory {
  all('الكل', 'جميع الأصناف والأدوية'),
  antibiotics('مضادات حيوية', 'مضادات البكتيريا والالتهابات'),
  analgesics('مسكنات وخافض حرارة', 'تسكين الآلام وتخفيف الحمى'),
  chronic('أدوية الأمراض المزمنة', 'الضغط، السكري، والقلب'),
  vitamins('فيتامينات ومكملات', 'المقويات والمعادن الغذائية'),
  digestive('أدوية الجهاز الهضمي', 'المعدة، القولون، والحموضة');

  final String label;
  final String description;
  const MedicineCategory(this.label, this.description);
}

/// خيارات فرز وترتيب نتائج الأدوية (تُستخدم مع أزرار الراديو RadioListTile)
enum MedicineSortOption {
  nearest('الأقرب جغرافياً', 'ترتيب حسب أقرب صيدلية لموقعك الحالي'),
  lowestPrice('الأقل سعراً', 'ترتيب تصاعدي حسب سعر الدواء'),
  highestStock('الأكثر وفرة بالمخزون', 'ترتيب حسب الكميات المتاحة في الصيدليات'),
  alphabetical('أبجدياً (أ - ي)', 'ترتيب حسب الاسم التجاري للدواء');

  final String label;
  final String subtitle;
  const MedicineSortOption(this.label, this.subtitle);
}

/// خيارات طريقة استلام الدواء المحجوز (تُستخدم مع RadioListTile و Checkbox)
enum ReservationDeliveryType {
  pharmacyPickup('استلام حضوري من الصيدلية', 'الحضور الشخصي للصيدلية وإبراز رمز الحجز'),
  expressHold('حجز عاجل مؤكد (VIP)', 'تجميد وحجز العلبة بالاسم لمدة ساعتين كاملتين');

  final String title;
  final String details;
  const ReservationDeliveryType(this.title, this.details);
}

/// حالة الدواء المحفوظ محلياً في قاعدة بيانات SQFlite
enum LocalMedicineStatus {
  active('نشط في المفضلة'),
  purchased('تم شراؤه سابقاً'),
  neededUrgent('مطلوب عاجلاً');

  final String title;
  const LocalMedicineStatus(this.title);
}
