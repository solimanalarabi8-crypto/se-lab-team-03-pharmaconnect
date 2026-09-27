/// كلاسات استثناءات مخصصة مبنية وفق مفاهيم المحاضرة الرابعة:
/// - الأصناف المجردة (Abstract Classes)
/// - الواجهات البرمجية والعقود (implements Exception)
/// - التغليف وتمرير البيانات للـ Superclass
/// - تعدد الأشكال والتجاوز (@override)
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    if (code != null) {
      return '[$code] $message';
    }
    return message;
  }
}

/// استثناء أخطاء الشبكة والاتصال بالخادم المركزي (Laravel API)
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code = 'NETWORK_ERROR',
    super.details,
  });
}

/// استثناء أخطاء قاعدة البيانات المحلية (SQFlite)
class AppDatabaseException extends AppException {
  final String? query;

  const AppDatabaseException(
    super.message, {
    this.query,
    super.code = 'DATABASE_ERROR',
    super.details,
  });
}

/// استثناء أخطاء التحقق من صحة المدخلات والحقول
class ValidationException extends AppException {
  final String? field;

  const ValidationException(
    super.message, {
    this.field,
    super.code = 'VALIDATION_ERROR',
    super.details,
  });
}

/// استثناء أخطاء المصادقة والصلاحيات
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code = 'AUTH_ERROR',
    super.details,
  });
}
