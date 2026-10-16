// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Ta3awen';

  @override
  String get tagline => 'La chose dont tu n\'as plus besoin, quelqu\'un d\'autre en a peut-être besoin';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get retry => 'Réessayer';

  @override
  String get clear => 'Effacer';

  @override
  String get loading => 'Chargement...';

  @override
  String get loginRequired => 'Vous devez vous connecter';

  @override
  String get errTimeout => 'La connexion a pris trop de temps, vérifiez votre réseau et réessayez';

  @override
  String get errBadCredentials => 'E-mail ou mot de passe incorrect';

  @override
  String get errEmailInUse => 'Cet e-mail est déjà enregistré';

  @override
  String get errWeakPassword => 'Mot de passe faible (6 caractères minimum)';

  @override
  String get errInvalidEmail => 'E-mail invalide';

  @override
  String get errNetwork => 'Impossible de se connecter à Internet, vérifiez votre réseau';

  @override
  String get errTooMany => 'Trop de tentatives, réessayez plus tard';

  @override
  String get errUserDisabled => 'Ce compte est désactivé, contactez l\'administration';

  @override
  String get errUnexpected => 'Une erreur inattendue s\'est produite, réessayez';

  @override
  String get errPermission => 'Vous n\'avez pas la permission d\'effectuer cette opération';

  @override
  String get errNotFound => 'Données introuvables';

  @override
  String get errGeneric => 'Une erreur s\'est produite, réessayez';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordMin => 'Mot de passe (6 caractères minimum)';

  @override
  String get invalidEmailMsg => 'E-mail invalide';

  @override
  String get login => 'Se connecter';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccount => 'Pas de compte ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get enterEmailFirst => 'Saisissez d\'abord votre e-mail';

  @override
  String get resetEmailSent => 'Lien de réinitialisation envoyé par e-mail';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get fullName => 'Nom complet';

  @override
  String get enterFullName => 'Saisissez votre nom complet';

  @override
  String get weakPasswordMsg => 'Mot de passe faible';

  @override
  String get accountCreated => 'Compte créé avec succès, bienvenue !';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get loginHelp => 'Connectez-vous pour voir les demandes et dons près de chez vous';

  @override
  String get registerHelp => 'Créez votre compte en une minute et commencez à aider';

  @override
  String get signInWithGoogle => 'Continuer avec Google';

  @override
  String get orLabel => 'ou';

  @override
  String get passwordConfirm => 'Confirmer le mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordHelper => 'Au moins 6 caractères';

  @override
  String get socialSetupTitle => 'Complétez votre profil';

  @override
  String get socialSetupBody => 'Il nous faut votre nom et votre wilaya pour afficher les annonces près de chez vous';

  @override
  String get socialSetupSave => 'Enregistrer et continuer';

  @override
  String get errAuthCanceled => 'Connexion annulée';

  @override
  String get errProviderDisabled => 'Cette option n\'est pas encore activée, essayez l\'email';

  @override
  String get errProviderConfig => 'Impossible de se connecter à Google, vérifiez la configuration';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabMyListings => 'Mes annonces';

  @override
  String get tabProfile => 'Compte';

  @override
  String get addListing => 'Ajouter';

  @override
  String get logoutTitle => 'Déconnexion';

  @override
  String get logoutConfirm => 'Voulez-vous vous déconnecter ?';

  @override
  String get logout => 'Quitter';

  @override
  String get navGive => 'Donner';

  @override
  String get navAsk => 'Demander';

  @override
  String get navBlood => 'Sang';

  @override
  String get filterAll => 'Tout';

  @override
  String get publishTitle => 'Publier';

  @override
  String get publishDonate => 'Donner un objet';

  @override
  String get publishExchange => 'Échanger un objet';

  @override
  String get publishAsk => 'Demander quelque chose';

  @override
  String get publishBlood => 'Demander du sang (urgent)';

  @override
  String get giveDonate => 'Don';

  @override
  String get giveExchange => 'Échange';

  @override
  String get listingKindLabel => 'Type';

  @override
  String get myListings => 'Mes publications';

  @override
  String get myListingsSubtitle => 'Mes annonces et réservations';

  @override
  String get myRequests => 'Mes demandes';

  @override
  String get myRequestsSubtitle => 'Publications du forum que j\'ai créées';

  @override
  String get searchHint => 'Rechercher une annonce...';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String get filterWilaya => 'Wilaya';

  @override
  String get filterCommune => 'Commune';

  @override
  String get loadingFeed => 'Chargement des annonces...';

  @override
  String get noResults => 'Aucun résultat correspondant';

  @override
  String get emptyFeed => 'Aucune annonce pour le moment, soyez le premier à publier';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get loadMore => 'Plus';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get allWilayas => 'Toutes les wilayas';

  @override
  String get allCommunes => 'Toutes les communes';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusGiven => 'Donné';

  @override
  String get catClothes => 'Vêtements';

  @override
  String get catFurniture => 'Meubles';

  @override
  String get catBooks => 'Livres';

  @override
  String get catElectronics => 'Électronique';

  @override
  String get catSchool => 'Fournitures scolaires';

  @override
  String get catHome => 'Articles ménagers';

  @override
  String get catKids => 'Articles pour bébés';

  @override
  String get catFood => 'Produits alimentaires';

  @override
  String get catAid => 'Équipement d\'assistance';

  @override
  String get catOther => 'Autres';

  @override
  String get condNew => 'Neuf';

  @override
  String get condVeryGood => 'Très bon état';

  @override
  String get condGood => 'Bon état';

  @override
  String get condUsed => 'Usagé';

  @override
  String get reasonInappropriate => 'Contenu inapproprié';

  @override
  String get reasonFalseInfo => 'Informations fausses';

  @override
  String get reasonAlreadyObtained => 'Objet déjà obtenu';

  @override
  String get reasonDuplicate => 'Annonce en double';

  @override
  String get reasonOther => 'Autre';

  @override
  String get detailsTitle => 'Détails de l\'annonce';

  @override
  String get description => 'Description';

  @override
  String get ownerLabel => 'Propriétaire de l\'annonce';

  @override
  String get showPhone => 'Afficher le numéro';

  @override
  String get noPhone => 'Le propriétaire n\'a pas laissé de numéro';

  @override
  String get listingNotFound => 'Annonce introuvable';

  @override
  String get report => 'Signaler';

  @override
  String get reportTitle => 'Signaler cette annonce';

  @override
  String get reportDescLabel => 'Description supplémentaire (facultatif)';

  @override
  String get reportSubmit => 'Envoyer le signalement';

  @override
  String get reportSent => 'Signalement envoyé, merci pour votre aide';

  @override
  String get listingTitleLabel => 'Titre de l\'annonce';

  @override
  String get titleInvalid => 'Saisissez un titre clair';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Décrivez l\'état de l\'objet et les détails importants...';

  @override
  String get descriptionInvalid => 'Saisissez une description courte';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get categoryInvalid => 'Choisissez une catégorie';

  @override
  String get conditionLabel => 'État';

  @override
  String get conditionInvalid => 'Choisissez l\'état';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get commune => 'Commune';

  @override
  String get wilayaInvalid => 'Choisissez la wilaya';

  @override
  String get communeInvalid => 'Choisissez la commune';

  @override
  String get phoneLabel => 'Téléphone (obligatoire)';

  @override
  String get phoneHelper => 'Pas de chat dans l\'app — les intéressés vous appelleront';

  @override
  String get phoneRequired => 'Le téléphone est obligatoire, pas de chat dans l\'app';

  @override
  String get phoneInvalid => 'Numéro algérien invalide (ex. 0550123456)';

  @override
  String get images => 'Photos';

  @override
  String imagesCount(Object count) {
    return '($count/5)';
  }

  @override
  String get processingImages => 'Impossible de traiter les images sélectionnées';

  @override
  String get addImages => 'Ajouter des photos (max 5)';

  @override
  String get changeImages => 'Changer les photos';

  @override
  String get createListingTitle => 'Nouvelle annonce';

  @override
  String get editListingTitle => 'Modifier l\'annonce';

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get publish => 'Publier';

  @override
  String get editSaved => 'Modifications enregistrées';

  @override
  String get published => 'Annonce publiée avec succès';

  @override
  String get myListingsEmpty => 'Vous n\'avez pas encore publié d\'annonce';

  @override
  String get addFirstListing => 'Ajouter ma première annonce';

  @override
  String get edit => 'Modifier';

  @override
  String get markGiven => 'Marquer comme « Donné »';

  @override
  String get markAvailable => 'Remettre « Disponible »';

  @override
  String get deleteListingTitle => 'Supprimer l\'annonce';

  @override
  String deleteListingBody(String title) {
    return 'Voulez-vous supprimer \"$title\" définitivement ?';
  }

  @override
  String get listingDeleted => 'Annonce supprimée';

  @override
  String get settingsSection => 'Paramètres';

  @override
  String get languageTitle => 'Langue';

  @override
  String get themeTitle => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get adminPanel => 'Administration';

  @override
  String get adminPanelSubtitle => 'Gérer annonces, signalements et utilisateurs';

  @override
  String get aboutTitle => 'À propos de Ta3awen';

  @override
  String get aboutBody => 'App algérien pour donner un objet inutilisé\nà quelqu\'un qui en a besoin.\nProjet caritatif en mémoire de ma mère — que Dieu l\'accueille.';

  @override
  String get logoutButton => 'Se déconnecter';

  @override
  String get adminTitle => 'Administration';

  @override
  String get noAdminPermission => 'Vous n\'avez pas accès à l\'administration';

  @override
  String get tabListings => 'Annonces';

  @override
  String get tabReports => 'Signalements';

  @override
  String get tabUsers => 'Utilisateurs';

  @override
  String get noListings => 'Aucune annonce';

  @override
  String get noReports => 'Aucun signalement';

  @override
  String get noUsers => 'Aucun utilisateur';

  @override
  String reportPrefix(String title) {
    return 'Signalement : $title';
  }

  @override
  String reportMeta(String reason, String reporter) {
    return 'Motif : $reason • Par : $reporter';
  }

  @override
  String get statusReserved => 'Réservé';

  @override
  String get claimRequest => 'Réserver cette annonce';

  @override
  String get claimCancel => 'Annuler ma réservation';

  @override
  String get claimRelease => 'Libérer la réservation';

  @override
  String get confirmDelivery => 'Confirmer la remise';

  @override
  String get claimSuccess => 'Annonce réservée, en attente de confirmation';

  @override
  String get claimTaken => 'Un autre utilisateur l\'a déjà réservée';

  @override
  String get claimCancelled => 'Réservation annulée';

  @override
  String get deliveryConfirmed => 'Remise confirmée';

  @override
  String get myReservations => 'Mes réservations';

  @override
  String get reservationsEmpty => 'Vous n\'avez réservé aucune annonce';

  @override
  String reservedBy(String name) {
    return 'Réservé par $name';
  }

  @override
  String get tabRequests => 'Demandes';

  @override
  String get addRequest => 'Ajouter';

  @override
  String get reqTypeAll => 'Tous';

  @override
  String get reqTypeNeed => 'J\'ai besoin';

  @override
  String get reqTypeOffer => 'Je peux offrir';

  @override
  String get reqTypeLabel => 'Type de demande';

  @override
  String get reqTitleNeed => 'De quoi avez-vous besoin ?';

  @override
  String get reqTitleOffer => 'Que pouvez-vous proposer ?';

  @override
  String get reqDescNeed => 'Détails : ce dont vous avez besoin exactement, la quantité, et quand...';

  @override
  String get reqDescOffer => 'Détails : ce que vous pouvez proposer, la quantité, et quand remettre...';

  @override
  String get reqTypeInvalid => 'Choisissez le type de demande';

  @override
  String get reqStatusOpen => 'Ouverte';

  @override
  String get reqStatusMatched => 'Appariée';

  @override
  String get reqStatusClosed => 'Clôturée';

  @override
  String get reqCreateTitle => 'Nouvelle demande';

  @override
  String get reqEditTitle => 'Modifier la demande';

  @override
  String get reqPublished => 'Demande publiée avec succès';

  @override
  String get reqSearchHint => 'Rechercher des demandes...';

  @override
  String get reqSegmentBoard => 'Demandes ouvertes';

  @override
  String get reqSegmentMine => 'Mes demandes';

  @override
  String get reqEmptyBoard => 'Aucune demande ouverte pour le moment';

  @override
  String get reqEmptyMine => 'Vous n\'avez publié aucune demande';

  @override
  String get reqAddFirst => 'Publiez votre première demande';

  @override
  String reqMatchedBy(String name) {
    return 'Apparié avec $name';
  }

  @override
  String get reqDetailsTitle => 'Détails de la demande';

  @override
  String get reqNotFound => 'Demande introuvable';

  @override
  String get reqAuthor => 'Auteur de la demande';

  @override
  String get reqMatchHelpNeed => 'Je peux aider';

  @override
  String get reqMatchHelpOffer => 'Je le veux';

  @override
  String get reqMatchHelpBlood => 'Je peux donner';

  @override
  String get reqMatchSuccessNeed => 'Apparié ! Contactez l\'auteur pour convenir des détails';

  @override
  String get reqMatchSuccessOffer => 'Apparié ! Contactez l\'auteur pour convenir de la remise';

  @override
  String get reqMatchSuccessBlood => 'Apparié ! Contactez l\'auteur pour convenir du don';

  @override
  String get reqMatchedVisibility => 'Ce post n\'apparaîtra plus sur le tableau public des demandes ouvertes tant que l\'appariement est actif';

  @override
  String get reqMatchTaken => 'Quelqu\'un a déjà répondu à cette demande';

  @override
  String get reqWithdrawMatch => 'Se retirer';

  @override
  String get reqMatchWithdrawn => 'Retiré, la demande est de nouveau ouverte';

  @override
  String get reqReleaseMatch => 'Libérer l\'appariement';

  @override
  String get reqFinalizeMatch => 'Marquer comme terminé';

  @override
  String get reqMatchReleased => 'Demande rouverte';

  @override
  String get reqMatchFinalized => 'Demande terminée avec succès';

  @override
  String get reqMatchedWithYou => 'Apparié avec vous';

  @override
  String reqMatchedByUser(String name) {
    return 'Répondu par : $name';
  }

  @override
  String get reqReopen => 'Rouvrir la demande';

  @override
  String get reqClose => 'Clôturer la demande';

  @override
  String get reqClosed => 'Demande clôturée';

  @override
  String get reqReopened => 'La demande est de nouveau ouverte';

  @override
  String get reqDeleteTitle => 'Supprimer la demande';

  @override
  String reqDeleteBody(String title) {
    return 'Voulez-vous supprimer définitivement « $title » ?';
  }

  @override
  String get reqDeleted => 'Demande supprimée';

  @override
  String get reqKindBlood => 'Sang';

  @override
  String get reqBloodTypeLabel => 'Groupe sanguin';

  @override
  String get reqBloodTypeInvalid => 'Choisissez un groupe sanguin dans la liste';

  @override
  String get reqBloodEmpty => 'Aucune demande de don de sang ouverte';

  @override
  String get reqAddBlood => 'Publier une demande de sang';

  @override
  String get reqBloodTitle => 'De quel groupe sanguin avez-vous besoin ?';

  @override
  String get reqBloodDesc => 'Indiquez l\'hôpital et quand le sang est nécessaire (opération, maladie, blessure...)';

  @override
  String get catBlood => 'Don de sang';

  @override
  String get tabDashboard => 'Tableau de bord';

  @override
  String get statDisabledUsers => 'Comptes désactivés';

  @override
  String get statListingsAvailable => 'Disponibles';

  @override
  String get statListingsReserved => 'Réservés';

  @override
  String get statListingsGiven => 'Donnés';

  @override
  String get statReportsOpen => 'Signalements ouverts';

  @override
  String get statRequestsOpen => 'Demandes ouvertes';

  @override
  String get statRequestsMatched => 'Appariées';

  @override
  String get statBloodRequests => 'Demandes de sang';

  @override
  String get seedCleanupTitle => 'Données de démo';

  @override
  String seedCleanupBody(int count) {
    return 'Supprimer $count annonce(s) de démo créée(s) pour les tests (seed-*)';
  }

  @override
  String get seedCleanupNone => 'Aucune annonce de démo trouvée';

  @override
  String get seedCleanupAction => 'Supprimer les annonces de démo';

  @override
  String seedCleanupDone(int count) {
    return '$count annonce(s) de démo supprimée(s)';
  }

  @override
  String get reportStatusOpen => 'Ouvert';

  @override
  String get reportStatusResolved => 'Traité';

  @override
  String get reportStatusDismissed => 'Rejeté';

  @override
  String get reportFilterAll => 'Tous';

  @override
  String get reportOpenListing => 'Ouvrir l\'annonce';

  @override
  String get reportListingMissing => 'L\'annonce n\'existe plus';

  @override
  String get reportResolve => 'Traiter';

  @override
  String get reportDismiss => 'Rejeter';

  @override
  String get reportDeleteContent => 'Supprimer le contenu';

  @override
  String get reportDeleteContentTitle => 'Supprimer l\'annonce signalée ?';

  @override
  String reportDeleteContentBody(String title) {
    return '\"$title\" sera définitivement supprimée et le signalement marqué traité.';
  }

  @override
  String get reportResolvedToast => 'Signalement traité';

  @override
  String get reportDismissedToast => 'Signalement rejeté';

  @override
  String get adminSearchListings => 'Rechercher titre, propriétaire, wilaya...';

  @override
  String get adminSearchUsers => 'Rechercher nom, e-mail, wilaya...';

  @override
  String get emptySearchResults => 'Aucun résultat';

  @override
  String get userDetailPhone => 'Téléphone';

  @override
  String get userDetailLocation => 'Localisation';

  @override
  String get userDetailJoined => 'Inscrit le';

  @override
  String get userDetailDisabledReason => 'Motif de désactivation';

  @override
  String userListingsCount(int count) {
    return '$count annonces';
  }

  @override
  String userReportsFiled(int count) {
    return '$count signalement(s) envoyé(s)';
  }

  @override
  String userReportsAgainst(int count) {
    return '$count signalement(s) sur leur contenu';
  }

  @override
  String get disableUserTitle => 'Désactiver le compte';

  @override
  String get disableReasonHint => 'Motif (facultatif)';

  @override
  String get disableAction => 'Désactiver';

  @override
  String get enableAction => 'Activer';

  @override
  String get userEnabledToast => 'Compte activé';

  @override
  String get userDisabledToast => 'Compte désactivé';

  @override
  String get adminBadge => 'Admin';

  @override
  String get adminGrant => 'Nommer admin';

  @override
  String get adminRevoke => 'Retirer admin';

  @override
  String get adminGranted => 'Droits d\'administration accordés';

  @override
  String get adminRevoked => 'Droits d\'administration retirés';

  @override
  String get deleteUserData => 'Supprimer toutes les données utilisateur';

  @override
  String get deleteUserDataTitle => 'Supprimer toutes les données utilisateur ?';

  @override
  String deleteUserDataBody(String name) {
    return 'Supprime définitivement les annonces, publications, signalements et le profil de $name. Le compte de connexion doit être supprimé séparément depuis la console Supabase.';
  }

  @override
  String get userDataDeleted => 'Données utilisateur supprimées';

  @override
  String get noRequests => 'Aucune demande';

  @override
  String get reqKindGeneralLabel => 'Général';

  @override
  String get reqKindOptionGeneral => 'Demande générale';

  @override
  String get reqKindOptionBlood => 'Demande de don de sang';

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get onboardingStep1Title => 'Publier un besoin ou une offre';

  @override
  String get onboardingStep1Body => 'Demandez ce dont vous avez besoin, ou proposez ce dont vous n\'avez plus besoin aux gens autour de vous.';

  @override
  String get onboardingStep2Title => 'Appariement, puis appel';

  @override
  String get onboardingStep2Body => 'Quand quelqu\'un répond à votre annonce, vos numéros s\'affichent mutuellement. Pas de chat intégré — un simple appel.';

  @override
  String get onboardingStep3Title => 'Tableau de don de sang';

  @override
  String get onboardingStep3Body => 'Un espace dédié aux demandes de don de sang : choisissez le groupe sanguin et contactez les donneurs plus vite.';

  @override
  String get onboardingCta => 'Compris';

  @override
  String get profileHowItWorks => 'Comment ça marche';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get profileUpdated => 'Profil mis à jour';
}
