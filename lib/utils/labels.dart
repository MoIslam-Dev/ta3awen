import 'package:flutter/material.dart';
import '../l10n/ext.dart';

/// Maps stored (Arabic) data values to localized display labels.
///
/// The stored values in Firestore never change with the UI language —
/// only their presentation is localized.

String categoryLabel(BuildContext context, String storage) {
  switch (storage) {
    case 'ملابس':
      return context.l10n.catClothes;
    case 'أثاث':
      return context.l10n.catFurniture;
    case 'كتب':
      return context.l10n.catBooks;
    case 'إلكترونيات':
      return context.l10n.catElectronics;
    case 'أدوات مدرسية':
      return context.l10n.catSchool;
    case 'أدوات منزلية':
      return context.l10n.catHome;
    case 'مستلزمات أطفال':
      return context.l10n.catKids;
    case 'مواد غذائية':
      return context.l10n.catFood;
    case 'معدات مساعدة':
      return context.l10n.catAid;
    case 'أخرى':
      return context.l10n.catOther;
    default:
      return storage;
  }
}

String conditionLabel(BuildContext context, String storage) {
  switch (storage) {
    case 'جديد':
      return context.l10n.condNew;
    case 'جيد جداً':
      return context.l10n.condVeryGood;
    case 'جيد':
      return context.l10n.condGood;
    case 'مستعمل':
      return context.l10n.condUsed;
    default:
      return storage;
  }
}

String statusLabel(BuildContext context, String storage) {
  switch (storage) {
    case 'متاح':
      return context.l10n.statusAvailable;
    case 'تم التبرع به':
      return context.l10n.statusGiven;
    default:
      return storage;
  }
}

String reportReasonLabel(BuildContext context, String storage) {
  switch (storage) {
    case 'محتوى غير مناسب':
      return context.l10n.reasonInappropriate;
    case 'معلومات كاذبة':
      return context.l10n.reasonFalseInfo;
    case 'الغرض تم الحصول عليه مسبقاً':
      return context.l10n.reasonAlreadyObtained;
    case 'إعلان مكرر':
      return context.l10n.reasonDuplicate;
    case 'أخرى':
      return context.l10n.reasonOther;
    default:
      return storage;
  }
}
