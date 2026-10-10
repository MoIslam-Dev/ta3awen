// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ta3awen';

  @override
  String get tagline => 'What you no longer need, someone else may need';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get loading => 'Loading...';

  @override
  String get loginRequired => 'You must sign in';

  @override
  String get errTimeout => 'Signing in took too long, check your network and try again';

  @override
  String get errBadCredentials => 'Incorrect email or password';

  @override
  String get errEmailInUse => 'This email is already registered';

  @override
  String get errWeakPassword => 'Weak password (at least 6 characters)';

  @override
  String get errInvalidEmail => 'Invalid email';

  @override
  String get errNetwork => 'No internet connection, check your network';

  @override
  String get errTooMany => 'Too many attempts, try again later';

  @override
  String get errUserDisabled => 'This account is disabled, contact support';

  @override
  String get errUnexpected => 'An unexpected error occurred, try again';

  @override
  String get errPermission => 'You don\'t have permission to do this';

  @override
  String get errNotFound => 'Requested data not found';

  @override
  String get errGeneric => 'Something went wrong, try again';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordMin => 'Password (at least 6 characters)';

  @override
  String get invalidEmailMsg => 'Invalid email';

  @override
  String get login => 'Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get enterEmailFirst => 'Enter your email first';

  @override
  String get resetEmailSent => 'Password reset link sent to your email';

  @override
  String get registerTitle => 'Create an account';

  @override
  String get fullName => 'Full name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get weakPasswordMsg => 'Weak password';

  @override
  String get accountCreated => 'Account created successfully, welcome!';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMyListings => 'My listings';

  @override
  String get tabProfile => 'Account';

  @override
  String get addListing => 'Add listing';

  @override
  String get logoutTitle => 'Sign out';

  @override
  String get logoutConfirm => 'Do you want to sign out?';

  @override
  String get logout => 'Sign out';

  @override
  String get searchHint => 'Search listings...';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterWilaya => 'Wilaya';

  @override
  String get filterCommune => 'Commune';

  @override
  String get loadingFeed => 'Loading listings...';

  @override
  String get noResults => 'No matching results';

  @override
  String get emptyFeed => 'No listings yet — be the first to post one';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get loadMore => 'More';

  @override
  String get allCategories => 'All categories';

  @override
  String get allWilayas => 'All wilayas';

  @override
  String get allCommunes => 'All communes';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusGiven => 'Donated';

  @override
  String get catClothes => 'Clothes';

  @override
  String get catFurniture => 'Furniture';

  @override
  String get catBooks => 'Books';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catSchool => 'School supplies';

  @override
  String get catHome => 'Home goods';

  @override
  String get catKids => 'Baby & kids';

  @override
  String get catFood => 'Food';

  @override
  String get catAid => 'Assistance equipment';

  @override
  String get catOther => 'Other';

  @override
  String get condNew => 'New';

  @override
  String get condVeryGood => 'Very good';

  @override
  String get condGood => 'Good';

  @override
  String get condUsed => 'Used';

  @override
  String get reasonInappropriate => 'Inappropriate content';

  @override
  String get reasonFalseInfo => 'False information';

  @override
  String get reasonAlreadyObtained => 'Item already obtained';

  @override
  String get reasonDuplicate => 'Duplicate listing';

  @override
  String get reasonOther => 'Other';

  @override
  String get detailsTitle => 'Listing details';

  @override
  String get description => 'Description';

  @override
  String get ownerLabel => 'Listing owner';

  @override
  String get showPhone => 'Show contact number';

  @override
  String get noPhone => 'The owner did not leave a phone number';

  @override
  String get listingNotFound => 'Listing not found';

  @override
  String get report => 'Report';

  @override
  String get reportTitle => 'Report this listing';

  @override
  String get reportDescLabel => 'Additional description (optional)';

  @override
  String get reportSubmit => 'Send report';

  @override
  String get reportSent => 'Report sent, thank you for helping';

  @override
  String get listingTitleLabel => 'Listing title';

  @override
  String get titleInvalid => 'Enter a clear title';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Describe the item\'s condition and any important notes...';

  @override
  String get descriptionInvalid => 'Enter a short description';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryInvalid => 'Choose a category';

  @override
  String get conditionLabel => 'Condition';

  @override
  String get conditionInvalid => 'Choose a condition';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get commune => 'Commune';

  @override
  String get wilayaInvalid => 'Choose a wilaya';

  @override
  String get communeInvalid => 'Choose a commune';

  @override
  String get phoneLabel => 'Contact phone (required)';

  @override
  String get phoneHelper => 'No in-app chat — interested people will call you';

  @override
  String get phoneRequired => 'Phone is required — there is no in-app chat';

  @override
  String get phoneInvalid => 'Invalid Algerian number (e.g. 0550123456)';

  @override
  String get images => 'Photos';

  @override
  String imagesCount(Object count) {
    return '($count/5)';
  }

  @override
  String get processingImages => 'Could not process the selected images';

  @override
  String get addImages => 'Add photos (up to 5)';

  @override
  String get changeImages => 'Change photos';

  @override
  String get createListingTitle => 'New listing';

  @override
  String get editListingTitle => 'Edit listing';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get publish => 'Publish';

  @override
  String get editSaved => 'Changes saved';

  @override
  String get published => 'Listing published successfully';

  @override
  String get myListingsEmpty => 'You haven\'t posted a listing yet';

  @override
  String get addFirstListing => 'Add my first listing';

  @override
  String get edit => 'Edit';

  @override
  String get markGiven => 'Mark as \"Donated\"';

  @override
  String get markAvailable => 'Set back to \"Available\"';

  @override
  String get deleteListingTitle => 'Delete listing';

  @override
  String deleteListingBody(String title) {
    return 'Do you want to permanently delete \"$title\"?';
  }

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String get settingsSection => 'Settings';

  @override
  String get languageTitle => 'Language';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get adminPanelSubtitle => 'Manage listings, reports and users';

  @override
  String get aboutTitle => 'About Ta3awen';

  @override
  String get aboutBody => 'An Algerian app for giving away something you no longer use\nto someone who needs it.\nA charity project in memory of my mother — may God have mercy on her.';

  @override
  String get logoutButton => 'Sign out';

  @override
  String get adminTitle => 'Admin panel';

  @override
  String get noAdminPermission => 'You don\'t have access to the admin panel';

  @override
  String get tabListings => 'Listings';

  @override
  String get tabReports => 'Reports';

  @override
  String get tabUsers => 'Users';

  @override
  String get noListings => 'No listings';

  @override
  String get noReports => 'No reports';

  @override
  String get noUsers => 'No users';

  @override
  String reportPrefix(String title) {
    return 'Report: $title';
  }

  @override
  String reportMeta(String reason, String reporter) {
    return 'Reason: $reason • By: $reporter';
  }

  @override
  String get statusReserved => 'Reserved';

  @override
  String get claimRequest => 'Reserve this listing';

  @override
  String get claimCancel => 'Cancel my reservation';

  @override
  String get claimRelease => 'Release reservation';

  @override
  String get confirmDelivery => 'Confirm delivery';

  @override
  String get claimSuccess => 'Listing reserved, waiting for the owner';

  @override
  String get claimTaken => 'Someone else already reserved it';

  @override
  String get claimCancelled => 'Reservation cancelled';

  @override
  String get deliveryConfirmed => 'Delivery confirmed';

  @override
  String get myReservations => 'My reservations';

  @override
  String get reservationsEmpty => 'You haven\'t reserved any listing yet';

  @override
  String reservedBy(String name) {
    return 'Reserved by $name';
  }

  @override
  String get tabRequests => 'Requests';

  @override
  String get addRequest => 'Add';

  @override
  String get reqTypeAll => 'All';

  @override
  String get reqTypeNeed => 'I need';

  @override
  String get reqTypeOffer => 'I can offer';

  @override
  String get reqTypeLabel => 'Request type';

  @override
  String get reqTitleNeed => 'What do you need?';

  @override
  String get reqTitleOffer => 'What can you offer?';

  @override
  String get reqDescNeed => 'Details: what exactly you need, quantity, and when...';

  @override
  String get reqDescOffer => 'Details: what you can offer, quantity, and when it can be handed over...';

  @override
  String get reqTypeInvalid => 'Choose a request type';

  @override
  String get reqStatusOpen => 'Open';

  @override
  String get reqStatusMatched => 'Matched';

  @override
  String get reqStatusClosed => 'Closed';

  @override
  String get reqCreateTitle => 'New request';

  @override
  String get reqEditTitle => 'Edit request';

  @override
  String get reqPublished => 'Request published successfully';

  @override
  String get reqSearchHint => 'Search requests...';

  @override
  String get reqSegmentBoard => 'Board';

  @override
  String get reqSegmentMine => 'My requests';

  @override
  String get reqEmptyBoard => 'No open requests right now';

  @override
  String get reqEmptyMine => 'You haven\'t posted any request yet';

  @override
  String get reqAddFirst => 'Post your first request';

  @override
  String reqMatchedBy(String name) {
    return 'Matched with $name';
  }

  @override
  String get reqDetailsTitle => 'Request details';

  @override
  String get reqNotFound => 'Request not found';

  @override
  String get reqAuthor => 'Request author';

  @override
  String get reqMatchHelp => 'I\'m interested';

  @override
  String get reqMatchSuccess => 'Matched! Contact the author to arrange the details';

  @override
  String get reqMatchTaken => 'Someone else already answered this request';

  @override
  String get reqWithdrawMatch => 'Withdraw';

  @override
  String get reqMatchWithdrawn => 'Withdrawn, the request is open again';

  @override
  String get reqReleaseMatch => 'Release match';

  @override
  String get reqFinalizeMatch => 'Mark as completed';

  @override
  String get reqMatchReleased => 'Request reopened';

  @override
  String get reqMatchFinalized => 'Request completed successfully';

  @override
  String get reqMatchedWithYou => 'Matched with you';

  @override
  String reqMatchedByUser(String name) {
    return 'Answered by: $name';
  }

  @override
  String get reqReopen => 'Reopen request';

  @override
  String get reqClose => 'Close request';

  @override
  String get reqClosed => 'Request closed';

  @override
  String get reqReopened => 'The request is open again';

  @override
  String get reqDeleteTitle => 'Delete request';

  @override
  String reqDeleteBody(String title) {
    return 'Do you want to permanently delete \"$title\"?';
  }

  @override
  String get reqDeleted => 'Request deleted';

  @override
  String get reqKindBlood => 'Blood';

  @override
  String get reqBloodTypeLabel => 'Blood type';

  @override
  String get reqBloodTypeInvalid => 'Choose a blood type from the list';

  @override
  String get reqBloodEmpty => 'No open blood donation requests';

  @override
  String get reqAddBlood => 'Post a blood request';

  @override
  String get reqBloodTitle => 'What blood type do you need?';

  @override
  String get reqBloodDesc => 'Mention the hospital and when the blood is needed (surgery, illness, injury...)';

  @override
  String get catBlood => 'Blood donation';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get statDisabledUsers => 'Disabled users';

  @override
  String get statListingsAvailable => 'Available';

  @override
  String get statListingsReserved => 'Reserved';

  @override
  String get statListingsGiven => 'Given';

  @override
  String get statReportsOpen => 'Open reports';

  @override
  String get statRequestsOpen => 'Open requests';

  @override
  String get statRequestsMatched => 'Matched';

  @override
  String get statBloodRequests => 'Blood requests';

  @override
  String get seedCleanupTitle => 'Demo data';

  @override
  String seedCleanupBody(int count) {
    return 'Remove $count demo listing(s) created for testing (seed-*)';
  }

  @override
  String get seedCleanupNone => 'No demo listings found';

  @override
  String get seedCleanupAction => 'Remove demo listings';

  @override
  String seedCleanupDone(int count) {
    return '$count demo listing(s) removed';
  }

  @override
  String get reportStatusOpen => 'Open';

  @override
  String get reportStatusResolved => 'Resolved';

  @override
  String get reportStatusDismissed => 'Dismissed';

  @override
  String get reportFilterAll => 'All';

  @override
  String get reportOpenListing => 'Open listing';

  @override
  String get reportListingMissing => 'The listing no longer exists';

  @override
  String get reportResolve => 'Resolve';

  @override
  String get reportDismiss => 'Dismiss';

  @override
  String get reportDeleteContent => 'Delete content';

  @override
  String get reportDeleteContentTitle => 'Delete reported listing?';

  @override
  String reportDeleteContentBody(String title) {
    return '\"$title\" will be permanently deleted and the report marked resolved.';
  }

  @override
  String get reportResolvedToast => 'Report resolved';

  @override
  String get reportDismissedToast => 'Report dismissed';

  @override
  String get adminSearchListings => 'Search title, owner, wilaya...';

  @override
  String get adminSearchUsers => 'Search name, email, wilaya...';

  @override
  String get emptySearchResults => 'No results';

  @override
  String get userDetailPhone => 'Phone';

  @override
  String get userDetailLocation => 'Location';

  @override
  String get userDetailJoined => 'Joined';

  @override
  String get userDetailDisabledReason => 'Disable reason';

  @override
  String userListingsCount(int count) {
    return '$count listings';
  }

  @override
  String userReportsFiled(int count) {
    return '$count reports filed';
  }

  @override
  String userReportsAgainst(int count) {
    return '$count reports on their content';
  }

  @override
  String get disableUserTitle => 'Disable account';

  @override
  String get disableReasonHint => 'Reason (optional)';

  @override
  String get disableAction => 'Disable';

  @override
  String get enableAction => 'Enable';

  @override
  String get userEnabledToast => 'Account enabled';

  @override
  String get userDisabledToast => 'Account disabled';

  @override
  String get noRequests => 'No requests';

  @override
  String get reqKindGeneralLabel => 'General';

  @override
  String get errorGeneric => 'Something went wrong';
}
