// المكسين (Mixins) وفق مفاهيم المحاضرة الرابعة:
// - استخدام الكلمة المفتاحية mixin لإعادة استخدام السلوكيات عبر الشاشات المختلفة
// - دمج السلوكيات عبر الكلمة المفتاحية with دون الدخول في مشاكل الوراثة المتعددة

/// مكسين مخصص للتحقق من صحة مدخلات النماذج وصناديق الحقول
mixin FormValidatorMixin {
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'حقل $fieldName مطلوب ولا يمكن تركه فارغاً';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final clean = value.replaceAll(RegExp(r'\s+|-'), '');
    if (!RegExp(r'^(\+?967|0)?7[0-9]{8}$').hasMatch(clean)) {
      return 'يرجى إدخال رقم هاتف يمني صحيح (مثال: 770123456)';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'السعر مطلوب';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price <= 0) {
      return 'يرجى إدخال قيمة سعرية صحيحة أكبر من الصفر';
    }
    return null;
  }

  String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الكمية مطلوبة';
    }
    final qty = int.tryParse(value.trim());
    if (qty == null || qty <= 0) {
      return 'يرجى إدخال كمية صحيحة';
    }
    return null;
  }
}

/// مكسين مخصص لتنسيق العملات والمسافات والنصوص الطبية
mixin CurrencyFormatterMixin {
  String formatYemeniRial(num amount) {
    return '${amount.toStringAsFixed(amount is int || amount % 1 == 0 ? 0 : 2)} ر.ي';
  }

  String formatDistance(double? meters) {
    if (meters == null) return 'المسافة غير محددة';
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} متر';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} كم';
  }
}
