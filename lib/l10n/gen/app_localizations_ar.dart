// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'تعاون';

  @override
  String get tagline => 'الحاجة اللي ما تحتاجهاش، ممكن يحتاجها واحد آخر';

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get clear => 'مسح';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get loginRequired => 'يجب تسجيل الدخول';

  @override
  String get errTimeout => 'استغرق تسجيل الدخول وقتاً طويلاً، تحقق من شبكتك وحاول مجدداً';

  @override
  String get errBadCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get errEmailInUse => 'هذا البريد الإلكتروني مسجّل مسبقاً';

  @override
  String get errWeakPassword => 'كلمة المرور ضعيفة (6 أحرف على الأقل)';

  @override
  String get errInvalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get errNetwork => 'تعذّر الاتصال بالإنترنت، تحقق من شبكتك';

  @override
  String get errTooMany => 'محاولات كثيرة جداً، حاول لاحقاً';

  @override
  String get errUserDisabled => 'هذا الحساب معطّل، تواصل مع الإدارة';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقع، حاول مرة أخرى';

  @override
  String get errPermission => 'ليست لديك صلاحية لتنفيذ هذه العملية';

  @override
  String get errNotFound => 'لم يتم العثور على البيانات المطلوبة';

  @override
  String get errGeneric => 'حدث خطأ، حاول مرة أخرى';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordMin => 'كلمة المرور (6 أحرف على الأقل)';

  @override
  String get invalidEmailMsg => 'بريد إلكتروني غير صالح';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get enterEmailFirst => 'أدخل بريدك الإلكتروني أولاً';

  @override
  String get resetEmailSent => 'تم إرسال رابط إعادة تعيين كلمة المرور';

  @override
  String get registerTitle => 'إنشاء حساب جديد';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String get weakPasswordMsg => 'كلمة المرور ضعيفة';

  @override
  String get accountCreated => 'تم إنشاء الحساب بنجاح، مرحباً بك!';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabMyListings => 'إعلاناتي';

  @override
  String get tabProfile => 'حسابي';

  @override
  String get addListing => 'إضافة إعلان';

  @override
  String get logoutTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل تريد تسجيل الخروج من حسابك؟';

  @override
  String get logout => 'خروج';

  @override
  String get searchHint => 'ابحث عن إعلان...';

  @override
  String get filterCategory => 'التصنيف';

  @override
  String get filterWilaya => 'الولاية';

  @override
  String get filterCommune => 'البلدية';

  @override
  String get loadingFeed => 'جاري تحميل الإعلانات...';

  @override
  String get noResults => 'لا توجد نتائج مطابقة للبحث';

  @override
  String get emptyFeed => 'لا توجد إعلانات بعد، كن أول من ينشر إعلاناً';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get loadMore => 'المزيد';

  @override
  String get allCategories => 'كل التصنيفات';

  @override
  String get allWilayas => 'كل الولايات';

  @override
  String get allCommunes => 'كل البلديات';

  @override
  String get statusAvailable => 'متاح';

  @override
  String get statusGiven => 'تم التبرع به';

  @override
  String get catClothes => 'ملابس';

  @override
  String get catFurniture => 'أثاث';

  @override
  String get catBooks => 'كتب';

  @override
  String get catElectronics => 'إلكترونيات';

  @override
  String get catSchool => 'أدوات مدرسية';

  @override
  String get catHome => 'أدوات منزلية';

  @override
  String get catKids => 'مستلزمات أطفال';

  @override
  String get catFood => 'مواد غذائية';

  @override
  String get catAid => 'معدات مساعدة';

  @override
  String get catOther => 'أخرى';

  @override
  String get condNew => 'جديد';

  @override
  String get condVeryGood => 'جيد جداً';

  @override
  String get condGood => 'جيد';

  @override
  String get condUsed => 'مستعمل';

  @override
  String get reasonInappropriate => 'محتوى غير مناسب';

  @override
  String get reasonFalseInfo => 'معلومات كاذبة';

  @override
  String get reasonAlreadyObtained => 'الغرض تم الحصول عليه مسبقاً';

  @override
  String get reasonDuplicate => 'إعلان مكرر';

  @override
  String get reasonOther => 'أخرى';

  @override
  String get detailsTitle => 'تفاصيل الإعلان';

  @override
  String get description => 'الوصف';

  @override
  String get ownerLabel => 'صاحب الإعلان';

  @override
  String get showPhone => 'إظهار رقم التواصل';

  @override
  String get noPhone => 'صاحب الإعلان لم يترك رقم هاتف';

  @override
  String get listingNotFound => 'لم يتم العثور على الإعلان';

  @override
  String get report => 'الإبلاغ';

  @override
  String get reportTitle => 'الإبلاغ عن الإعلان';

  @override
  String get reportDescLabel => 'وصف إضافي (اختياري)';

  @override
  String get reportSubmit => 'إرسال البلاغ';

  @override
  String get reportSent => 'تم إرسال البلاغ، شكراً لتعاونك';

  @override
  String get listingTitleLabel => 'عنوان الإعلان';

  @override
  String get titleInvalid => 'أدخل عنواناً واضحاً';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get descriptionHint => 'اذكر حالة الغرض وملاحظات مهمة...';

  @override
  String get descriptionInvalid => 'أدخل وصفاً مختصراً';

  @override
  String get categoryLabel => 'التصنيف';

  @override
  String get categoryInvalid => 'اختر التصنيف';

  @override
  String get conditionLabel => 'الحالة';

  @override
  String get conditionInvalid => 'اختر الحالة';

  @override
  String get wilaya => 'الولاية';

  @override
  String get commune => 'البلدية';

  @override
  String get wilayaInvalid => 'اختر الولاية';

  @override
  String get communeInvalid => 'اختر البلدية';

  @override
  String get phoneLabel => 'رقم هاتف للتواصل (إجباري)';

  @override
  String get phoneHelper => 'لا توجد محادثات داخل التطبيق — سيتواصل معك المعنيون عبر الهاتف';

  @override
  String get phoneRequired => 'رقم الهاتف إجباري — لا توجد محادثات داخل التطبيق';

  @override
  String get phoneInvalid => 'رقم هاتف جزائري غير صالح (مثال: 0550123456)';

  @override
  String get images => 'الصور';

  @override
  String imagesCount(Object count) {
    return '($count/5)';
  }

  @override
  String get processingImages => 'تعذّر معالجة الصور المختارة';

  @override
  String get addImages => 'إضافة صور (حتى 5)';

  @override
  String get changeImages => 'تغيير الصور';

  @override
  String get createListingTitle => 'إضافة إعلان جديد';

  @override
  String get editListingTitle => 'تعديل الإعلان';

  @override
  String get saveChanges => 'حفظ التعديلات';

  @override
  String get publish => 'نشر الإعلان';

  @override
  String get editSaved => 'تم حفظ التعديلات';

  @override
  String get published => 'تم نشر الإعلان بنجاح';

  @override
  String get myListingsEmpty => 'لم تنشر أي إعلان بعد';

  @override
  String get addFirstListing => 'أضف إعلانك الأول';

  @override
  String get edit => 'تعديل';

  @override
  String get markGiven => 'تعليم كـ «تم التبرع به»';

  @override
  String get markAvailable => 'إعادة إلى «متاح»';

  @override
  String get deleteListingTitle => 'حذف الإعلان';

  @override
  String deleteListingBody(String title) {
    return 'هل تريد حذف \"$title\" نهائياً؟';
  }

  @override
  String get listingDeleted => 'تم حذف الإعلان';

  @override
  String get settingsSection => 'الإعدادات';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get themeTitle => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get adminPanel => 'لوحة الإدارة';

  @override
  String get adminPanelSubtitle => 'إدارة الإعلانات والبلاغات والمستخدمين';

  @override
  String get aboutTitle => 'عن تطبيق تعاون';

  @override
  String get aboutBody => 'تطبيق جزائري للتبرع بالغرض الذي لم يعد يُستخدم\nليحتاجه شخص آخر.\nمشروع خيري في ذكرى والدتي - رحمها الله.';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get adminTitle => 'لوحة الإدارة';

  @override
  String get noAdminPermission => 'ليس لديك صلاحية الدخول إلى لوحة الإدارة';

  @override
  String get tabListings => 'الإعلانات';

  @override
  String get tabReports => 'البلاغات';

  @override
  String get tabUsers => 'المستخدمون';

  @override
  String get noListings => 'لا توجد إعلانات';

  @override
  String get noReports => 'لا توجد بلاغات';

  @override
  String get noUsers => 'لا توجد مستخدمين';

  @override
  String reportPrefix(String title) {
    return 'بلاغ: $title';
  }

  @override
  String reportMeta(String reason, String reporter) {
    return 'السبب: $reason • المُبلِّغ: $reporter';
  }
}
