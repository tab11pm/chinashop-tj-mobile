// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tajik (`tg`).
class AppLocalizationsTg extends AppLocalizations {
  AppLocalizationsTg([String locale = 'tg']) : super(locale);

  @override
  String get appTitle => 'ПинШоп ТЖ';

  @override
  String get orderActiveItems => 'Молҳои фаъол';

  @override
  String get orderCancelledItems => 'Молҳои бекоршуда';

  @override
  String get orderOriginalTotal => 'Маблағи аслӣ';

  @override
  String get orderCurrentTotal => 'Маблағи ҷорӣ';

  @override
  String get orderCancelledTotal => 'Бекоршуда';

  @override
  String get orderRefundedTotal => 'Баргардондашуда';

  @override
  String orderCancelledItemCount(int count) {
    return '$count моли бекоршуда';
  }

  @override
  String get refundStatusPending => 'Баргардонӣ интизор аст';

  @override
  String get refundStatusFailed => 'Баргардонӣ ноком шуд';

  @override
  String get refundStatusManualRequired => 'Баргардонии дастӣ лозим аст';

  @override
  String get refundStatusSucceeded => 'Баргардонӣ анҷом шуд';

  @override
  String get cancellationReasonLogisticsRestricted => 'Маҳдудияти логистика';

  @override
  String get cancellationReasonPartnerRejected => 'Шарик рад кард';

  @override
  String get cancellationReasonOutOfStock => 'Дар анбор нест';

  @override
  String get cancellationReasonCompliance => 'Мутобиқат';

  @override
  String get cancellationReasonOther => 'Дигар';

  @override
  String get notificationsTitle => 'Огоҳиномаҳо';

  @override
  String get notificationsEmpty => 'Ҳоло огоҳинома нест';

  @override
  String get notificationItemCancelled => 'Моли фармоиш бекор шуд';

  @override
  String get notificationRefundSucceeded => 'Баргардонӣ анҷом шуд';

  @override
  String get notificationRefundFailed => 'Баргардонӣ диққат мехоҳад';

  @override
  String get notificationRefundManualRequired =>
      'Баргардонӣ дастӣ иҷро мешавад';

  @override
  String notificationRefundAmount(String amount) {
    return 'Маблағи баргардонӣ: $amount TJS';
  }

  @override
  String get onboardingTitle => 'Хуш омадед ба ПинШоп ТЖ';

  @override
  String get onboardingSubtitle =>
      'Аз Чин харид кунед, ба Тоҷикистон расонда мешавад';

  @override
  String get selectLanguage => 'Забонро интихоб кунед';

  @override
  String get continueButton => 'Давом додан';

  @override
  String get phoneLabel => 'Рақами телефон';

  @override
  String get phoneHint => '+992XXXXXXXXX';

  @override
  String get sendOtpButton => 'Рамз фиристодан';

  @override
  String get otpLabel => 'Рамзи тасдиқ';

  @override
  String get otpHint => 'Рамзи 6-рақама';

  @override
  String get verifyButton => 'Тасдиқ кардан';

  @override
  String get homeTitle => 'Асосӣ';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get categoryTitle => 'Категория';

  @override
  String get productTitle => 'Молҳо';

  @override
  String get cartTitle => 'Сабад';

  @override
  String get cartEmpty => 'Сабади шумо холӣ аст';

  @override
  String get cartDiscount => 'Тахфиф';

  @override
  String get cartPromoLine => 'Тахфифот дастрас аст';

  @override
  String cartFxLine(String cny) {
    return '≈ $cny ¥ · нарх ҳангоми фармоиш муқарраршудааст';
  }

  @override
  String get checkoutTitle => 'Фармоиш додан';

  @override
  String get ordersTitle => 'Фармоишҳои ман';

  @override
  String get orderDetailTitle => 'Тафсилоти фармоиш';

  @override
  String get favoritesTitle => 'Дӯстдоштаҳо';

  @override
  String get profileTitle => 'Профил';

  @override
  String get profileAnonymous => 'Корбар';

  @override
  String get profileEditCta => 'Вироиш';

  @override
  String get profileNameLabel => 'Номи пурра';

  @override
  String get profilePhoneLabel => 'Телефон';

  @override
  String get profileEditTitle => 'Таҳрири профил';

  @override
  String get profileEditSaved => 'Профил навсозӣ шуд';

  @override
  String get languageLabel => 'Забон';

  @override
  String get saveButton => 'Нигоҳ доштан';

  @override
  String get logoutButton => 'Баромадан';

  @override
  String get loadingText => 'Бор шудан...';

  @override
  String get errorGeneric => 'Хатое рӯй дод. Дубора кӯшиш кунед.';

  @override
  String get errorNetwork => 'Хатои шабака. Пайвастшавиро тафтиш кунед.';

