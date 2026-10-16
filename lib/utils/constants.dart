/// Default page size for every paginated database read. Small enough to
/// keep the read budget healthy, large enough to fill a screen.
const int kPageSize = 20;

const List<String> kCategories = [
  'ملابس',
  'أثاث',
  'كتب',
  'إلكترونيات',
  'أدوات مدرسية',
  'أدوات منزلية',
  'مستلزمات أطفال',
  'مواد غذائية',
  'معدات مساعدة',
  'أخرى',
];

const List<String> kConditions = ['جديد', 'جيد جداً', 'جيد', 'مستعمل'];

/// Blood donation board: the 8 blood type designations, stored in Latin
/// script (universal in Algerian medical context).
const List<String> kBloodTypes = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

/// Storage value of the fixed category on blood posts.
const String kBloodCategory = 'التبرع بالدم';

const List<String> kReportReasons = [
  'محتوى غير مناسب',
  'معلومات كاذبة',
  'الغرض تم الحصول عليه مسبقاً',
  'إعلان مكرر',
  'أخرى',
];
