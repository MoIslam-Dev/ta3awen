String authErrorMessage(Object error) {
  final code = error.toString();
  if (code.contains('user-not-found') ||
      code.contains('wrong-password') ||
      code.contains('invalid-credential')) {
    return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
  }
  if (code.contains('email-already-in-use')) {
    return 'هذا البريد الإلكتروني مسجّل مسبقاً';
  }
  if (code.contains('weak-password')) {
    return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
  }
  if (code.contains('invalid-email')) {
    return 'بريد إلكتروني غير صالح';
  }
  if (code.contains('network-request-failed')) {
    return 'تعذّر الاتصال بالإنترنت، تحقق من شبكتك';
  }
  if (code.contains('too-many-requests')) {
    return 'محاولات كثيرة جداً، حاول لاحقاً';
  }
  if (code.contains('user-disabled')) {
    return 'هذا الحساب معطّل، تواصل مع الإدارة';
  }
  return 'حدث خطأ غير متوقع، حاول مرة أخرى';
}

String dataErrorMessage(Object error) {
  final code = error.toString();
  if (code.contains('permission-denied')) {
    return 'ليست لديك صلاحية لتنفيذ هذه العملية';
  }
  if (code.contains('unavailable') ||
      code.contains('network') ||
      code.contains('failed')) {
    return 'تعذّر الاتصال بالإنترنت، تحقق من شبكتك';
  }
  if (code.contains('not-found')) {
    return 'لم يتم العثور على البيانات المطلوبة';
  }
  return 'حدث خطأ، حاول مرة أخرى';
}