  @override
  String get priceLabel => 'Нарх';

  @override
  String get addToCart => 'Ба сабад илова кардан';

  @override
  String get removeFromCart => 'Хориҷ кардан';

  @override
  String get quantity => 'Миқдор';

  @override
  String get orderStatus => 'Ҳолат';

  @override
  String get orderTotal => 'Ҷамъ';

  @override
  String get shipmentStage => 'Марҳилаи расонидан';

  @override
  String get placeOrderButton => 'Фармоиш додан';

  @override
  String get payNowButton => 'Пардохт кардан';

  @override
  String get addToFavorites => 'Ба дӯстдоштаҳо илова кардан';

  @override
  String get removeFromFavorites => 'Аз дӯстдоштаҳо хориҷ кардан';

  @override
  String get favoritesEmpty => 'Дӯстдоштаҳо холист';

  @override
  String get noOrders => 'Фармоише нест';

  @override
  String get searchHint => 'Ҷустуҷӯи молҳо...';

  @override
  String get allCategories => 'Ҳамаи категорияҳо';

  @override
  String get selectAddress => 'Суроғаи расонидан интихоб кунед';

  @override
  String get addAddress => 'Суроға илова кардан';

  @override
  String get addressLabel => 'Суроға';

  @override
  String get retryButton => 'Такрор кардан';

  @override
  String get trackingTitle => 'Пайгирӣ';

  @override
  String get variantLabel => 'Намуд';

  @override
  String get enterPhoneTitle => 'Рақами телефони худро ворид кунед';

  @override
  String get enterOtpTitle => 'Рамзи тасдиқро ворид кунед';

  @override
  String sentOtpSubtitle(String phone) {
    return 'Мо рамзи 6-рақамиро ба $phone фиристодем';
  }

  @override
  String get sendSmsSubtitle =>
      'Мо ба шумо рамзи тасдиқро тавассути SMS мефиристем.';

  @override
  String get sentOtpSubtitlePrefix => 'Мо SMS фиристодем ба ';

  @override
  String get resendCode => 'Рамзро дубора фиристодан';

  @override
  String get changePhoneLink => 'Тағйир додан';

  @override
  String resendCodeIn(String seconds) {
    return 'Такрор пас аз $seconds';
  }

  @override
  String get authLegalText =>
      'Бо идома додан, шумо Шартҳо ва Сиёсати махфиятро қабул мекунед';

  @override
  String get errorEnterPhone => 'Лутфан рақами телефони худро ворид кунед';

  @override
  String get errorEnterCode => 'Лутфан рамзи тасдиқро ворид кунед';

  @override
  String get profileSetupStep => 'Қадами 3 аз 3 · Қариб тайёр';

  @override
  String get profileSetupTitle => 'Биёед шинос шавем';

  @override
  String get profileSetupSubtitle =>
      'Профилро пур кунед — барои чекҳо, огоҳиномаҳо ва дастгирӣ лозим аст.';

  @override
  String get nameLabel => 'Номи шумо';

  @override
  String get nameHint => 'Фаррух Рауфов';

  @override
  String get emailLabel => 'Почтаи электронӣ';

  @override
  String get emailHint => 'farrukh@example.com';

  @override
  String get emailHelpText =>
      'Почта барои фиристодани чекҳои электронӣ ва тасдиқи фармоишҳо лозим аст.';

  @override
  String get profileSetupCta => 'Тайёр, ба харид! →';

  @override
  String get errorEnterName => 'Лутфан номи худро ворид кунед';

  @override
  String get errorEnterEmail => 'Лутфан почтаи дурусти электрониро ворид кунед';

  @override
  String welcomeTitle(String name) {
    return 'Хуш омадед, $name!';
  }

  @override
  String get welcomeSubtitle =>
      'Ҳисоб тайёр аст. Нархҳои сомонии собитшуда ва расонидан ба Тоҷикистон шуморо интизоранд.';

  @override
  String get welcomeCta => 'Ба мағоза гузаред →';

  @override
  String get categories => 'Категорияҳо';

  @override
  String get newArrivals => 'Тозаворидҳо';

  @override
  String get seeAll => 'Ҳамаро дидан';

  @override
  String get browseCatalog => 'Каталогро кушоед';

  @override
  String get allFilter => 'Ҳама';

  @override
  String get noProductsFound => 'Молҳо ёфт нашуд';

  @override
  String get noProductsInCategory => 'Дар ин категория молҳо нест';

  @override
  String get selectVariant => 'Намудро интихоб кунед';

  @override
  String get addedToCart => 'Ба сабад илова шуд!';

  @override
  String get goToCart => 'Ба сабад гузаштан';

