import 'package:flutter/material.dart';
import '../l10n/ext.dart';
import '../models/listing.dart';
import '../models/request_post.dart';

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
    case 'التبرع بالدم':
      return context.l10n.catBlood;
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
    case 'محجوز':
      return context.l10n.statusReserved;
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

/// Listing nature badge: free donation vs barter/exchange.
String listingKindLabel(BuildContext context, String kind) {
  switch (kind) {
    case listingKindExchange:
      return context.l10n.giveExchange;
    default:
      return context.l10n.giveDonate;
  }
}

String requestTypeLabel(BuildContext context, String type) {
  switch (type) {
    case requestTypeNeed:
      return context.l10n.reqTypeNeed;
    case requestTypeOffer:
      return context.l10n.reqTypeOffer;
    default:
      return type;
  }
}

String requestStatusLabel(BuildContext context, String status) {
  switch (status) {
    case requestStatusOpen:
      return context.l10n.reqStatusOpen;
    case requestStatusMatched:
      return context.l10n.reqStatusMatched;
    case requestStatusClosed:
      return context.l10n.reqStatusClosed;
    default:
      return status;
  }
}

/// What the author is asking for, which drives the wording of the "I can…"
/// action on the board: a need expects help, an offer expects someone who
/// wants the item, a blood post expects a donor.
enum RequestMatchIntent { need, offer, blood }

RequestMatchIntent requestMatchIntent(RequestPost post) {
  if (post.isBlood) return RequestMatchIntent.blood;
  return post.type == requestTypeNeed
      ? RequestMatchIntent.need
      : RequestMatchIntent.offer;
}

String requestMatchHelpLabel(BuildContext context, RequestPost post) {
  switch (requestMatchIntent(post)) {
    case RequestMatchIntent.need:
      return context.l10n.reqMatchHelpNeed;
    case RequestMatchIntent.offer:
      return context.l10n.reqMatchHelpOffer;
    case RequestMatchIntent.blood:
      return context.l10n.reqMatchHelpBlood;
  }
}

String requestMatchSuccessLabel(BuildContext context, RequestPost post) {
  switch (requestMatchIntent(post)) {
    case RequestMatchIntent.need:
      return context.l10n.reqMatchSuccessNeed;
    case RequestMatchIntent.offer:
      return context.l10n.reqMatchSuccessOffer;
    case RequestMatchIntent.blood:
      return context.l10n.reqMatchSuccessBlood;
  }
}
