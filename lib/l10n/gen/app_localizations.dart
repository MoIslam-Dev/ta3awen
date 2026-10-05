import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'تعاون'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In ar, this message translates to:
  /// **'الحاجة اللي ما تحتاجهاش، ممكن يحتاجها واحد آخر'**
  String get tagline;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'موافق'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clear;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل...'**
  String get loading;

  /// No description provided for @loginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول'**
  String get loginRequired;

  /// No description provided for @errTimeout.
  ///
  /// In ar, this message translates to:
  /// **'استغرق تسجيل الدخول وقتاً طويلاً، تحقق من شبكتك وحاول مجدداً'**
  String get errTimeout;

  /// No description provided for @errBadCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة'**
  String get errBadCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد الإلكتروني مسجّل مسبقاً'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة (6 أحرف على الأقل)'**
  String get errWeakPassword;

  /// No description provided for @errInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get errInvalidEmail;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالإنترنت، تحقق من شبكتك'**
  String get errNetwork;

  /// No description provided for @errTooMany.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة جداً، حاول لاحقاً'**
  String get errTooMany;

  /// No description provided for @errUserDisabled.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب معطّل، تواصل مع الإدارة'**
  String get errUserDisabled;

  /// No description provided for @errUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع، حاول مرة أخرى'**
  String get errUnexpected;

  /// No description provided for @errPermission.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية لتنفيذ هذه العملية'**
  String get errPermission;

  /// No description provided for @errNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على البيانات المطلوبة'**
  String get errNotFound;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ، حاول مرة أخرى'**
  String get errGeneric;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @passwordMin.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور (6 أحرف على الأقل)'**
  String get passwordMin;

  /// No description provided for @invalidEmailMsg.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get invalidEmailMsg;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccount;

  /// No description provided for @enterEmailFirst.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني أولاً'**
  String get enterEmailFirst;

  /// No description provided for @resetEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط إعادة تعيين كلمة المرور'**
  String get resetEmailSent;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get registerTitle;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك الكامل'**
  String get enterFullName;

  /// No description provided for @weakPasswordMsg.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور ضعيفة'**
  String get weakPasswordMsg;

  /// No description provided for @accountCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الحساب بنجاح، مرحباً بك!'**
  String get accountCreated;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabMyListings.
  ///
  /// In ar, this message translates to:
  /// **'إعلاناتي'**
  String get tabMyListings;

  /// No description provided for @tabProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabProfile;

  /// No description provided for @addListing.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إعلان'**
  String get addListing;

  /// No description provided for @logoutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حسابك؟'**
  String get logoutConfirm;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get logout;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن إعلان...'**
  String get searchHint;

  /// No description provided for @filterCategory.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get filterCategory;

  /// No description provided for @filterWilaya.
  ///
  /// In ar, this message translates to:
  /// **'الولاية'**
  String get filterWilaya;

  /// No description provided for @filterCommune.
  ///
  /// In ar, this message translates to:
  /// **'البلدية'**
  String get filterCommune;

  /// No description provided for @loadingFeed.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل الإعلانات...'**
  String get loadingFeed;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة للبحث'**
  String get noResults;

  /// No description provided for @emptyFeed.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات بعد، كن أول من ينشر إعلاناً'**
  String get emptyFeed;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح عوامل التصفية'**
  String get clearFilters;

  /// No description provided for @loadMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get loadMore;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'كل التصنيفات'**
  String get allCategories;

  /// No description provided for @allWilayas.
  ///
  /// In ar, this message translates to:
  /// **'كل الولايات'**
  String get allWilayas;

  /// No description provided for @allCommunes.
  ///
  /// In ar, this message translates to:
  /// **'كل البلديات'**
  String get allCommunes;

  /// No description provided for @statusAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get statusAvailable;

  /// No description provided for @statusGiven.
  ///
  /// In ar, this message translates to:
  /// **'تم التبرع به'**
  String get statusGiven;

  /// No description provided for @catClothes.
  ///
  /// In ar, this message translates to:
  /// **'ملابس'**
  String get catClothes;

  /// No description provided for @catFurniture.
  ///
  /// In ar, this message translates to:
  /// **'أثاث'**
  String get catFurniture;

  /// No description provided for @catBooks.
  ///
  /// In ar, this message translates to:
  /// **'كتب'**
  String get catBooks;

  /// No description provided for @catElectronics.
  ///
  /// In ar, this message translates to:
  /// **'إلكترونيات'**
  String get catElectronics;

  /// No description provided for @catSchool.
  ///
  /// In ar, this message translates to:
  /// **'أدوات مدرسية'**
  String get catSchool;

  /// No description provided for @catHome.
  ///
  /// In ar, this message translates to:
  /// **'أدوات منزلية'**
  String get catHome;

  /// No description provided for @catKids.
  ///
  /// In ar, this message translates to:
  /// **'مستلزمات أطفال'**
  String get catKids;

  /// No description provided for @catFood.
  ///
  /// In ar, this message translates to:
  /// **'مواد غذائية'**
  String get catFood;

  /// No description provided for @catAid.
  ///
  /// In ar, this message translates to:
  /// **'معدات مساعدة'**
  String get catAid;

  /// No description provided for @catOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get catOther;

  /// No description provided for @condNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get condNew;

  /// No description provided for @condVeryGood.
  ///
  /// In ar, this message translates to:
  /// **'جيد جداً'**
  String get condVeryGood;

  /// No description provided for @condGood.
  ///
  /// In ar, this message translates to:
  /// **'جيد'**
  String get condGood;

  /// No description provided for @condUsed.
  ///
  /// In ar, this message translates to:
  /// **'مستعمل'**
  String get condUsed;

  /// No description provided for @reasonInappropriate.
  ///
  /// In ar, this message translates to:
  /// **'محتوى غير مناسب'**
  String get reasonInappropriate;

  /// No description provided for @reasonFalseInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات كاذبة'**
  String get reasonFalseInfo;

  /// No description provided for @reasonAlreadyObtained.
  ///
  /// In ar, this message translates to:
  /// **'الغرض تم الحصول عليه مسبقاً'**
  String get reasonAlreadyObtained;

  /// No description provided for @reasonDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'إعلان مكرر'**
  String get reasonDuplicate;

  /// No description provided for @reasonOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get reasonOther;

  /// No description provided for @detailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإعلان'**
  String get detailsTitle;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @ownerLabel.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الإعلان'**
  String get ownerLabel;

  /// No description provided for @showPhone.
  ///
  /// In ar, this message translates to:
  /// **'إظهار رقم التواصل'**
  String get showPhone;

  /// No description provided for @noPhone.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الإعلان لم يترك رقم هاتف'**
  String get noPhone;

  /// No description provided for @listingNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على الإعلان'**
  String get listingNotFound;

  /// No description provided for @report.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ'**
  String get report;

  /// No description provided for @reportTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن الإعلان'**
  String get reportTitle;

  /// No description provided for @reportDescLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف إضافي (اختياري)'**
  String get reportDescLabel;

  /// No description provided for @reportSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get reportSubmit;

  /// No description provided for @reportSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ، شكراً لتعاونك'**
  String get reportSent;

  /// No description provided for @listingTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإعلان'**
  String get listingTitleLabel;

  /// No description provided for @titleInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنواناً واضحاً'**
  String get titleInvalid;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اذكر حالة الغرض وملاحظات مهمة...'**
  String get descriptionHint;

  /// No description provided for @descriptionInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل وصفاً مختصراً'**
  String get descriptionInvalid;

  /// No description provided for @categoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get categoryLabel;

  /// No description provided for @categoryInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اختر التصنيف'**
  String get categoryInvalid;

  /// No description provided for @conditionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get conditionLabel;

  /// No description provided for @conditionInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اختر الحالة'**
  String get conditionInvalid;

  /// No description provided for @wilaya.
  ///
  /// In ar, this message translates to:
  /// **'الولاية'**
  String get wilaya;

  /// No description provided for @commune.
  ///
  /// In ar, this message translates to:
  /// **'البلدية'**
  String get commune;

  /// No description provided for @wilayaInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اختر الولاية'**
  String get wilayaInvalid;

  /// No description provided for @communeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'اختر البلدية'**
  String get communeInvalid;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف للتواصل (إجباري)'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد محادثات داخل التطبيق — سيتواصل معك المعنيون عبر الهاتف'**
  String get phoneHelper;

  /// No description provided for @phoneRequired.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف إجباري — لا توجد محادثات داخل التطبيق'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف جزائري غير صالح (مثال: 0550123456)'**
  String get phoneInvalid;

  /// No description provided for @images.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get images;

  /// No description provided for @imagesCount.
  ///
  /// In ar, this message translates to:
  /// **'({count}/5)'**
  String imagesCount(Object count);

  /// No description provided for @processingImages.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر معالجة الصور المختارة'**
  String get processingImages;

  /// No description provided for @addImages.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صور (حتى 5)'**
  String get addImages;

  /// No description provided for @changeImages.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصور'**
  String get changeImages;

  /// No description provided for @createListingTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إعلان جديد'**
  String get createListingTitle;

  /// No description provided for @editListingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإعلان'**
  String get editListingTitle;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @publish.
  ///
  /// In ar, this message translates to:
  /// **'نشر الإعلان'**
  String get publish;

  /// No description provided for @editSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التعديلات'**
  String get editSaved;

  /// No description provided for @published.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الإعلان بنجاح'**
  String get published;

  /// No description provided for @myListingsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تنشر أي إعلان بعد'**
  String get myListingsEmpty;

  /// No description provided for @addFirstListing.
  ///
  /// In ar, this message translates to:
  /// **'أضف إعلانك الأول'**
  String get addFirstListing;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @markGiven.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كـ «تم التبرع به»'**
  String get markGiven;

  /// No description provided for @markAvailable.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إلى «متاح»'**
  String get markAvailable;

  /// No description provided for @deleteListingTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإعلان'**
  String get deleteListingTitle;

  /// No description provided for @deleteListingBody.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف \"{title}\" نهائياً؟'**
  String deleteListingBody(String title);

  /// No description provided for @listingDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الإعلان'**
  String get listingDeleted;

  /// No description provided for @settingsSection.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsSection;

  /// No description provided for @languageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageTitle;

  /// No description provided for @themeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeTitle;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'حسب النظام'**
  String get themeSystem;

  /// No description provided for @adminPanel.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminPanel;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الإعلانات والبلاغات والمستخدمين'**
  String get adminPanelSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن تطبيق تعاون'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق جزائري للتبرع بالغرض الذي لم يعد يُستخدم\nليحتاجه شخص آخر.\nمشروع خيري في ذكرى والدتي - رحمها الله.'**
  String get aboutBody;

  /// No description provided for @logoutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutButton;

  /// No description provided for @adminTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminTitle;

  /// No description provided for @noAdminPermission.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية الدخول إلى لوحة الإدارة'**
  String get noAdminPermission;

  /// No description provided for @tabListings.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get tabListings;

  /// No description provided for @tabReports.
  ///
  /// In ar, this message translates to:
  /// **'البلاغات'**
  String get tabReports;

  /// No description provided for @tabUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get tabUsers;

  /// No description provided for @noListings.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات'**
  String get noListings;

  /// No description provided for @noReports.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات'**
  String get noReports;

  /// No description provided for @noUsers.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستخدمين'**
  String get noUsers;

  /// No description provided for @reportPrefix.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ: {title}'**
  String reportPrefix(String title);

  /// No description provided for @reportMeta.
  ///
  /// In ar, this message translates to:
  /// **'السبب: {reason} • المُبلِّغ: {reporter}'**
  String reportMeta(String reason, String reporter);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