  @override
  String get subtotalLabel => 'Ҷамъи молҳо';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count молҳо',
      one: '$count мол',
    );
    return '$_temp0';
  }

  @override
  String get checkoutButton => 'Расмӣ кардан';

  @override
  String get orderSummary => 'Хулосаи фармоиш';

  @override
  String get deliveryAddress => 'Суроғаи расонидан';

  @override
  String get pickupInformation =>
      'Пас аз фармоиш маъмур нуқтаи доданро таъин карда, маълумоти гирифтани фармоишро ба шумо мефиристад.';

  @override
  String get noSavedAddresses =>
      'Суроғаи нигоҳдошта нест. Дар Профил илова кунед.';

  @override
  String get goToProfile => 'Ба Профил рафтан';

  @override
  String get processing => 'Коркард...';

  @override
  String get placeOrderAndPay => 'Фармоиш додан ва пардохт';

  @override
  String get continuePayment => 'Пардохтро идома додан';

  @override
  String get paymentDisclaimer =>
      'Бо додани фармоиш, пардохт тавассути Корти Миллӣ анҷом меёбад.';

  @override
  String get qty => 'Миқ';

  @override
  String orderNumber(String id) {
    return 'Фармоиш #$id';
  }

  @override
  String get orderPlacedLabel => 'Гузошта шуд';

  @override
  String get orderItemsLabel => 'Молҳо';

  @override
  String get trackingNotAvailable => 'Маълумоти пайгирӣ ҳанӯз дастрас нест.';

  @override
  String get currentStageLabel => 'Марҳилаи ҷорӣ';

  @override
  String get trackingCodeLabel => 'Рамзи пайгирӣ';

  @override
  String get stageHistoryLabel => 'Таърихи марҳилаҳо';

  @override
  String get deliveryAddresses => 'Суроғаҳои расонидан';

  @override
  String get noAddressesSaved =>
      'Суроғае нигоҳ дошта нашудааст. Барои илова кардан + зер кунед.';

  @override
  String get defaultLabel => 'Пешфарз';

  @override
  String get addAddressSheetTitle => 'Суроға илова кардан';

  @override
  String get regionField => 'Минтақа';

  @override
  String get cityField => 'Шаҳр';

  @override
  String get addressLineField => 'Хати суроға';

  @override
  String get phoneField => 'Телефон';

  @override
  String get commentField => 'Шарҳ (ихтиёрӣ)';

  @override
  String get saveAddressButton => 'Суроғаро нигоҳ доштан';

  @override
  String get selectRegionHint => 'Минтақаро интихоб кунед';

  @override
  String get selectCityHint => 'Шаҳрро интихоб кунед';

  @override
  String get phoneFromProfileHint => 'Аз профил';

  @override
  String get fieldRequiredError => 'Ҳатмист';

  @override
  String get addressPhoneInvalidError => 'Рақами телефонро дуруст ворид кунед';

  @override
  String get addFirstAddressCta => 'Аввалин суроғаро илова кунед';

  @override
  String get addAddressTitle => 'Суроғаи нав';

  @override
  String get editAddressTitle => 'Таҳрири суроға';

  @override
  String get addressLoadError => 'Ин суроғаро бор кардан нашуд';

  @override
  String get addAddressCta => 'Суроға илова кунед';

  @override
  String get deleteAddressConfirmTitle => 'Ин суроғаро нест кунем?';

  @override
  String get deleteAddressConfirmBody =>
      'Ин суроға барқасд нест карда мешавад.';

  @override
  String get deleteConfirmButton => 'Нест кардан';

  @override
  String get cancelButton => 'Бекор кардан';

  @override
  String get errOutOfStock => 'Мол дар анбор нест';

  @override
  String get errProductUnavailable => 'Мол дастрас нест';

  @override
  String get errCartEmpty => 'Сабад холӣ аст';

  @override
  String get errOrderAlreadyPaid => 'Фармоиш аллакай пардохт шудааст';

  @override
  String get errOrderNotFound => 'Фармоиш ёфт нашуд';

  @override
  String get errPaymentNotFound => 'Пардохт ёфт нашуд';

  @override
  String get errNoFxRate =>
      'Нархҳо муваққатан дастрас нестанд. Баъдтар кӯшиш кунед.';

  @override
  String get errValidation => 'Маълумоти воридшударо санҷед';

  @override
  String get errUnauthorized => 'Дубора ворид шавед';

  @override
  String get errForbidden => 'Дастрасӣ нест';

  @override
  String get errConflict => 'Амал бо ҳолати ҷорӣ мухолиф аст';

  @override
  String get errEmailInUse => 'Ин email аллакай ба ҳисоби дигар пайваст аст';

  @override
  String get errPhoneInUse => 'Ин рақам аллакай ба ҳисоби дигар пайваст аст';

  @override
  String get errNotFound => 'Ёфт нашуд';

  @override
  String get stageAwaiting => 'Дар интизорӣ';

  @override
  String get stageCnWarehouse => 'Дар анбори Чин';

  @override
  String get stageInTransit => 'Дар роҳ';

  @override
  String get stageTjWarehouse => 'Дар анбори Тоҷикистон';

  @override
  String get stageReady => 'Барои гирифтан тайёр';

  @override
  String get stageDelivered => 'Расонида шуд';

  @override
  String get statusCreated => 'Сохта шуд';

  @override
  String get statusPaid => 'Пардохта шуд';

  @override
  String get statusOrdered => 'Фармоиш дода шуд';

  @override
  String get statusCancelled => 'Бекор шуд';

  @override
  String get statusRefunded => 'Баргардонида шуд';

  @override
  String get b2bApplyTitle => 'Дархост барои яклухт';

  @override
  String get b2bApplyIntro =>
      'Маълумоти мағозаро пур кунед, то ба феҳристи яклухти корхонаҳо дастрасӣ пайдо кунед.';

  @override
  String get b2bShopNameLabel => 'Номи мағоза';

  @override
  String get b2bShopNameHint => 'Масалан: Дӯкони Сомон';

  @override
  String get b2bTaxIdLabel => 'РМА / ИНН';

  @override
  String get b2bTaxIdHint => 'Матни озод';

  @override
  String get b2bCityLabel => 'Шаҳр';

  @override
  String get b2bCityHint => 'Масалан: Душанбе';

  @override
  String get b2bVolumeLabel => 'Ҳаҷми пешбинишуда (ихтиёрӣ)';

  @override
  String get b2bVolumeHint => 'Масалан: 200 дона/моҳ';

  @override
  String b2bPhoneFromProfile(String phone) {
    return 'Телефони тамос: $phone — аз профили шумо гирифта шуд';
  }

  @override
  String get b2bSubmitApplication => 'Дархост фиристодан';

  @override
  String get b2bSubmitting => 'Фиристода истодааст…';

  @override
  String get b2bFieldRequired => 'Ин майдонро пур кунед';

  @override
  String get b2bFieldTooShort => 'Хеле кӯтоҳ';

  @override
  String get b2bFieldTooLong => 'Хеле дароз';

  @override
  String get b2bStatusTitle => 'Дастрасии яклухт';

  @override
  String get b2bStatusPending => 'Дар баррасӣ';

  @override
  String get b2bStatusApproved => 'Тасдиқ шуд';

  @override
  String get b2bStatusRejected => 'Рад шуд';

  @override
  String get b2bStatusSuspended => 'Боздошта шуд';

  @override
  String get b2bPendingBody =>
      'Дархости шумо дар баррасӣ аст. Мо шуморо дар бораи қарор хабардор мекунем.';

  @override
  String get b2bApprovedBody => 'Дастрасӣ ба феҳристи яклухт кушода шуд.';

  @override
  String get b2bRejectionLabel => 'Сабаби рад:';

  @override
  String get b2bSuspendedBody =>
      'Дастрасӣ боздошта шуд. Бо дастгирӣ тамос гиред.';

  @override
  String get b2bSubmittedData => 'Маълумоти дархост';

  @override
  String get b2bReapply => 'Дархостро аз нав фиристодан';

  @override
  String get b2bNoApplicationTitle => 'Шумо ҳанӯз дархост надодаед';

  @override
  String get b2bNoApplicationBody =>
      'Дархост диҳед, то ба феҳристи яклухти корхонаҳо дастрасӣ пайдо кунед.';

  @override
  String get errorApplicationExists => 'Шумо аллакай дархости фаъол доред.';

  @override
  String get errSellerNotVerified => 'Тасдиқи дастрасии яклухт зарур аст.';

  @override
  String get wholesaleCatalogTitle => 'Опт каталог';

  @override
  String get wholesaleCatalogEmptyTitle => 'Ҳоло молҳо нест';

  @override
  String get wholesaleCatalogEmptyBody =>
      'Молҳои корхонаҳо дар ин ҷо зуд пайдо мешаванд';

  @override
  String get wholesaleLockedTitle => 'Дастрасӣ баста аст';

  @override
  String get wholesaleLockedBody =>
      'Нархҳои яклухт танҳо барои фурӯшандагони тасдиқшуда дастрасанд. Барои тасдиқ дархост диҳед.';

  @override
  String get wholesaleLockedCta => 'Дархост фиристодан';

  @override
  String get wholesaleMoqLabel => 'Ҳадди ақалли фармоиш:';

  @override
  String get wholesaleQuantityLabel => 'Миқдор';

  @override
  String get wholesaleAddToCart => 'Ба сабад';

  @override
  String get wholesaleAddedToCart => 'Ба сабад илова шуд';

  @override
  String get wholesaleTiersTitle => 'Ҷадвали нарх';

  @override
  String get wholesaleTierSelectHint =>
      'Барои интихоби миқдор ба тариф зер кунед';

  @override
  String get wholesaleTierQtyCol => 'аз, дона';

  @override
  String get wholesaleTierPriceCol => 'Нарх / дона';

  @override
  String get wholesaleFactoryLabel => 'Корхона:';

  @override
  String get factoryCountryLabel => 'Кишвар:';

  @override
  String factoryMoqRange(int min, int max) {
    return 'МАФ: $min – $max дона';
  }

  @override
  String get factoryDescriptionLabel => 'Дар бораи корхона';

  @override
  String get factoryContactsLabel => 'Тамосҳо';

  @override
  String get factoryNotFound => 'Корхона ёфт нашуд';

  @override
  String get wholesaleCartTitle => 'Сабади яклухт';

  @override
  String get wholesaleCartEmptyTitle => 'Сабад холӣ аст';

  @override
  String get wholesaleCartEmptyBody =>
      'Молҳоро аз феҳристи корхонаҳо илова кунед';

  @override
  String get wholesaleCheckoutTitle => 'Фармоиш додан';

  @override
  String get wholesaleOrderSummaryHeading => 'Хулосаи фармоиш';

  @override
  String get wholesaleCheckoutCta => 'Тасдиқ ва пардохт';

  @override
  String get wholesaleOrdersTitle => 'Фармоишҳои яклухти ман';

  @override
  String get wholesaleOrdersEmptyTitle => 'Ҳоло фармоише нест';

  @override
  String get wholesaleOrdersEmptyBody =>
      'Аввалин фармоишро аз феҳристи корхонаҳо диҳед';

  @override
  String get wholesaleOrderDetailTitle => 'Фармоиш';

  @override
  String get wholesaleOrderItemsHeading => 'Таркиби фармоиш';

  @override
  String wholesaleTierApplied(int qty) {
    return 'Тир аз $qty дона.';
  }

  @override
  String wholesaleMoqError(int qty) {
    return 'Ҳадди ақал $qty дона.';
  }

  @override
  String get wholesaleOrderTotalLabel => 'Ҷамъ';

  @override
  String get wholesaleFactorySubtotalLabel => 'Ҷамъи корхона';

  @override
  String get wholesaleCartCheckoutCta => 'Фармоиш додан';

  @override
  String get wholesaleCartItemRemoveConfirm => 'Молро аз сабад хориҷ кунед?';

  @override
  String get wholesaleCartItemRemoveUndo => 'Бекор кардан';

  @override
  String wholesaleCheckoutMoqError(int qty, String name) {
    return 'Ҳадди ақал $qty дона барои $name. Сабадро навсозӣ кунед.';
  }

  @override
  String get wholesaleCheckoutReturnToCart => 'Ба сабад баргаштан';

  @override
  String get wholesaleCheckoutProcessing => 'Коркард...';

  @override
  String get wholesaleCheckoutProductUnavailable =>
      'Як ё якчанд мол дастрас нест. Сабадро нав кунед.';

  @override
  String get wholesaleCheckoutRetry => 'Бори дигар кӯшиш кунед';

  @override
  String wholesaleMoqChip(int moq) {
    return 'ҳадди ақал $moq дона';
  }

  @override
  String get wholesaleCartRemoveItemA11y => 'Молро нест кардан';

  @override
  String get wholesaleCartDecreaseQtyA11y => 'Камкунии шумора';

  @override
  String get wholesaleCartIncreaseQtyA11y => 'Зиёдкунии шумора';

  @override
  String get channelChoiceTitle => 'Намудро интихоб кунед';

  @override
  String get channelChoiceSubtitle =>
      'Чӣ гуна мехоҳед ChinaShop-ро истифода баред';

  @override
  String get channelB2cLabel => 'Харидории чакана';

  @override
  String get channelB2cSublabel => 'Барои худ харед';

  @override
  String get channelB2bLabel => 'Харидории яклухт';

  @override
  String get channelB2bSublabel => 'Аз заводҳо яклухт харед';

  @override
  String get channelSkip => 'Гузаштан';

  @override
  String get b2bHomeTitle => 'B2B Асосӣ';

  @override
  String get b2bNavHome => 'Асосӣ';

  @override
  String get b2bNavCatalog => 'Каталог';

  @override
  String get b2bNavCart => 'Сабад';

  @override
  String get b2bNavOrders => 'Заказҳо';

  @override
  String get b2bNavProfile => 'Профил';

  @override
  String get b2bChannelBannerTitle => 'Канали яклухт';

  @override
  String get b2bChannelBannerSubtitle => 'Шумо дар намуди яклухт ҳастед';

  @override
  String get b2bHomeViewFactories => 'Заводҳоро дидан';

  @override
  String get b2bHomeMyOrders => 'Фармоишҳои яклухтии ман';

  @override
  String get switchChannelTitle => 'Тағйири канал';

  @override
  String get switchToB2cLabel => 'Ба чакана гузаштан';

  @override
  String get switchToB2cSubtitle => 'Ба харидории муқаррарӣ баргаштан';

  @override
  String get profileWholesaleMenuLabel => 'Маҳсулоти яклухт';

  @override
  String get switchToB2bLabel => 'Ба яклухт гузаштан';

  @override
  String get switchToB2bSubtitle =>
      'Ба каталоги заводҳо ва нархҳои яклухт дастрасӣ';

  @override
  String get switchChannelConfirmTitle => 'Тасдиқи тағйири канал';

  @override
  String get switchChannelConfirmB2c => 'Ба намуди чакана гузаштан?';

  @override
  String get switchChannelConfirmB2b => 'Ба намуди яклухт гузаштан?';

  @override
  String get switchChannelCartNote =>
      'Молҳои сабад ҳангоми тағйири канал нигоҳ дошта мешаванд.';

  @override
  String get switchChannelConfirmButton => 'Тасдиқ';

  @override
  String get switchChannelCancel => 'Бекор кардан';

  @override
  String get channelSectionTitle => 'Канал';

  @override
  String get b2bApplicationStatusTitle => 'Ҳолати ариза';

  @override
  String get paymentReceiptTitle => 'Пардохт ва чек';

  @override
  String get paymentAmountLabel => 'Маблағи пардохт';

  @override
  String get paymentOpenLinkCta => 'Кушодани пайванди пардохт';

  @override
  String get paymentLinkOpenedNote =>
      'Кушодани пайванд пардохтро ТАСДИҚ НАМЕКУНАД. Пас аз пардохт чекро дар поён бор кунед.';

  @override
  String get paymentNoLinkError =>
      'Пайванди пардохт дастрас нест. Баргардед ва аз нав кӯшиш кунед.';

  @override
  String get paymentLinkOpenFailed =>
      'Кушодани пайванди пардохт нашуд. Аз нав кӯшиш кунед.';

  @override
  String get receiptStepTitle => 'Чекро бор кунед';

  @override
  String get receiptStepSubtitle =>
      'Скриншот ё акси тасдиқи пардохтро замима кунед.';

  @override
  String get receiptChooseFromGallery => 'Аз галерея интихоб кунед';

  @override
  String get receiptTakePhoto => 'Акс гирифтан';

  @override
  String get receiptUploading => 'Боркунии чек…';

  @override
  String get receiptAwaitingReviewTitle => 'Чек қабул шуд';

  @override
  String get receiptAwaitingReviewBody =>
      'Чеки шумо санҷида мешавад. Пас аз санҷиш пардохти шуморо тасдиқ мекунем.';

  @override
  String get receiptUploadFailed =>
      'Боркунии чек нашуд. Тасвири дигарро кӯшиш кунед.';

  @override
  String get receiptDoneCta => 'Тайёр';

  @override
  String get receiptRetryCta => 'Аз нав кӯшиш кунед';

  @override
  String get errDuplicateReceipt => 'Ин чек аллакай бор карда шудааст.';

  @override
  String get errReceiptFileInvalid =>
      'Файли нодуруст. Тасвири JPEG, PNG ё WebP то 5 МБ бор кунед.';

  @override
  String get errPaymentNotPending => 'Ин пардохт дигар чекро интизор нест.';

  @override
  String get errReceiptNotFound => 'Пардохт ёфт нашуд.';

  @override
  String get errReceiptUploadSuspended =>
      'Боркунии чекҳо барои чанд соат муваққатан баста шуд, зеро тасвирҳои бегона чанд бор фиристода шуданд.';

  @override
  String get receiptCheckingTitle => 'Чек тафтиш карда мешавад…';

  @override
  String get receiptCheckingBody =>
      'Мо чеки шуморо тафтиш мекунем. Ин одатан якчанд сония тӯл мекашад.';

  @override
  String get receiptApprovedTitle => 'Пардохт тасдиқ шуд';

  @override
  String get receiptApprovedBody => 'Пардохти шумо тасдиқ шуд. Ташаккур!';

  @override
  String get receiptNeedsReviewTitle =>
      'Аз ҷониби оператор тафтиш карда мешавад';

  @override
  String get receiptNeedsReviewBody =>
      'Гурӯҳи мо чеки шуморо тафтиш мекунад. Мо ба зудӣ ба шумо хабар медиҳем.';

  @override
  String get receiptRejectedTitle => 'Чек рад шуд';

  @override
  String get receiptRejectedBody =>
      'Чеки шуморо тасдиқ карда натавонистем. Лутфан тасвири возеҳтарро бор кунед.';

  @override
  String get receiptRejectedReasonLabel => 'Сабаб:';

  @override
  String get receiptRejectedReasonAmountMismatch =>
      'Маблағи чек ба фармоиши шумо мувофиқат намекунад. Онро санҷида, чеки нав бор кунед.';

  @override
  String get receiptRejectedReasonReferenceMissing =>
      'Рақами муомилотро дар чек ёфта натавонистем. Чеки возеҳтар бор кунед.';

  @override
  String get receiptRejectedReasonDuplicate =>
      'Ин чек аллакай барои пардохти дигар истифода шудааст. Чеки дурустро бор кунед.';

  @override
  String get receiptRejectedReasonGeneric =>
      'Чек аз санҷиши худкор нагузашт. Онро санҷида, чеки нав бор кунед.';

  @override
  String get receiptRejectedReasonNotReceipt =>
      'Дар ин тасвир чеки пардохт нест. Скриншот ё акси чеки ҳақиқиро бор кунед.';

  @override
  String get receiptRejectedUploadNewCta => 'Чеки нав бор кунед';

  @override
  String get paymentUnderReview => 'Пардохт дар тафтиш аст';

  @override
  String get b2bBandLogoLabel => 'ПинШоп Бизнес';

  @override
  String get b2bBandGreeting => 'Хуш омадед ба ПинШоп Бизнес!';

  @override
  String get b2bBandGreetingSubtitle =>
      'Яклухт мустақим аз корхонаҳо · нарх бо миқдор паст мешавад';

  @override
  String get b2bBandSearchHint => 'Артикул, мол ё корхона…';

  @override
  String get b2bSwitchPillBuyerLabel => 'Харидор';

  @override
  String get b2bSwitchPillWholesaleLabel => 'Яклухт B2B';

  @override
  String get b2bKpiOrdersLabel => 'Фармоиш / моҳ';

  @override
  String get b2bKpiTurnoverLabel => 'Гардиш';

  @override
  String get b2bKpiSellerStatusLabel => 'Ҳолати фурӯшанда';

  @override
  String get b2bKpiVerifiedValue => 'verified';

  @override
  String get ordersTabAll => 'Ҳама';

  @override
  String get ordersTabInTransit => 'Дар роҳ';

  @override
  String get ordersTabPaid => 'Пардохт шуд';

  @override
  String get ordersTabDelivered => 'Таҳвил дода шуд';

  @override
  String get pickupCodeTitle => 'Рамзи гирифтан';

  @override
  String get pickupCodeHelper =>
      'Ин рамзро ба корманди нуқтаи супориш нишон диҳед';

  @override
  String get pickupCodeOfflineBanner =>
      'Пайваст нест — рамзи захирашуда нишон дода шуд';

  @override
  String get pickupCodeDeliveredTitle => 'Фармоиш супорида шуд';

  @override
  String get pickupCodeDeliveredBody => 'Ташаккур барои харид!';

  @override
  String get showPickupCodeBtn => 'Рамзи гирифтанро нишон диҳед';

  @override
  String get readyForPickupBadge => 'Барои гирифтан омода';

  @override
  String get deliveredCelebrationTitle => 'Бо харид муборак!';

  @override
  String get characteristicsLabel => 'Хусусиятҳо';

  @override
  String get modelOptionsLabel => 'Параметрҳои модел';

  @override
  String get baseModelLabel => 'Модели асосӣ';

  @override
  String get selectedModelLabel => 'Модели интихобшуда';

  @override
  String get soldOutLabel => 'Нест';

  @override
  String get priceReasonLabel =>
      'Нарх аз сабаби хусусиятҳои модели интихобшуда фарқ мекунад.';

  @override
  String get attrColor => 'Ранг';

  @override
  String get attrSize => 'Андоза';

  @override
  String get attrMaterial => 'Мавод';

  @override
  String get attrWeight => 'Вазн';

  @override
  String get attrBrand => 'Бренд';

  @override
  String get attrModel => 'Модел';

  @override
  String get attrCapacity => 'Ҳаҷм';

  @override
  String get attrStorage => 'Хотира';

  @override
  String get orderTrackBtn => 'Назар кардан';

  @override
  String get orderHelpBtn => 'Кумак';

  @override
  String get orderDetailsBtn => 'Тафсилот';

  @override
  String get orderAgainBtn => 'Боз фармоиш додан';

  @override
  String get orderReviewBtn => 'Шарҳ гузоштан';

  @override
  String get b2bSectionFactories => 'Корхонаҳо';

  @override
  String get b2bSectionSeeAll => 'Ҳама ›';

  @override
  String get b2bSectionPopular => 'Машҳури яклухт';

  @override
  String get b2bSectionCatalog => 'Каталог ›';

  @override
  String get b2bFactoryElectronics => 'Электроника';

  @override
  String get b2bFactoryClothing => 'Либос';

  @override
  String get b2bFactoryHome => 'Барои хона';

  @override
  String b2bFactoryCount(int count) {
    return '$count корхонаҳо';
  }

  @override
  String get reviewsSectionTitle => 'Тақризҳо';

  @override
  String seeAllReviewsBtn(int count) {
    return 'Ҳамаи тақризҳо ($count)';
  }

  @override
  String get reviewsEmptyTitle => 'Ҳанӯз тақризе нест';

  @override
  String get reviewsEmptySubtitle => 'Аввалин шавед — дар бораи мол нақл кунед';

  @override
  String get allReviewsTitle => 'Ҳамаи тақризҳо';

  @override
  String get sortNewestChip => 'Навтарин';

  @override
  String get sortRatingChip => 'Аз рӯи баҳо';

  @override
  String get hasPhotosChip => 'Бо акс';

  @override
  String get resetFiltersBtn => 'Партофтани филтрҳо';

  @override
  String get reviewsEmptyFilteredTitle => 'Бо ин филтрҳо тақриз нест';

  @override
  String get reviewsEmptyFilteredSubtitle => 'Филтрҳоро тоза кунед';

  @override
  String get loadReviewsError => 'Тақризҳоро бор кардан нашуд';

  @override
  String reviewCountLabel(int count) {
    return '$count тақриз';
  }

  @override
  String get reviewEntryCta => 'Молро баҳо диҳед';

  @override
  String get reviewFormTitleCreate => 'Молро баҳо диҳед';

  @override
  String get reviewFormTitleEdit => 'Тағйир додани тақриз';

  @override
  String get reviewSubmitCta => 'Фиристодан';

  @override
  String get reviewSubmitting => 'Фиристода истодааст…';

  @override
  String get reviewPhotoSourceCamera => 'Камера';

  @override
  String get reviewPhotoSourceGallery => 'Галерея';

  @override
  String get reviewTextHint => 'Дар бораи мол нақл кунед (ихтиёрӣ)';

  @override
  String get reviewPhotoHelper => 'То 5 акс';

  @override
  String get reviewRatingRequiredValidation =>
      'Баҳо гузоред — ҳадди ақал як ситора';

  @override
  String get reviewTextTooLongValidation => 'На бештар аз 1000 аломат';

  @override
  String get reviewRatingLabel1 => 'Бад';

  @override
  String get reviewRatingLabel2 => 'Миёна';

  @override
  String get reviewRatingLabel3 => 'Муқаррарӣ';

  @override
  String get reviewRatingLabel4 => 'Хуб';

  @override
  String get reviewRatingLabel5 => 'Аъло';

  @override
  String get errReviewNotEligible =>
      'Шумо наметавонед ба ин мол тақриз гузоред';

  @override
  String get errReviewNotFound => 'Тақриз ёфт нашуд';

  @override
  String get errReviewPhotoInvalid =>
      'Яке аз аксҳо мувофиқ нест — онро иваз карда, аз нав фиристед';

  @override
  String get errReviewPhotoLimit => 'Аксҳо хеле зиёданд — на бештар аз 5';

  @override
  String get errReviewAlreadyExists =>
      'Шумо аллакай ба ин мол тақриз гузоштаед';

  @override
  String get reviewOpenExistingCta => 'Тақризи ман';

  @override
  String get reviewRetryCta => 'Такрор кунед';

  @override
  String get reviewDiscardTitle => 'Бе нигоҳ доштан баромадан?';

  @override
  String get reviewDiscardBody =>
      'Баҳо, матн ва аксҳои ворид кардашуда гум мешаванд.';

  @override
  String get reviewDiscardStay => 'Мондан';

  @override
  String get reviewDiscardExit => 'Баромадан';

  @override
  String get reviewSubmitCelebrationTitle => 'Ташаккур барои тақриз!';

  @override
  String get reportSheetTitle => 'Шикоят кардан аз тақриз';

  @override
  String get reportCategorySpam => 'Спам ё реклама';

  @override
  String get reportCategoryAbusive => 'Мазмуни таҳқиромез';

  @override
  String get reportCategoryFalse => 'Иттилооти дурӯғ ё бемавзӯъ';

  @override
  String get reportCategoryPhoto => 'Акси номувофиқ';

  @override
  String get reportCategoryOther => 'Дигар';

  @override
  String get reportCommentHint => 'Шарҳ (ихтиёрӣ)';

  @override
  String get reportSubmitBtn => 'Фиристодани шикоят';

  @override
  String get reportSubmittedToast => 'Шикоят фиристода шуд';

  @override
  String get reportedMarkerLabel => 'Шумо шикоят кардед';

  @override
  String get reportMenuItem => 'Шикоят кардан';

  @override
  String get editReportMenuItem => 'Тағйир додани шикоят';
}
