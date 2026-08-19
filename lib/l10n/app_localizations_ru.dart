// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ChinaShop TJ';

  @override
  String get orderActiveItems => 'Активные позиции';

  @override
  String get orderCancelledItems => 'Отменённые позиции';

  @override
  String get orderOriginalTotal => 'Исходная сумма';

  @override
  String get orderCurrentTotal => 'Текущая сумма';

  @override
  String get orderCancelledTotal => 'Отменено';

  @override
  String get orderRefundedTotal => 'Возвращено';

  @override
  String orderCancelledItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count отменённых позиций',
      many: '$count отменённых позиций',
      few: '$count отменённые позиции',
      one: '$count отменённая позиция',
    );
    return '$_temp0';
  }

  @override
  String get refundStatusPending => 'Возврат ожидается';

  @override
  String get refundStatusFailed => 'Ошибка возврата';

  @override
  String get refundStatusManualRequired => 'Нужен ручной возврат';

  @override
  String get refundStatusSucceeded => 'Возврат завершён';

  @override
  String get cancellationReasonLogisticsRestricted => 'Ограничение логистики';

  @override
  String get cancellationReasonPartnerRejected => 'Отказ партнёра';

  @override
  String get cancellationReasonOutOfStock => 'Нет в наличии';

  @override
  String get cancellationReasonCompliance => 'Требования соответствия';

  @override
  String get cancellationReasonOther => 'Другое';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmpty => 'Уведомлений пока нет';

  @override
  String get notificationItemCancelled => 'Позиция заказа отменена';

  @override
  String get notificationRefundSucceeded => 'Возврат завершён';

  @override
  String get notificationRefundFailed => 'Возврат требует внимания';

  @override
  String get notificationRefundManualRequired => 'Возврат выполняется вручную';

  @override
  String notificationRefundAmount(String amount) {
    return 'Сумма возврата: $amount TJS';
  }

  @override
  String get onboardingTitle => 'Добро пожаловать в ChinaShop TJ';

  @override
  String get onboardingSubtitle =>
      'Покупайте из Китая с доставкой в Таджикистан';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get phoneHint => '+992XXXXXXXXX';

  @override
  String get sendOtpButton => 'Отправить код';

  @override
  String get otpLabel => 'Код подтверждения';

  @override
  String get otpHint => '6-значный код';

  @override
  String get verifyButton => 'Подтвердить';

  @override
  String get homeTitle => 'Главная';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get categoryTitle => 'Категория';

  @override
  String get productTitle => 'Товар';

  @override
  String get cartTitle => 'Корзина';

  @override
  String get cartEmpty => 'Ваша корзина пуста';

  @override
  String get cartDiscount => 'Скидка';

  @override
  String get cartPromoLine => 'Скидки уже учтены';

  @override
  String cartFxLine(String cny) {
    return '≈ $cny ¥ · курс фиксируется при оформлении';
  }

  @override
  String get checkoutTitle => 'Оформление заказа';

  @override
  String get ordersTitle => 'Мои заказы';

  @override
  String get orderDetailTitle => 'Детали заказа';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileAnonymous => 'Пользователь';

  @override
  String get profileEditCta => 'Изменить';

  @override
  String get profileNameLabel => 'Полное имя';

  @override
  String get profilePhoneLabel => 'Телефон';

  @override
  String get profileEditTitle => 'Редактировать профиль';

  @override
  String get profileEditSaved => 'Профиль обновлён';

  @override
  String get languageLabel => 'Язык';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get logoutButton => 'Выйти';

  @override
  String get loadingText => 'Загрузка...';

  @override
  String get errorGeneric => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get errorNetwork => 'Ошибка сети. Проверьте подключение.';

  @override
  String get priceLabel => 'Цена';

  @override
  String get addToCart => 'В корзину';

  @override
  String get removeFromCart => 'Удалить';

  @override
  String get quantity => 'Количество';

  @override
  String get orderStatus => 'Статус';

  @override
  String get orderTotal => 'Итого';

  @override
  String get shipmentStage => 'Этап доставки';

  @override
  String get placeOrderButton => 'Оформить заказ';

  @override
  String get payNowButton => 'Оплатить';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Удалить из избранного';

  @override
  String get favoritesEmpty => 'Избранное пусто';

  @override
  String get noOrders => 'Заказов пока нет';

  @override
  String get searchHint => 'Поиск товаров...';

  @override
  String get allCategories => 'Все категории';

  @override
  String get selectAddress => 'Выберите адрес доставки';

  @override
  String get addAddress => 'Добавить адрес';

  @override
  String get addressLabel => 'Адрес';

  @override
  String get retryButton => 'Повторить';

  @override
  String get trackingTitle => 'Отслеживание';

  @override
  String get variantLabel => 'Вариант';

  @override
  String get enterPhoneTitle => 'Введите номер телефона';

  @override
  String get enterOtpTitle => 'Введите код подтверждения';

  @override
  String sentOtpSubtitle(String phone) {
    return 'Мы отправили 6-значный код на номер $phone';
  }

  @override
  String get sendSmsSubtitle => 'Мы отправим вам код подтверждения через SMS.';

  @override
  String get sentOtpSubtitlePrefix => 'Мы отправили SMS на ';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get changePhoneLink => 'Изменить';

  @override
  String resendCodeIn(String seconds) {
    return 'Повторить через $seconds';
  }

  @override
  String get authLegalText =>
      'Продолжая, вы принимаете Условия и Политику конфиденциальности';

  @override
  String get errorEnterPhone => 'Пожалуйста, введите номер телефона';

  @override
  String get errorEnterCode => 'Пожалуйста, введите код подтверждения';

  @override
  String get profileSetupStep => 'Шаг 3 из 3 · Почти готово';

  @override
  String get profileSetupTitle => 'Давайте познакомимся';

  @override
  String get profileSetupSubtitle =>
      'Заполните профиль — это нужно для чеков, уведомлений и поддержки.';

  @override
  String get nameLabel => 'Ваше имя';

  @override
  String get nameHint => 'Фаррух Рауфов';

  @override
  String get emailLabel => 'Электронная почта';

  @override
  String get emailHint => 'farrukh@example.com';

  @override
  String get emailHelpText =>
      'Почта нужна, чтобы присылать электронные чеки и подтверждения заказов.';

  @override
  String get profileSetupCta => 'Готово, за покупками! →';

  @override
  String get errorEnterName => 'Пожалуйста, введите ваше имя';

  @override
  String get errorEnterEmail => 'Пожалуйста, введите корректный email';

  @override
  String welcomeTitle(String name) {
    return 'Добро пожаловать, $name!';
  }

  @override
  String get welcomeSubtitle =>
      'Аккаунт готов. Зафиксированные цены в сомони и доставка в Таджикистан ждут вас.';

  @override
  String get welcomeCta => 'Перейти в магазин →';

  @override
  String get categories => 'Категории';

  @override
  String get newArrivals => 'Новинки';

  @override
  String get seeAll => 'Смотреть все';

  @override
  String get browseCatalog => 'Перейти в каталог';

  @override
  String get allFilter => 'Все';

  @override
  String get noProductsFound => 'Товары не найдены';

  @override
  String get noProductsInCategory => 'В этой категории нет товаров';

  @override
  String get selectVariant => 'Выберите вариант';

  @override
  String get addedToCart => 'Добавлено в корзину!';

  @override
  String get goToCart => 'Перейти в корзину';

  @override
  String get subtotalLabel => 'Сумма товаров';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count товаров',
      few: '$count товара',
      one: '$count товар',
    );
    return '$_temp0';
  }

  @override
  String get checkoutButton => 'Оформить';

  @override
  String get orderSummary => 'Сводка заказа';

  @override
  String get deliveryAddress => 'Адрес доставки';

  @override
  String get pickupInformation =>
      'После оформления администратор назначит пункт выдачи и сообщит вам детали получения.';

  @override
  String get noSavedAddresses => 'Нет сохранённых адресов. Добавьте в профиле.';

  @override
  String get goToProfile => 'Перейти в профиль';

  @override
  String get processing => 'Обработка...';

  @override
  String get placeOrderAndPay => 'Оформить заказ и оплатить';

  @override
  String get continuePayment => 'Продолжить оплату';

  @override
  String get paymentDisclaimer =>
      'Оформляя заказ, вы подтверждаете оплату через Корти Милли.';

  @override
  String get qty => 'Кол';

  @override
  String orderNumber(String id) {
    return 'Заказ #$id';
  }

  @override
  String get orderPlacedLabel => 'Оформлен';

  @override
  String get orderItemsLabel => 'Товары';

  @override
  String get trackingNotAvailable =>
      'Информация об отслеживании пока недоступна.';

  @override
  String get currentStageLabel => 'Текущий этап';

  @override
  String get trackingCodeLabel => 'Код отслеживания';

  @override
  String get stageHistoryLabel => 'История этапов';

  @override
  String get deliveryAddresses => 'Адреса доставки';

  @override
  String get noAddressesSaved =>
      'Адреса не сохранены. Нажмите + чтобы добавить.';

  @override
  String get defaultLabel => 'По умолчанию';

  @override
  String get addAddressSheetTitle => 'Добавить адрес';

  @override
  String get regionField => 'Регион';

  @override
  String get cityField => 'Город';

  @override
  String get addressLineField => 'Адресная строка';

  @override
  String get phoneField => 'Телефон';

  @override
  String get commentField => 'Комментарий (необязательно)';

  @override
  String get saveAddressButton => 'Сохранить адрес';

  @override
  String get selectRegionHint => 'Выберите регион';

  @override
  String get selectCityHint => 'Выберите город';

  @override
  String get phoneFromProfileHint => 'Из профиля';

  @override
  String get fieldRequiredError => 'Обязательное поле';

  @override
  String get addressPhoneInvalidError => 'Введите корректный номер телефона';

  @override
  String get addFirstAddressCta => 'Добавить первый адрес';

  @override
  String get addAddressTitle => 'Новый адрес';

  @override
  String get editAddressTitle => 'Редактировать адрес';

  @override
  String get addressLoadError => 'Не удалось загрузить этот адрес';

  @override
  String get addAddressCta => 'Добавить адрес';

  @override
  String get deleteAddressConfirmTitle => 'Удалить этот адрес?';

  @override
  String get deleteAddressConfirmBody => 'Этот адрес будет удалён навсегда.';

  @override
  String get deleteConfirmButton => 'Удалить';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get errOutOfStock => 'Товара нет в наличии';

  @override
  String get errProductUnavailable => 'Товар недоступен';

  @override
  String get errCartEmpty => 'Корзина пуста';

  @override
  String get errOrderAlreadyPaid => 'Заказ уже оплачен';

  @override
  String get errOrderNotFound => 'Заказ не найден';

  @override
  String get errPaymentNotFound => 'Платёж не найден';

  @override
  String get errNoFxRate => 'Цены временно недоступны. Попробуйте позже.';

  @override
  String get errValidation => 'Проверьте введённые данные';

  @override
  String get errUnauthorized => 'Войдите снова';

  @override
  String get errForbidden => 'Нет доступа';

  @override
  String get errConflict => 'Действие конфликтует с текущим состоянием';

  @override
  String get errEmailInUse => 'Этот email уже привязан к другому аккаунту';

  @override
  String get errPhoneInUse => 'Этот номер уже привязан к другому аккаунту';

  @override
  String get errNotFound => 'Не найдено';

  @override
  String get stageAwaiting => 'Ожидание';

  @override
  String get stageCnWarehouse => 'На складе в Китае';

  @override
  String get stageInTransit => 'В пути';

  @override
  String get stageTjWarehouse => 'На складе в Таджикистане';

  @override
  String get stageReady => 'Готов к выдаче';

  @override
  String get stageDelivered => 'Доставлен';

  @override
  String get statusCreated => 'Создан';

  @override
  String get statusPaid => 'Оплачен';

  @override
  String get statusOrdered => 'Заказан';

  @override
  String get statusCancelled => 'Отменён';

  @override
  String get statusRefunded => 'Возврат';

  @override
  String get b2bApplyTitle => 'Заявка на опт';

  @override
  String get b2bApplyIntro =>
      'Заполните данные магазина, чтобы получить доступ к оптовому каталогу заводов.';

  @override
  String get b2bShopNameLabel => 'Название магазина';

  @override
  String get b2bShopNameHint => 'Например: Дӯкони Сомон';

  @override
  String get b2bTaxIdLabel => 'ИНН / налоговый ID';

  @override
  String get b2bTaxIdHint => 'Свободный текст';

  @override
  String get b2bCityLabel => 'Город';

  @override
  String get b2bCityHint => 'Например: Душанбе';

  @override
  String get b2bVolumeLabel => 'Ожидаемый объём (необязательно)';

  @override
  String get b2bVolumeHint => 'Например: 200 шт/мес';

  @override
  String b2bPhoneFromProfile(String phone) {
    return 'Контактный телефон: $phone — взят из вашего профиля';
  }

  @override
  String get b2bSubmitApplication => 'Подать заявку';

  @override
  String get b2bSubmitting => 'Отправка…';

  @override
  String get b2bFieldRequired => 'Заполните это поле';

  @override
  String get b2bFieldTooShort => 'Слишком коротко';

  @override
  String get b2bFieldTooLong => 'Слишком длинно';

  @override
  String get b2bStatusTitle => 'Оптовый доступ';

  @override
  String get b2bStatusPending => 'На рассмотрении';

  @override
  String get b2bStatusApproved => 'Одобрено';

  @override
  String get b2bStatusRejected => 'Отклонено';

  @override
  String get b2bStatusSuspended => 'Приостановлено';

  @override
  String get b2bPendingBody =>
      'Ваша заявка на рассмотрении. Мы уведомим вас о решении.';

  @override
  String get b2bApprovedBody => 'Доступ к оптовому каталогу открыт.';

  @override
  String get b2bRejectionLabel => 'Причина отказа:';

  @override
  String get b2bSuspendedBody =>
      'Доступ приостановлен. Свяжитесь с поддержкой.';

  @override
  String get b2bSubmittedData => 'Данные заявки';

  @override
  String get b2bReapply => 'Подать заявку заново';

  @override
  String get b2bNoApplicationTitle => 'Вы ещё не подавали заявку';

  @override
  String get b2bNoApplicationBody =>
      'Подайте заявку, чтобы получить доступ к оптовому каталогу заводов.';

  @override
  String get errorApplicationExists => 'У вас уже есть активная заявка.';

  @override
  String get errSellerNotVerified => 'Требуется верификация оптового доступа.';

  @override
  String get wholesaleCatalogTitle => 'Оптовый каталог';

  @override
  String get wholesaleCatalogEmptyTitle => 'Товаров пока нет';

  @override
  String get wholesaleCatalogEmptyBody => 'Скоро здесь появятся товары заводов';

  @override
  String get wholesaleLockedTitle => 'Доступ закрыт';

  @override
  String get wholesaleLockedBody =>
      'Оптовые цены доступны только верифицированным продавцам. Подайте заявку на проверку.';

  @override
  String get wholesaleLockedCta => 'Подать заявку';

  @override
  String get wholesaleMoqLabel => 'Минимальный заказ:';

  @override
  String get wholesaleQuantityLabel => 'Количество';

  @override
  String get wholesaleAddToCart => 'В корзину';

  @override
  String get wholesaleAddedToCart => 'Добавлено в корзину';

  @override
  String get wholesaleTiersTitle => 'Тарифная таблица';

  @override
  String get wholesaleTierSelectHint => 'Нажмите на тариф, чтобы выбрать объём';

  @override
  String get wholesaleTierQtyCol => 'от, шт.';

  @override
  String get wholesaleTierPriceCol => 'Цена / шт.';

  @override
  String get wholesaleFactoryLabel => 'Завод:';

  @override
  String get factoryCountryLabel => 'Страна:';

  @override
  String factoryMoqRange(int min, int max) {
    return 'MOQ: $min – $max шт.';
  }

  @override
  String get factoryDescriptionLabel => 'О заводе';

  @override
  String get factoryContactsLabel => 'Контакты';

  @override
  String get factoryNotFound => 'Завод не найден';

  @override
  String get wholesaleCartTitle => 'Оптовая корзина';

  @override
  String get wholesaleCartEmptyTitle => 'Корзина пуста';

  @override
  String get wholesaleCartEmptyBody => 'Добавьте товары из каталога заводов';

  @override
  String get wholesaleCheckoutTitle => 'Оформление заказа';

  @override
  String get wholesaleOrderSummaryHeading => 'Сводка заказа';

  @override
  String get wholesaleCheckoutCta => 'Подтвердить и оплатить';

  @override
  String get wholesaleOrdersTitle => 'Мои оптовые заказы';

  @override
  String get wholesaleOrdersEmptyTitle => 'Заказов пока нет';

  @override
  String get wholesaleOrdersEmptyBody =>
      'Оформите первый заказ из каталога заводов';

  @override
  String get wholesaleOrderDetailTitle => 'Заказ';

  @override
  String get wholesaleOrderItemsHeading => 'Состав заказа';

  @override
  String wholesaleTierApplied(int qty) {
    return 'Тир от $qty шт.';
  }

  @override
  String wholesaleMoqError(int qty) {
    return 'Минимум $qty шт.';
  }

  @override
  String get wholesaleOrderTotalLabel => 'Итого';

  @override
  String get wholesaleFactorySubtotalLabel => 'Итого по заводу';

  @override
  String get wholesaleCartCheckoutCta => 'Оформить заказ';

  @override
  String get wholesaleCartItemRemoveConfirm => 'Удалить товар из корзины?';

  @override
  String get wholesaleCartItemRemoveUndo => 'Отмена';

  @override
  String wholesaleCheckoutMoqError(int qty, String name) {
    return 'Минимум $qty единиц для $name. Обновите корзину.';
  }

  @override
  String get wholesaleCheckoutReturnToCart => 'Вернуться в корзину';

  @override
  String get wholesaleCheckoutProcessing => 'Обработка...';

  @override
  String get wholesaleCheckoutProductUnavailable =>
      'Один или несколько товаров недоступны. Обновите корзину.';

  @override
  String get wholesaleCheckoutRetry => 'Попробовать снова';

  @override
  String wholesaleMoqChip(int moq) {
    return 'мин. $moq шт.';
  }

  @override
  String get wholesaleCartRemoveItemA11y => 'Удалить товар';

  @override
  String get wholesaleCartDecreaseQtyA11y => 'Уменьшить количество';

  @override
  String get wholesaleCartIncreaseQtyA11y => 'Увеличить количество';

  @override
  String get channelChoiceTitle => 'Выберите режим';

  @override
  String get channelChoiceSubtitle => 'Как вы хотите использовать ChinaShop';

  @override
  String get channelB2cLabel => 'Розничные покупки';

  @override
  String get channelB2cSublabel => 'Покупайте для себя';

  @override
  String get channelB2bLabel => 'Оптовые закупки';

  @override
  String get channelB2bSublabel => 'Покупайте оптом у заводов';

  @override
  String get channelSkip => 'Пропустить';

  @override
  String get b2bHomeTitle => 'B2B Главная';

  @override
  String get b2bNavHome => 'Главная';

  @override
  String get b2bNavCatalog => 'Каталог';

  @override
  String get b2bNavCart => 'Корзина';

  @override
  String get b2bNavOrders => 'Заказы';

  @override
  String get b2bNavProfile => 'Профиль';

  @override
  String get b2bChannelBannerTitle => 'Оптовый канал';

  @override
  String get b2bChannelBannerSubtitle => 'Вы в оптовом режиме';

  @override
  String get b2bHomeViewFactories => 'Просмотр заводов';

  @override
  String get b2bHomeMyOrders => 'Мои оптовые заказы';

  @override
  String get switchChannelTitle => 'Сменить канал';

  @override
  String get switchToB2cLabel => 'Перейти в розницу';

  @override
  String get switchToB2cSubtitle => 'Вернуться к обычным покупкам';

  @override
  String get profileWholesaleMenuLabel => 'Оптовые товары';

  @override
  String get switchToB2bLabel => 'Перейти в опт';

  @override
  String get switchToB2bSubtitle => 'Доступ к каталогу заводов и оптовым ценам';

  @override
  String get switchChannelConfirmTitle => 'Подтвердить смену канала';

  @override
  String get switchChannelConfirmB2c => 'Перейти в розничный режим?';

  @override
  String get switchChannelConfirmB2b => 'Перейти в оптовый режим?';

  @override
  String get switchChannelCartNote =>
      'Товары в корзине сохраняются при смене канала.';

  @override
  String get switchChannelConfirmButton => 'Подтвердить';

  @override
  String get switchChannelCancel => 'Отмена';

  @override
  String get channelSectionTitle => 'Канал';

  @override
  String get b2bApplicationStatusTitle => 'Статус заявки';

  @override
  String get paymentReceiptTitle => 'Оплата и чек';

  @override
  String get paymentAmountLabel => 'Сумма к оплате';

  @override
  String get paymentOpenLinkCta => 'Открыть ссылку для оплаты';

  @override
  String get paymentLinkOpenedNote =>
      'Открытие ссылки НЕ подтверждает оплату. После оплаты загрузите чек ниже.';

  @override
  String get paymentNoLinkError =>
      'Ссылка для оплаты недоступна. Вернитесь назад и попробуйте снова.';

  @override
  String get paymentLinkOpenFailed =>
      'Не удалось открыть ссылку для оплаты. Попробуйте снова.';

  @override
  String get receiptStepTitle => 'Загрузите чек';

  @override
  String get receiptStepSubtitle =>
      'Прикрепите скриншот или фото подтверждения оплаты.';

  @override
  String get receiptChooseFromGallery => 'Выбрать из галереи';

  @override
  String get receiptTakePhoto => 'Сделать фото';

  @override
  String get receiptUploading => 'Загрузка чека…';

  @override
  String get receiptAwaitingReviewTitle => 'Чек получен';

  @override
  String get receiptAwaitingReviewBody =>
      'Ваш чек проверяется. Мы подтвердим оплату после проверки.';

  @override
  String get receiptUploadFailed =>
      'Не удалось загрузить чек. Попробуйте другое изображение.';

  @override
  String get receiptDoneCta => 'Готово';

  @override
  String get receiptRetryCta => 'Попробовать снова';

  @override
  String get errDuplicateReceipt => 'Этот чек уже был загружен.';

  @override
  String get errReceiptFileInvalid =>
      'Неверный файл. Загрузите изображение JPEG, PNG или WebP до 5 МБ.';

  @override
  String get errPaymentNotPending => 'Этот платёж больше не ожидает чек.';

  @override
  String get errReceiptNotFound => 'Платёж не найден.';

  @override
  String get errReceiptUploadSuspended =>
      'Загрузка чеков временно заблокирована на несколько часов из-за повторной отправки посторонних изображений.';

  @override
  String get receiptCheckingTitle => 'Проверяем чек…';

  @override
  String get receiptCheckingBody =>
      'Мы проверяем ваш чек. Это обычно занимает несколько секунд.';

  @override
  String get receiptApprovedTitle => 'Оплата подтверждена';

  @override
  String get receiptApprovedBody => 'Ваш платёж подтверждён. Спасибо!';

  @override
  String get receiptNeedsReviewTitle => 'Проверка оператором';

  @override
  String get receiptNeedsReviewBody =>
      'Наша команда проверяет ваш чек. Мы уведомим вас в ближайшее время.';

  @override
  String get receiptRejectedTitle => 'Чек отклонён';

  @override
  String get receiptRejectedBody =>
      'Ваш чек не удалось верифицировать. Пожалуйста, загрузите более чёткое изображение.';

  @override
  String get receiptRejectedReasonLabel => 'Причина:';

  @override
  String get receiptRejectedReasonAmountMismatch =>
      'Сумма в чеке не совпадает с суммой заказа. Проверьте и загрузите новый чек.';

  @override
  String get receiptRejectedReasonReferenceMissing =>
      'Не удалось найти номер транзакции в чеке. Загрузите более чёткий чек.';

  @override
  String get receiptRejectedReasonDuplicate =>
      'Этот чек уже использован для другого платежа. Загрузите правильный чек.';

  @override
  String get receiptRejectedReasonGeneric =>
      'Чек не прошёл автоматическую проверку. Проверьте его и загрузите новый.';

  @override
  String get receiptRejectedReasonNotReceipt =>
      'На изображении нет чека об оплате. Отправьте скриншот или фотографию настоящего чека.';

  @override
  String get receiptRejectedUploadNewCta => 'Загрузить новый чек';

  @override
  String get paymentUnderReview => 'Оплата на проверке';

  @override
  String get b2bBandLogoLabel => 'ChinaShop Бизнес';

  @override
  String get b2bBandGreeting => 'Добро пожаловать в ChinaShop Бизнес!';

  @override
  String get b2bBandGreetingSubtitle =>
      'Опт напрямую с заводов · цена за единицу падает с объёмом';

  @override
  String get b2bBandSearchHint => 'Артикул, товар или завод…';

  @override
  String get b2bSwitchPillBuyerLabel => 'Покупатель';

  @override
  String get b2bSwitchPillWholesaleLabel => 'Опт B2B';

  @override
  String get b2bKpiOrdersLabel => 'Заказов в месяц';

  @override
  String get b2bKpiTurnoverLabel => 'Оборот';

  @override
  String get b2bKpiSellerStatusLabel => 'Статус продавца';

  @override
  String get b2bKpiVerifiedValue => 'verified';

  @override
  String get ordersTabAll => 'Все';

  @override
  String get ordersTabInTransit => 'В пути';

  @override
  String get ordersTabPaid => 'Оплачен';

  @override
  String get ordersTabDelivered => 'Получен';

  @override
  String get pickupCodeTitle => 'Код выдачи';

  @override
  String get pickupCodeHelper => 'Покажите этот код сотруднику пункта выдачи';

  @override
  String get pickupCodeOfflineBanner =>
      'Нет соединения — показан сохранённый код';

  @override
  String get pickupCodeDeliveredTitle => 'Заказ выдан';

  @override
  String get pickupCodeDeliveredBody => 'Спасибо за покупку!';

  @override
  String get showPickupCodeBtn => 'Показать код выдачи';

  @override
  String get readyForPickupBadge => 'Готов к выдаче';

  @override
  String get deliveredCelebrationTitle => 'Поздравляем с покупкой!';

  @override
  String get characteristicsLabel => 'Характеристики';

  @override
  String get modelOptionsLabel => 'Параметры модели';

  @override
  String get baseModelLabel => 'Базовая модель';

  @override
  String get selectedModelLabel => 'Выбранная модель';

  @override
  String get soldOutLabel => 'Нет в наличии';

  @override
  String get priceReasonLabel =>
      'Цена меняется из-за характеристик выбранной модели.';

  @override
  String get attrColor => 'Цвет';

  @override
  String get attrSize => 'Размер';

  @override
  String get attrMaterial => 'Материал';

  @override
  String get attrWeight => 'Вес';

  @override
  String get attrBrand => 'Бренд';

  @override
  String get attrModel => 'Модель';

  @override
  String get attrCapacity => 'Объем';

  @override
  String get attrStorage => 'Память';

  @override
  String get orderTrackBtn => 'Отследить';

  @override
  String get orderHelpBtn => 'Помощь';

  @override
  String get orderDetailsBtn => 'Детали';

  @override
  String get orderAgainBtn => 'Заказать снова';

  @override
  String get orderReviewBtn => 'Оставить отзыв';

  @override
  String get b2bSectionFactories => 'Заводы';

  @override
  String get b2bSectionSeeAll => 'Все ›';

  @override
  String get b2bSectionPopular => 'Популярное оптом';

  @override
  String get b2bSectionCatalog => 'Каталог ›';

  @override
  String get b2bFactoryElectronics => 'Электроника';

  @override
  String get b2bFactoryClothing => 'Одежда';

  @override
  String get b2bFactoryHome => 'Для дома';

  @override
  String b2bFactoryCount(int count) {
    return '$count заводов';
  }

  @override
  String get reviewsSectionTitle => 'Отзывы';

  @override
  String seeAllReviewsBtn(int count) {
    return 'Все отзывы ($count)';
  }

  @override
  String get reviewsEmptyTitle => 'Отзывов пока нет';

  @override
  String get reviewsEmptySubtitle => 'Станьте первым — расскажите о товаре';

  @override
  String get allReviewsTitle => 'Все отзывы';

  @override
  String get sortNewestChip => 'Новые';

  @override
  String get sortRatingChip => 'По рейтингу';

  @override
  String get hasPhotosChip => 'С фото';

  @override
  String get resetFiltersBtn => 'Сбросить фильтры';

  @override
  String get reviewsEmptyFilteredTitle => 'По этим фильтрам отзывов нет';

  @override
  String get reviewsEmptyFilteredSubtitle => 'Попробуйте убрать фильтры';

  @override
  String get loadReviewsError => 'Не удалось загрузить отзывы';

  @override
  String reviewCountLabel(int count) {
    return '$count отзывов';
  }

  @override
  String get reviewEntryCta => 'Оценить товар';

  @override
  String get reviewFormTitleCreate => 'Оценить товар';

  @override
  String get reviewFormTitleEdit => 'Изменить отзыв';

  @override
  String get reviewSubmitCta => 'Отправить';

  @override
  String get reviewSubmitting => 'Отправка…';

  @override
  String get reviewPhotoSourceCamera => 'Камера';

  @override
  String get reviewPhotoSourceGallery => 'Галерея';

  @override
  String get reviewTextHint => 'Расскажите о товаре (необязательно)';

  @override
  String get reviewPhotoHelper => 'До 5 фото';

  @override
  String get reviewRatingRequiredValidation =>
      'Поставьте оценку — минимум одна звезда';

  @override
  String get reviewTextTooLongValidation => 'Не больше 1000 символов';

  @override
  String get reviewRatingLabel1 => 'Плохо';

  @override
  String get reviewRatingLabel2 => 'Так себе';

  @override
  String get reviewRatingLabel3 => 'Нормально';

  @override
  String get reviewRatingLabel4 => 'Хорошо';

  @override
  String get reviewRatingLabel5 => 'Отлично';

  @override
  String get errReviewNotEligible =>
      'Вы не можете оставить отзыв на этот товар';

  @override
  String get errReviewNotFound => 'Отзыв не найден';

  @override
  String get errReviewPhotoInvalid =>
      'Одно из фото не подошло — замените его и отправьте снова';

  @override
  String get errReviewPhotoLimit => 'Слишком много фото — не больше 5';

  @override
  String get errReviewAlreadyExists => 'Вы уже оставили отзыв на этот товар';

  @override
  String get reviewOpenExistingCta => 'Открыть мой отзыв';

  @override
  String get reviewRetryCta => 'Повторить';

  @override
  String get reviewDiscardTitle => 'Выйти без сохранения?';

  @override
  String get reviewDiscardBody =>
      'Введённые оценка, текст и фото будут потеряны.';

  @override
  String get reviewDiscardStay => 'Остаться';

  @override
  String get reviewDiscardExit => 'Выйти';

  @override
  String get reviewSubmitCelebrationTitle => 'Спасибо за отзыв!';

  @override
  String get reportSheetTitle => 'Пожаловаться на отзыв';

  @override
  String get reportCategorySpam => 'Спам или реклама';

  @override
  String get reportCategoryAbusive => 'Оскорбительное содержание';

  @override
  String get reportCategoryFalse => 'Ложная или нерелевантная информация';

  @override
  String get reportCategoryPhoto => 'Неприемлемое фото';

  @override
  String get reportCategoryOther => 'Другое';

  @override
  String get reportCommentHint => 'Комментарий (необязательно)';

  @override
  String get reportSubmitBtn => 'Отправить жалобу';

  @override
  String get reportSubmittedToast => 'Жалоба отправлена';

  @override
  String get reportedMarkerLabel => 'Вы пожаловались';

  @override
  String get reportMenuItem => 'Пожаловаться';

  @override
  String get editReportMenuItem => 'Изменить жалобу';
}
