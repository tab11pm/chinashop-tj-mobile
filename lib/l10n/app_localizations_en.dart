// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChinaShop TJ';

  @override
  String get orderActiveItems => 'Active items';

  @override
  String get orderCancelledItems => 'Cancelled items';

  @override
  String get orderOriginalTotal => 'Original total';

  @override
  String get orderCurrentTotal => 'Current total';

  @override
  String get orderCancelledTotal => 'Cancelled total';

  @override
  String get orderRefundedTotal => 'Refunded total';

  @override
  String orderCancelledItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cancelled items',
      one: '$count cancelled item',
    );
    return '$_temp0';
  }

  @override
  String get refundStatusPending => 'Refund pending';

  @override
  String get refundStatusFailed => 'Refund failed';

  @override
  String get refundStatusManualRequired => 'Manual refund required';

  @override
  String get refundStatusSucceeded => 'Refund completed';

  @override
  String get cancellationReasonLogisticsRestricted => 'Logistics restricted';

  @override
  String get cancellationReasonPartnerRejected => 'Partner rejected';

  @override
  String get cancellationReasonOutOfStock => 'Out of stock';

  @override
  String get cancellationReasonCompliance => 'Compliance';

  @override
  String get cancellationReasonOther => 'Other';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationItemCancelled => 'Order item cancelled';

  @override
  String get notificationRefundSucceeded => 'Refund completed';

  @override
  String get notificationRefundFailed => 'Refund needs attention';

  @override
  String get notificationRefundManualRequired =>
      'Refund is being handled manually';

  @override
  String notificationRefundAmount(String amount) {
    return 'Refund amount: $amount TJS';
  }

  @override
  String get onboardingTitle => 'Welcome to ChinaShop TJ';

  @override
  String get onboardingSubtitle => 'Shop from China, delivered to Tajikistan';

  @override
  String get selectLanguage => 'Select your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '+992XXXXXXXXX';

  @override
  String get sendOtpButton => 'Send code';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get otpHint => '6-digit code';

  @override
  String get verifyButton => 'Verify';

  @override
  String get homeTitle => 'Home';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get categoryTitle => 'Category';

  @override
  String get productTitle => 'Product';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get cartDiscount => 'Discount';

  @override
  String get cartPromoLine => 'Discounts already applied';

  @override
  String cartFxLine(String cny) {
    return '≈ $cny ¥ · rate locked at order';
  }

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get ordersTitle => 'My Orders';

  @override
  String get orderDetailTitle => 'Order Details';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAnonymous => 'User';

  @override
  String get profileEditCta => 'Edit';

  @override
  String get profileNameLabel => 'Full name';

  @override
  String get profilePhoneLabel => 'Phone';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditSaved => 'Profile updated';

  @override
  String get languageLabel => 'Language';

  @override
  String get saveButton => 'Save';

  @override
  String get logoutButton => 'Log out';

  @override
  String get loadingText => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get priceLabel => 'Price';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get removeFromCart => 'Remove';

  @override
  String get quantity => 'Quantity';

  @override
  String get orderStatus => 'Status';

  @override
  String get orderTotal => 'Total';

  @override
  String get shipmentStage => 'Shipment stage';

  @override
  String get placeOrderButton => 'Place order';

  @override
  String get payNowButton => 'Pay now';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get noOrders => 'No orders yet';

  @override
  String get searchHint => 'Search products...';

  @override
  String get allCategories => 'All categories';

  @override
  String get selectAddress => 'Select delivery address';

  @override
  String get addAddress => 'Add address';

  @override
  String get addressLabel => 'Address';

  @override
  String get retryButton => 'Retry';

  @override
  String get trackingTitle => 'Tracking';

  @override
  String get variantLabel => 'Variant';

  @override
  String get enterPhoneTitle => 'Enter your phone number';

  @override
  String get enterOtpTitle => 'Enter verification code';

  @override
  String sentOtpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get sendSmsSubtitle => 'We will send you a verification code via SMS.';

  @override
  String get sentOtpSubtitlePrefix => 'We sent an SMS to ';

  @override
  String get resendCode => 'Resend code';

  @override
  String get changePhoneLink => 'Change';

  @override
  String resendCodeIn(String seconds) {
    return 'Resend in $seconds';
  }

  @override
  String get authLegalText =>
      'By continuing, you agree to the Terms and Privacy Policy';

  @override
  String get errorEnterPhone => 'Please enter your phone number';

  @override
  String get errorEnterCode => 'Please enter the verification code';

  @override
  String get profileSetupStep => 'Step 3 of 3 · Almost done';

  @override
  String get profileSetupTitle => 'Let\'s get acquainted';

  @override
  String get profileSetupSubtitle =>
      'Fill in your profile — needed for receipts, notifications, and support.';

  @override
  String get nameLabel => 'Your name';

  @override
  String get nameHint => 'Farrukh Raufov';

  @override
  String get emailLabel => 'Email address';

  @override
  String get emailHint => 'farrukh@example.com';

  @override
  String get emailHelpText =>
      'We need your email to send e-receipts and order confirmations.';

  @override
  String get profileSetupCta => 'Done, let\'s shop! →';

  @override
  String get errorEnterName => 'Please enter your name';

  @override
  String get errorEnterEmail => 'Please enter a valid email address';

  @override
  String welcomeTitle(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get welcomeSubtitle =>
      'Your account is ready. Locked-in somoni prices and delivery to Tajikistan await you.';

  @override
  String get welcomeCta => 'Go to the shop →';

  @override
  String get categories => 'Categories';

  @override
  String get newArrivals => 'New Arrivals';

  @override
  String get seeAll => 'See all';

  @override
  String get browseCatalog => 'Browse catalog';

  @override
  String get allFilter => 'All';

  @override
  String get noProductsFound => 'No products found';

  @override
  String get noProductsInCategory => 'No products in this category';

  @override
  String get selectVariant => 'Select variant';

  @override
  String get addedToCart => 'Added to cart!';

  @override
  String get goToCart => 'Go to cart';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get checkoutButton => 'Checkout';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get pickupInformation =>
      'After checkout, our administrator will assign a pickup point and share collection details with you.';

  @override
  String get noSavedAddresses => 'No saved addresses. Add one in Profile.';

  @override
  String get goToProfile => 'Go to Profile';

  @override
  String get processing => 'Processing...';

  @override
  String get placeOrderAndPay => 'Place order & Pay';

  @override
  String get continuePayment => 'Continue payment';

  @override
  String get paymentDisclaimer =>
      'By placing the order, payment will be processed via Korti Milli.';

  @override
  String get qty => 'Qty';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get orderPlacedLabel => 'Placed';

  @override
  String get orderItemsLabel => 'Items';

  @override
  String get trackingNotAvailable => 'Tracking information not yet available.';

  @override
  String get currentStageLabel => 'Current stage';

  @override
  String get trackingCodeLabel => 'Tracking code';

  @override
  String get stageHistoryLabel => 'Stage history';

  @override
  String get deliveryAddresses => 'Delivery Addresses';

  @override
  String get noAddressesSaved => 'No addresses saved. Tap + to add one.';

  @override
  String get defaultLabel => 'Default';

  @override
  String get addAddressSheetTitle => 'Add Address';

  @override
  String get regionField => 'Region';

  @override
  String get cityField => 'City';

  @override
  String get addressLineField => 'Address line';

  @override
  String get phoneField => 'Phone';

  @override
  String get commentField => 'Comment (optional)';

  @override
  String get saveAddressButton => 'Save address';

  @override
  String get selectRegionHint => 'Select region';

  @override
  String get selectCityHint => 'Select city';

  @override
  String get phoneFromProfileHint => 'From profile';

  @override
  String get fieldRequiredError => 'Required';

  @override
  String get addressPhoneInvalidError => 'Enter a valid phone number';

  @override
  String get addFirstAddressCta => 'Add your first address';

  @override
  String get addAddressTitle => 'Add address';

  @override
  String get editAddressTitle => 'Edit address';

  @override
  String get addressLoadError => 'Could not load this address';

  @override
  String get addAddressCta => 'Add an address';

  @override
  String get deleteAddressConfirmTitle => 'Delete this address?';

  @override
  String get deleteAddressConfirmBody =>
      'This address will be permanently removed.';

  @override
  String get deleteConfirmButton => 'Delete';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get errOutOfStock => 'This item is out of stock';

  @override
  String get errProductUnavailable => 'This product is unavailable';

  @override
  String get errCartEmpty => 'Your cart is empty';

  @override
  String get errOrderAlreadyPaid => 'This order is already paid';

  @override
  String get errOrderNotFound => 'Order not found';

  @override
  String get errPaymentNotFound => 'Payment not found';

  @override
  String get errNoFxRate =>
      'Prices are temporarily unavailable. Please try again later.';

  @override
  String get errValidation => 'Please check the entered data';

  @override
  String get errUnauthorized => 'Please sign in again';

  @override
  String get errForbidden => 'You don\'t have access to this';

  @override
  String get errConflict => 'This action conflicts with the current state';

  @override
  String get errEmailInUse => 'This email is already linked to another account';

  @override
  String get errPhoneInUse =>
      'This phone number is already linked to another account';

  @override
  String get errNotFound => 'Not found';

  @override
  String get stageAwaiting => 'Awaiting';

  @override
  String get stageCnWarehouse => 'At China warehouse';

  @override
  String get stageInTransit => 'In transit';

  @override
  String get stageTjWarehouse => 'At Tajikistan warehouse';

  @override
  String get stageReady => 'Ready for pickup';

  @override
  String get stageDelivered => 'Delivered';

  @override
  String get statusCreated => 'Created';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusOrdered => 'Ordered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get b2bApplyTitle => 'Wholesale application';

  @override
  String get b2bApplyIntro =>
      'Fill in your shop details to get access to the factory wholesale catalog.';

  @override
  String get b2bShopNameLabel => 'Shop name';

  @override
  String get b2bShopNameHint => 'e.g. Dukoni Somon';

  @override
  String get b2bTaxIdLabel => 'Tax ID / INN';

  @override
  String get b2bTaxIdHint => 'Free text';

  @override
  String get b2bCityLabel => 'City';

  @override
  String get b2bCityHint => 'e.g. Dushanbe';

  @override
  String get b2bVolumeLabel => 'Expected volume (optional)';

  @override
  String get b2bVolumeHint => 'e.g. 200 pcs/month';

  @override
  String b2bPhoneFromProfile(String phone) {
    return 'Contact phone: $phone — taken from your profile';
  }

  @override
  String get b2bSubmitApplication => 'Submit application';

  @override
  String get b2bSubmitting => 'Submitting…';

  @override
  String get b2bFieldRequired => 'Fill in this field';

  @override
  String get b2bFieldTooShort => 'Too short';

  @override
  String get b2bFieldTooLong => 'Too long';

  @override
  String get b2bStatusTitle => 'Wholesale access';

  @override
  String get b2bStatusPending => 'Under review';

  @override
  String get b2bStatusApproved => 'Approved';

  @override
  String get b2bStatusRejected => 'Rejected';

  @override
  String get b2bStatusSuspended => 'Suspended';

  @override
  String get b2bPendingBody =>
      'Your application is under review. We will notify you of the decision.';

  @override
  String get b2bApprovedBody => 'Access to the wholesale catalog is open.';

  @override
  String get b2bRejectionLabel => 'Reason for rejection:';

  @override
  String get b2bSuspendedBody => 'Access is suspended. Please contact support.';

  @override
  String get b2bSubmittedData => 'Application details';

  @override
  String get b2bReapply => 'Submit application again';

  @override
  String get b2bNoApplicationTitle => 'You have not applied yet';

  @override
  String get b2bNoApplicationBody =>
      'Apply to get access to the factory wholesale catalog.';

  @override
  String get errorApplicationExists =>
      'You already have an active application.';

  @override
  String get errSellerNotVerified => 'Wholesale verification is required.';

  @override
  String get wholesaleCatalogTitle => 'Wholesale';

  @override
  String get wholesaleCatalogEmptyTitle => 'No products yet';

  @override
  String get wholesaleCatalogEmptyBody =>
      'Factory products will appear here soon';

  @override
  String get wholesaleLockedTitle => 'Access restricted';

  @override
  String get wholesaleLockedBody =>
      'Wholesale prices are available to verified sellers only. Submit an application for verification.';

  @override
  String get wholesaleLockedCta => 'Submit application';

  @override
  String get wholesaleMoqLabel => 'Minimum order:';

  @override
  String get wholesaleQuantityLabel => 'Quantity';

  @override
  String get wholesaleAddToCart => 'Add to cart';

  @override
  String get wholesaleAddedToCart => 'Added to cart';

  @override
  String get wholesaleTiersTitle => 'Price table';

  @override
  String get wholesaleTierSelectHint => 'Tap a tier to set quantity';

  @override
  String get wholesaleTierQtyCol => 'from, pcs';

  @override
  String get wholesaleTierPriceCol => 'Price / pc';

  @override
  String get wholesaleFactoryLabel => 'Factory:';

  @override
  String get factoryCountryLabel => 'Country:';

  @override
  String factoryMoqRange(int min, int max) {
    return 'MOQ: $min – $max pcs';
  }

  @override
  String get factoryDescriptionLabel => 'About the factory';

  @override
  String get factoryContactsLabel => 'Contacts';

  @override
  String get factoryNotFound => 'Factory not found';

  @override
  String get wholesaleCartTitle => 'Wholesale Cart';

  @override
  String get wholesaleCartEmptyTitle => 'Cart is empty';

  @override
  String get wholesaleCartEmptyBody => 'Add products from the factory catalog';

  @override
  String get wholesaleCheckoutTitle => 'Checkout';

  @override
  String get wholesaleOrderSummaryHeading => 'Order summary';

  @override
  String get wholesaleCheckoutCta => 'Confirm and pay';

  @override
  String get wholesaleOrdersTitle => 'My wholesale orders';

  @override
  String get wholesaleOrdersEmptyTitle => 'No orders yet';

  @override
  String get wholesaleOrdersEmptyBody =>
      'Place your first order from the factory catalog';

  @override
  String get wholesaleOrderDetailTitle => 'Order';

  @override
  String get wholesaleOrderItemsHeading => 'Order items';

  @override
  String wholesaleTierApplied(int qty) {
    return 'Tier from $qty pcs.';
  }

  @override
  String wholesaleMoqError(int qty) {
    return 'Minimum $qty pcs.';
  }

  @override
  String get wholesaleOrderTotalLabel => 'Total';

  @override
  String get wholesaleFactorySubtotalLabel => 'Factory subtotal';

  @override
  String get wholesaleCartCheckoutCta => 'Place order';

  @override
  String get wholesaleCartItemRemoveConfirm => 'Remove item from cart?';

  @override
  String get wholesaleCartItemRemoveUndo => 'Undo';

  @override
  String wholesaleCheckoutMoqError(int qty, String name) {
    return 'Minimum $qty units for $name. Update your cart.';
  }

  @override
  String get wholesaleCheckoutReturnToCart => 'Return to cart';

  @override
  String get wholesaleCheckoutProcessing => 'Processing...';

  @override
  String get wholesaleCheckoutProductUnavailable =>
      'One or more products are unavailable. Update your cart.';

  @override
  String get wholesaleCheckoutRetry => 'Try again';

  @override
  String wholesaleMoqChip(int moq) {
    return 'min. $moq pcs.';
  }

  @override
  String get wholesaleCartRemoveItemA11y => 'Remove item';

  @override
  String get wholesaleCartDecreaseQtyA11y => 'Decrease quantity';

  @override
  String get wholesaleCartIncreaseQtyA11y => 'Increase quantity';

  @override
  String get channelChoiceTitle => 'Select mode';

  @override
  String get channelChoiceSubtitle => 'Choose how you want to use ChinaShop';

  @override
  String get channelB2cLabel => 'Retail shopping';

  @override
  String get channelB2cSublabel => 'Shop for yourself';

  @override
  String get channelB2bLabel => 'Wholesale';

  @override
  String get channelB2bSublabel => 'Buy in bulk from factories';

  @override
  String get channelSkip => 'Skip for now';

  @override
  String get b2bHomeTitle => 'B2B Home';

  @override
  String get b2bNavHome => 'Home';

  @override
  String get b2bNavCatalog => 'Catalog';

  @override
  String get b2bNavCart => 'Cart';

  @override
  String get b2bNavOrders => 'Orders';

  @override
  String get b2bNavProfile => 'Profile';

  @override
  String get b2bChannelBannerTitle => 'Wholesale channel';

  @override
  String get b2bChannelBannerSubtitle => 'You are in wholesale mode';

  @override
  String get b2bHomeViewFactories => 'Browse factories';

  @override
  String get b2bHomeMyOrders => 'My wholesale orders';

  @override
  String get switchChannelTitle => 'Switch channel';

  @override
  String get switchToB2cLabel => 'Switch to retail';

  @override
  String get switchToB2cSubtitle => 'Return to regular shopping';

  @override
  String get profileWholesaleMenuLabel => 'Wholesale goods';

  @override
  String get switchToB2bLabel => 'Switch to wholesale';

  @override
  String get switchToB2bSubtitle => 'Access factory catalog and bulk pricing';

  @override
  String get switchChannelConfirmTitle => 'Confirm channel switch';

  @override
  String get switchChannelConfirmB2c => 'Switch to retail mode?';

  @override
  String get switchChannelConfirmB2b => 'Switch to wholesale mode?';

  @override
  String get switchChannelCartNote =>
      'Your cart items are preserved when switching channels.';

  @override
  String get switchChannelConfirmButton => 'Confirm';

  @override
  String get switchChannelCancel => 'Cancel';

  @override
  String get channelSectionTitle => 'Channel';

  @override
  String get b2bApplicationStatusTitle => 'Application status';

  @override
  String get paymentReceiptTitle => 'Payment & receipt';

  @override
  String get paymentAmountLabel => 'Amount to pay';

  @override
  String get paymentOpenLinkCta => 'Open payment link';

  @override
  String get paymentLinkOpenedNote =>
      'Opening the link does NOT confirm payment. After paying, upload your receipt below.';

  @override
  String get paymentNoLinkError =>
      'Payment link is unavailable. Please go back and try again.';

  @override
  String get paymentLinkOpenFailed =>
      'Could not open the payment link. Please try again.';

  @override
  String get receiptStepTitle => 'Upload your receipt';

  @override
  String get receiptStepSubtitle =>
      'Attach a screenshot or photo of your payment confirmation.';

  @override
  String get receiptChooseFromGallery => 'Choose from gallery';

  @override
  String get receiptTakePhoto => 'Take a photo';

  @override
  String get receiptUploading => 'Uploading receipt…';

  @override
  String get receiptAwaitingReviewTitle => 'Receipt received';

  @override
  String get receiptAwaitingReviewBody =>
      'Your receipt is being checked. We will confirm your payment after review.';

  @override
  String get receiptUploadFailed =>
      'Receipt upload failed. Please try a different image.';

  @override
  String get receiptDoneCta => 'Done';

  @override
  String get receiptRetryCta => 'Try again';

  @override
  String get errDuplicateReceipt => 'This receipt has already been uploaded.';

  @override
  String get errReceiptFileInvalid =>
      'Invalid file. Upload a JPEG, PNG or WebP image under 5 MB.';

  @override
  String get errPaymentNotPending =>
      'This payment is no longer awaiting a receipt.';

  @override
  String get errReceiptNotFound => 'Payment not found.';

  @override
  String get errReceiptUploadSuspended =>
      'Receipt uploads are temporarily blocked for a few hours because unrelated images were submitted repeatedly.';

  @override
  String get receiptCheckingTitle => 'Verifying receipt…';

  @override
  String get receiptCheckingBody =>
      'We are checking your receipt. This usually takes a few seconds.';

  @override
  String get receiptApprovedTitle => 'Payment confirmed';

  @override
  String get receiptApprovedBody =>
      'Your payment has been confirmed. Thank you!';

  @override
  String get receiptNeedsReviewTitle => 'Manual review in progress';

  @override
  String get receiptNeedsReviewBody =>
      'Our team is reviewing your receipt. We will notify you shortly.';

  @override
  String get receiptRejectedTitle => 'Receipt rejected';

  @override
  String get receiptRejectedBody =>
      'Your receipt could not be verified. Please upload a clearer image.';

  @override
  String get receiptRejectedReasonLabel => 'Reason:';

  @override
  String get receiptRejectedReasonAmountMismatch =>
      'The amount on the receipt doesn\'t match your order. Check it and upload a new receipt.';

  @override
  String get receiptRejectedReasonReferenceMissing =>
      'We couldn\'t find the transaction number on the receipt. Please upload a clearer receipt.';

  @override
  String get receiptRejectedReasonDuplicate =>
      'This receipt has already been used for another payment. Please upload the correct receipt.';

  @override
  String get receiptRejectedReasonGeneric =>
      'The receipt didn\'t pass automatic verification. Please check it and upload a new one.';

  @override
  String get receiptRejectedReasonNotReceipt =>
      'This image does not contain a payment receipt. Upload a screenshot or photo of the actual receipt.';

  @override
  String get receiptRejectedUploadNewCta => 'Upload a new receipt';

  @override
  String get paymentUnderReview => 'Payment under review';

  @override
  String get b2bBandLogoLabel => 'ChinaShop Business';

  @override
  String get b2bBandGreeting => 'Welcome to ChinaShop Business!';

  @override
  String get b2bBandGreetingSubtitle =>
      'Wholesale direct from factories · price per unit drops with volume';

  @override
  String get b2bBandSearchHint => 'Article, product or factory…';

  @override
  String get b2bSwitchPillBuyerLabel => 'Buyer';

  @override
  String get b2bSwitchPillWholesaleLabel => 'Wholesale B2B';

  @override
  String get b2bKpiOrdersLabel => 'Orders / month';

  @override
  String get b2bKpiTurnoverLabel => 'Turnover';

  @override
  String get b2bKpiSellerStatusLabel => 'Seller status';

  @override
  String get b2bKpiVerifiedValue => 'verified';

  @override
  String get ordersTabAll => 'All';

  @override
  String get ordersTabInTransit => 'In transit';

  @override
  String get ordersTabPaid => 'Paid';

  @override
  String get ordersTabDelivered => 'Delivered';

  @override
  String get pickupCodeTitle => 'Pickup code';

  @override
  String get pickupCodeHelper => 'Show this code to the pickup point employee';

  @override
  String get pickupCodeOfflineBanner =>
      'No connection — showing the saved code';

  @override
  String get pickupCodeDeliveredTitle => 'Order delivered';

  @override
  String get pickupCodeDeliveredBody => 'Thank you for your purchase!';

  @override
  String get showPickupCodeBtn => 'Show pickup code';

  @override
  String get readyForPickupBadge => 'Ready for pickup';

  @override
  String get deliveredCelebrationTitle => 'Congratulations on your purchase!';

  @override
  String get characteristicsLabel => 'Characteristics';

  @override
  String get modelOptionsLabel => 'Model options';

  @override
  String get baseModelLabel => 'Base model';

  @override
  String get selectedModelLabel => 'Selected model';

  @override
  String get soldOutLabel => 'Sold out';

  @override
  String get priceReasonLabel =>
      'Price changes because this model has different characteristics.';

  @override
  String get attrColor => 'Color';

  @override
  String get attrSize => 'Size';

  @override
  String get attrMaterial => 'Material';

  @override
  String get attrWeight => 'Weight';

  @override
  String get attrBrand => 'Brand';

  @override
  String get attrModel => 'Model';

  @override
  String get attrCapacity => 'Capacity';

  @override
  String get attrStorage => 'Memory';

  @override
  String get orderTrackBtn => 'Track';

  @override
  String get orderHelpBtn => 'Help';

  @override
  String get orderDetailsBtn => 'Details';

  @override
  String get orderAgainBtn => 'Order again';

  @override
  String get orderReviewBtn => 'Leave review';

  @override
  String get b2bSectionFactories => 'Factories';

  @override
  String get b2bSectionSeeAll => 'All ›';

  @override
  String get b2bSectionPopular => 'Popular wholesale';

  @override
  String get b2bSectionCatalog => 'Catalog ›';

  @override
  String get b2bFactoryElectronics => 'Electronics';

  @override
  String get b2bFactoryClothing => 'Clothing';

  @override
  String get b2bFactoryHome => 'Home';

  @override
  String b2bFactoryCount(int count) {
    return '$count factories';
  }

  @override
  String get reviewsSectionTitle => 'Reviews';

  @override
  String seeAllReviewsBtn(int count) {
    return 'All reviews ($count)';
  }

  @override
  String get reviewsEmptyTitle => 'No reviews yet';

  @override
  String get reviewsEmptySubtitle =>
      'Be the first to tell us about the product';

  @override
  String get allReviewsTitle => 'All reviews';

  @override
  String get sortNewestChip => 'Newest';

  @override
  String get sortRatingChip => 'By rating';

  @override
  String get hasPhotosChip => 'With photos';

  @override
  String get resetFiltersBtn => 'Reset filters';

  @override
  String get reviewsEmptyFilteredTitle => 'No reviews match these filters';

  @override
  String get reviewsEmptyFilteredSubtitle => 'Try removing some filters';

  @override
  String get loadReviewsError => 'Failed to load reviews';

  @override
  String reviewCountLabel(int count) {
    return '$count reviews';
  }

  @override
  String get reviewEntryCta => 'Rate product';

  @override
  String get reviewFormTitleCreate => 'Rate product';

  @override
  String get reviewFormTitleEdit => 'Edit review';

  @override
  String get reviewSubmitCta => 'Submit';

  @override
  String get reviewSubmitting => 'Submitting…';

  @override
  String get reviewPhotoSourceCamera => 'Camera';

  @override
  String get reviewPhotoSourceGallery => 'Gallery';

  @override
  String get reviewTextHint => 'Tell us about the product (optional)';

  @override
  String get reviewPhotoHelper => 'Up to 5 photos';

  @override
  String get reviewRatingRequiredValidation =>
      'Rate the product — at least one star';

  @override
  String get reviewTextTooLongValidation => 'No more than 1000 characters';

  @override
  String get reviewRatingLabel1 => 'Poor';

  @override
  String get reviewRatingLabel2 => 'Fair';

  @override
  String get reviewRatingLabel3 => 'Okay';

  @override
  String get reviewRatingLabel4 => 'Good';

  @override
  String get reviewRatingLabel5 => 'Excellent';

  @override
  String get errReviewNotEligible =>
      'You are not eligible to review this product';

  @override
  String get errReviewNotFound => 'Review not found';

  @override
  String get errReviewPhotoInvalid =>
      'One of the photos was rejected — replace it and try again';

  @override
  String get errReviewPhotoLimit => 'Too many photos — up to 5 allowed';

  @override
  String get errReviewAlreadyExists => 'You have already reviewed this product';

  @override
  String get reviewOpenExistingCta => 'Open my review';

  @override
  String get reviewRetryCta => 'Retry';

  @override
  String get reviewDiscardTitle => 'Discard changes?';

  @override
  String get reviewDiscardBody => 'Your rating, text, and photos will be lost.';

  @override
  String get reviewDiscardStay => 'Stay';

  @override
  String get reviewDiscardExit => 'Exit';

  @override
  String get reviewSubmitCelebrationTitle => 'Thanks for your review!';

  @override
  String get reportSheetTitle => 'Report review';

  @override
  String get reportCategorySpam => 'Spam or advertising';

  @override
  String get reportCategoryAbusive => 'Abusive content';

  @override
  String get reportCategoryFalse => 'False or irrelevant information';

  @override
  String get reportCategoryPhoto => 'Inappropriate photo';

  @override
  String get reportCategoryOther => 'Other';

  @override
  String get reportCommentHint => 'Comment (optional)';

  @override
  String get reportSubmitBtn => 'Send report';

  @override
  String get reportSubmittedToast => 'Report sent';

  @override
  String get reportedMarkerLabel => 'You reported this';

  @override
  String get reportMenuItem => 'Report';

  @override
  String get editReportMenuItem => 'Edit report';
}
