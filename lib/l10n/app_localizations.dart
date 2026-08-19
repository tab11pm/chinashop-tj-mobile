import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('tg')
  ];

  /// App name shown in headers
  ///
  /// In en, this message translates to:
  /// **'ChinaShop TJ'**
  String get appTitle;

  /// No description provided for @orderActiveItems.
  ///
  /// In en, this message translates to:
  /// **'Active items'**
  String get orderActiveItems;

  /// No description provided for @orderCancelledItems.
  ///
  /// In en, this message translates to:
  /// **'Cancelled items'**
  String get orderCancelledItems;

  /// No description provided for @orderOriginalTotal.
  ///
  /// In en, this message translates to:
  /// **'Original total'**
  String get orderOriginalTotal;

  /// No description provided for @orderCurrentTotal.
  ///
  /// In en, this message translates to:
  /// **'Current total'**
  String get orderCurrentTotal;

  /// No description provided for @orderCancelledTotal.
  ///
  /// In en, this message translates to:
  /// **'Cancelled total'**
  String get orderCancelledTotal;

  /// No description provided for @orderRefundedTotal.
  ///
  /// In en, this message translates to:
  /// **'Refunded total'**
  String get orderRefundedTotal;

  /// No description provided for @orderCancelledItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} cancelled item} other {{count} cancelled items}}'**
  String orderCancelledItemCount(int count);

  /// No description provided for @refundStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Refund pending'**
  String get refundStatusPending;

  /// No description provided for @refundStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund failed'**
  String get refundStatusFailed;

  /// No description provided for @refundStatusManualRequired.
  ///
  /// In en, this message translates to:
  /// **'Manual refund required'**
  String get refundStatusManualRequired;

  /// No description provided for @refundStatusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Refund completed'**
  String get refundStatusSucceeded;

  /// No description provided for @cancellationReasonLogisticsRestricted.
  ///
  /// In en, this message translates to:
  /// **'Logistics restricted'**
  String get cancellationReasonLogisticsRestricted;

  /// No description provided for @cancellationReasonPartnerRejected.
  ///
  /// In en, this message translates to:
  /// **'Partner rejected'**
  String get cancellationReasonPartnerRejected;

  /// No description provided for @cancellationReasonOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get cancellationReasonOutOfStock;

  /// No description provided for @cancellationReasonCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get cancellationReasonCompliance;

  /// No description provided for @cancellationReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancellationReasonOther;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationItemCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order item cancelled'**
  String get notificationItemCancelled;

  /// No description provided for @notificationRefundSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Refund completed'**
  String get notificationRefundSucceeded;

  /// No description provided for @notificationRefundFailed.
  ///
  /// In en, this message translates to:
  /// **'Refund needs attention'**
  String get notificationRefundFailed;

  /// No description provided for @notificationRefundManualRequired.
  ///
  /// In en, this message translates to:
  /// **'Refund is being handled manually'**
  String get notificationRefundManualRequired;

  /// No description provided for @notificationRefundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund amount: {amount} TJS'**
  String notificationRefundAmount(String amount);

  /// Onboarding welcome header
  ///
  /// In en, this message translates to:
  /// **'Welcome to ChinaShop TJ'**
  String get onboardingTitle;

  /// Onboarding subtitle
  ///
  /// In en, this message translates to:
  /// **'Shop from China, delivered to Tajikistan'**
  String get onboardingSubtitle;

  /// Language selection prompt on onboarding screen
  ///
  /// In en, this message translates to:
  /// **'Select your language'**
  String get selectLanguage;

  /// Primary continue/next button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Label for phone number input
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneLabel;

  /// Placeholder hint for phone input (E.164 format)
  ///
  /// In en, this message translates to:
  /// **'+992XXXXXXXXX'**
  String get phoneHint;

  /// Button to request OTP SMS
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendOtpButton;

  /// Label for OTP code input
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get otpLabel;

  /// Placeholder hint for OTP input
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpHint;

  /// Button to verify OTP code
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// Home screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// Catalog screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// Category screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryTitle;

  /// Product detail screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productTitle;

  /// Cart screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// Message shown when cart has no items
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// Cart footer discount row label
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get cartDiscount;

  /// Cart promo banner text
  ///
  /// In en, this message translates to:
  /// **'Discounts already applied'**
  String get cartPromoLine;

  /// FX rate info line in cart footer
  ///
  /// In en, this message translates to:
  /// **'≈ {cny} ¥ · rate locked at order'**
  String cartFxLine(String cny);

  /// Checkout screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// Orders list screen app bar title
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get ordersTitle;

  /// Order detail screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailTitle;

  /// Favorites screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// Profile screen app bar title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Fallback display name for profile hero when name is null
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileAnonymous;

  /// Edit profile button label in profile hero card
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEditCta;

  /// Name field label in profile edit form
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileNameLabel;

  /// Phone field label in profile edit form
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// Title of edit profile screen
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditTitle;

  /// Success snackbar after profile edit
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileEditSaved;

  /// Language preference label in profile
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Logout button label
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// Generic loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// Generic error message fallback
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Network/connectivity error message
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetwork;

  /// Price label used near PriceTag widgets
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// Add to cart button on product screen
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// Remove item from cart button label
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromCart;

  /// Quantity label for cart items
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// Order status label in order detail
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderStatus;

  /// Order total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// Shipment tracking stage label
  ///
  /// In en, this message translates to:
  /// **'Shipment stage'**
  String get shipmentStage;

  /// Submit order button on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get placeOrderButton;

  /// Initiate payment button on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNowButton;

  /// Add product to favorites button
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Remove product from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Empty state message on favorites screen
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// Empty state message on orders list
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrders;

  /// Search input placeholder in catalog
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchHint;

  /// Filter chip to show all categories
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// Address selector label on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Select delivery address'**
  String get selectAddress;

  /// FAB label to add a new address on profile screen
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// Address section header in profile
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Retry button in error widget
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Shipment tracking section header
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingTitle;

  /// Variant selector label on product screen
  ///
  /// In en, this message translates to:
  /// **'Variant'**
  String get variantLabel;

  /// Auth screen title for phone entry step
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneTitle;

  /// Auth screen title for OTP entry step
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterOtpTitle;

  /// Subtitle shown after OTP SMS sent
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String sentOtpSubtitle(String phone);

  /// Subtitle on phone entry step explaining SMS will be sent
  ///
  /// In en, this message translates to:
  /// **'We will send you a verification code via SMS.'**
  String get sendSmsSubtitle;

  /// Leading text of the OTP-step subtitle, followed by the bold phone number and a Change link
  ///
  /// In en, this message translates to:
  /// **'We sent an SMS to '**
  String get sentOtpSubtitlePrefix;

  /// Button to request a new OTP code
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Inline link on the OTP step to go back and edit the phone number
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changePhoneLink;

  /// Resend countdown label shown while the resend cooldown is active
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}'**
  String resendCodeIn(String seconds);

  /// Legal disclaimer footer on the phone-entry auth step
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the Terms and Privacy Policy'**
  String get authLegalText;

  /// Validation error when phone field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get errorEnterPhone;

  /// Validation error when OTP field is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get errorEnterCode;

  /// Step indicator label on the post-OTP profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Step 3 of 3 · Almost done'**
  String get profileSetupStep;

  /// Title of the post-OTP profile setup (name+email) screen
  ///
  /// In en, this message translates to:
  /// **'Let\'s get acquainted'**
  String get profileSetupTitle;

  /// Subtitle of the post-OTP profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Fill in your profile — needed for receipts, notifications, and support.'**
  String get profileSetupSubtitle;

  /// Label for the name field on profile setup
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// Placeholder text for the name field on profile setup
  ///
  /// In en, this message translates to:
  /// **'Farrukh Raufov'**
  String get nameHint;

  /// Label for the email field on profile setup
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// Placeholder text for the email field on profile setup
  ///
  /// In en, this message translates to:
  /// **'farrukh@example.com'**
  String get emailHint;

  /// Hint text below the email field on profile setup
  ///
  /// In en, this message translates to:
  /// **'We need your email to send e-receipts and order confirmations.'**
  String get emailHelpText;

  /// CTA button on the profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Done, let\'s shop! →'**
  String get profileSetupCta;

  /// Validation error when name field is empty on profile setup
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get errorEnterName;

  /// Validation error when email field is empty or invalid on profile setup
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get errorEnterEmail;

  /// Title on the post-profile-setup welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeTitle(String name);

  /// Subtitle on the post-profile-setup welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Locked-in somoni prices and delivery to Tajikistan await you.'**
  String get welcomeSubtitle;

  /// CTA button on the post-profile-setup welcome screen
  ///
  /// In en, this message translates to:
  /// **'Go to the shop →'**
  String get welcomeCta;

  /// Home screen categories section header
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Home screen new arrivals section header
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get newArrivals;

  /// Link to see full list in a section
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// CTA button on empty states (cart, favorites) to navigate to catalog
  ///
  /// In en, this message translates to:
  /// **'Browse catalog'**
  String get browseCatalog;

  /// Filter chip to show all products (no category filter)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// Empty state when catalog search returns no results
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// Empty state on category screen when no products exist
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noProductsInCategory;

  /// Label for variant selector on product screen
  ///
  /// In en, this message translates to:
  /// **'Select variant'**
  String get selectVariant;

  /// SnackBar confirmation after adding product to cart
  ///
  /// In en, this message translates to:
  /// **'Added to cart!'**
  String get addedToCart;

  /// SnackBar action label to navigate to the cart after adding a product
  ///
  /// In en, this message translates to:
  /// **'Go to cart'**
  String get goToCart;

  /// Subtotal price label in cart
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// Number of items in cart with plural form
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item} other{{count} items}}'**
  String itemCount(int count);

  /// Checkout CTA button in cart screen
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutButton;

  /// Order summary section header on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// Delivery address section header on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// Retail checkout explanation that pickup point is assigned by staff
  ///
  /// In en, this message translates to:
  /// **'After checkout, our administrator will assign a pickup point and share collection details with you.'**
  String get pickupInformation;

  /// Message shown on checkout when no address is saved
  ///
  /// In en, this message translates to:
  /// **'No saved addresses. Add one in Profile.'**
  String get noSavedAddresses;

  /// Navigation button to profile screen from checkout
  ///
  /// In en, this message translates to:
  /// **'Go to Profile'**
  String get goToProfile;

  /// Loading text while order is being placed
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Final order placement button on checkout screen
  ///
  /// In en, this message translates to:
  /// **'Place order & Pay'**
  String get placeOrderAndPay;

  /// Button to resume payment for an order placed but not yet paid (status=created)
  ///
  /// In en, this message translates to:
  /// **'Continue payment'**
  String get continuePayment;

  /// Payment disclaimer text on checkout screen
  ///
  /// In en, this message translates to:
  /// **'By placing the order, payment will be processed via Korti Milli.'**
  String get paymentDisclaimer;

  /// Quantity abbreviation label in order summary rows
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// Order list item title with order ID
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// Label for order placement date in order detail
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get orderPlacedLabel;

  /// Items section header in order detail
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get orderItemsLabel;

  /// Message shown when no tracking info exists yet
  ///
  /// In en, this message translates to:
  /// **'Tracking information not yet available.'**
  String get trackingNotAvailable;

  /// Label for current shipment stage in tracking view
  ///
  /// In en, this message translates to:
  /// **'Current stage'**
  String get currentStageLabel;

  /// Label for shipment tracking code
  ///
  /// In en, this message translates to:
  /// **'Tracking code'**
  String get trackingCodeLabel;

  /// Label for historical shipment stage list
  ///
  /// In en, this message translates to:
  /// **'Stage history'**
  String get stageHistoryLabel;

  /// Delivery addresses section header in profile
  ///
  /// In en, this message translates to:
  /// **'Delivery Addresses'**
  String get deliveryAddresses;

  /// Empty state text when no addresses have been saved
  ///
  /// In en, this message translates to:
  /// **'No addresses saved. Tap + to add one.'**
  String get noAddressesSaved;

  /// Badge shown on the default address
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// Title of the bottom sheet for adding an address
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddressSheetTitle;

  /// Input field label for region/province
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get regionField;

  /// Input field label for city
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityField;

  /// Input field label for street address line
  ///
  /// In en, this message translates to:
  /// **'Address line'**
  String get addressLineField;

  /// Input field label for phone number in address form
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneField;

  /// Optional comment field in address form
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentField;

  /// Submit button in the add address bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddressButton;

  /// Dropdown hint text for region selector in address form
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get selectRegionHint;

  /// Dropdown hint text for city selector in address form
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get selectCityHint;

  /// Hint text for read-only phone field in address form, indicating the value comes from the user profile
  ///
  /// In en, this message translates to:
  /// **'From profile'**
  String get phoneFromProfileHint;

  /// Inline validation error shown under an empty required form field
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequiredError;

  /// Inline validation error shown when the address phone field digits do not match the expected length
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get addressPhoneInvalidError;

  /// Empty-state action label prompting the user to add their first saved address
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get addFirstAddressCta;

  /// App bar title for the address form screen in add mode
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddressTitle;

  /// App bar title for the address form screen in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get editAddressTitle;

  /// Shown on the edit-address screen when the address cannot be resolved (cold deep-link, stale cache, or fetch failure) — the form is blocked from rendering until it loads
  ///
  /// In en, this message translates to:
  /// **'Could not load this address'**
  String get addressLoadError;

  /// CTA label that routes the user to the add-address screen (e.g. from checkout's empty address state)
  ///
  /// In en, this message translates to:
  /// **'Add an address'**
  String get addAddressCta;

  /// Title of the confirmation dialog shown before permanently deleting a saved address
  ///
  /// In en, this message translates to:
  /// **'Delete this address?'**
  String get deleteAddressConfirmTitle;

  /// Body text of the delete-address confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This address will be permanently removed.'**
  String get deleteAddressConfirmBody;

  /// Destructive confirm button label in the delete-address confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmButton;

  /// Generic cancel action label, e.g. dismissing a confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Error message for errOutOfStock
  ///
  /// In en, this message translates to:
  /// **'This item is out of stock'**
  String get errOutOfStock;

  /// Error message for errProductUnavailable
  ///
  /// In en, this message translates to:
  /// **'This product is unavailable'**
  String get errProductUnavailable;

  /// Error message for errCartEmpty
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get errCartEmpty;

  /// Error message for errOrderAlreadyPaid
  ///
  /// In en, this message translates to:
  /// **'This order is already paid'**
  String get errOrderAlreadyPaid;

  /// Error message for errOrderNotFound
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get errOrderNotFound;

  /// Error message for errPaymentNotFound
  ///
  /// In en, this message translates to:
  /// **'Payment not found'**
  String get errPaymentNotFound;

  /// Error message for errNoFxRate
  ///
  /// In en, this message translates to:
  /// **'Prices are temporarily unavailable. Please try again later.'**
  String get errNoFxRate;

  /// Error message for errValidation
  ///
  /// In en, this message translates to:
  /// **'Please check the entered data'**
  String get errValidation;

  /// Error message for errUnauthorized
  ///
  /// In en, this message translates to:
  /// **'Please sign in again'**
  String get errUnauthorized;

  /// Error message for errForbidden
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this'**
  String get errForbidden;

  /// Error message for errConflict
  ///
  /// In en, this message translates to:
  /// **'This action conflicts with the current state'**
  String get errConflict;

  /// Profile setup: submitted email already belongs to another account
  ///
  /// In en, this message translates to:
  /// **'This email is already linked to another account'**
  String get errEmailInUse;

  /// Profile setup: submitted phone already belongs to another account
  ///
  /// In en, this message translates to:
  /// **'This phone number is already linked to another account'**
  String get errPhoneInUse;

  /// Error message for errNotFound
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errNotFound;

  /// Shipment stage label: stageAwaiting
  ///
  /// In en, this message translates to:
  /// **'Awaiting'**
  String get stageAwaiting;

  /// Shipment stage label: stageCnWarehouse
  ///
  /// In en, this message translates to:
  /// **'At China warehouse'**
  String get stageCnWarehouse;

  /// Shipment stage label: stageInTransit
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get stageInTransit;

  /// Shipment stage label: stageTjWarehouse
  ///
  /// In en, this message translates to:
  /// **'At Tajikistan warehouse'**
  String get stageTjWarehouse;

  /// Shipment stage label: stageReady
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get stageReady;

  /// Shipment stage label: stageDelivered
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stageDelivered;

  /// Order status: statusCreated
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get statusCreated;

  /// Order status: statusPaid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// Order status: statusOrdered
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get statusOrdered;

  /// Order status: statusCancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Order status: statusRefunded
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// B2B apply screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Wholesale application'**
  String get b2bApplyTitle;

  /// B2B apply screen intro lede
  ///
  /// In en, this message translates to:
  /// **'Fill in your shop details to get access to the factory wholesale catalog.'**
  String get b2bApplyIntro;

  /// B2B form: shop name field label
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get b2bShopNameLabel;

  /// B2B form: shop name field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Dukoni Somon'**
  String get b2bShopNameHint;

  /// B2B form: tax id field label
  ///
  /// In en, this message translates to:
  /// **'Tax ID / INN'**
  String get b2bTaxIdLabel;

  /// B2B form: tax id field hint
  ///
  /// In en, this message translates to:
  /// **'Free text'**
  String get b2bTaxIdHint;

  /// B2B form: city field label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get b2bCityLabel;

  /// B2B form: city field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Dushanbe'**
  String get b2bCityHint;

  /// B2B form: expected volume field label
  ///
  /// In en, this message translates to:
  /// **'Expected volume (optional)'**
  String get b2bVolumeLabel;

  /// B2B form: expected volume field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 200 pcs/month'**
  String get b2bVolumeHint;

  /// B2B form: read-only phone helper note
  ///
  /// In en, this message translates to:
  /// **'Contact phone: {phone} — taken from your profile'**
  String b2bPhoneFromProfile(String phone);

  /// B2B form primary CTA
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get b2bSubmitApplication;

  /// B2B form CTA processing state
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get b2bSubmitting;

  /// B2B form validation: empty required field
  ///
  /// In en, this message translates to:
  /// **'Fill in this field'**
  String get b2bFieldRequired;

  /// B2B form validation: value too short
  ///
  /// In en, this message translates to:
  /// **'Too short'**
  String get b2bFieldTooShort;

  /// B2B form validation: value too long
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get b2bFieldTooLong;

  /// B2B status screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Wholesale access'**
  String get b2bStatusTitle;

  /// B2B status label: pending
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get b2bStatusPending;

  /// B2B status label: approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get b2bStatusApproved;

  /// B2B status label: rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get b2bStatusRejected;

  /// B2B status label: suspended
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get b2bStatusSuspended;

  /// B2B status body: pending
  ///
  /// In en, this message translates to:
  /// **'Your application is under review. We will notify you of the decision.'**
  String get b2bPendingBody;

  /// B2B status body: approved
  ///
  /// In en, this message translates to:
  /// **'Access to the wholesale catalog is open.'**
  String get b2bApprovedBody;

  /// B2B status: rejection note label
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection:'**
  String get b2bRejectionLabel;

  /// B2B status body: suspended
  ///
  /// In en, this message translates to:
  /// **'Access is suspended. Please contact support.'**
  String get b2bSuspendedBody;

  /// B2B status: submitted-data card heading
  ///
  /// In en, this message translates to:
  /// **'Application details'**
  String get b2bSubmittedData;

  /// B2B status: re-apply CTA (rejected only)
  ///
  /// In en, this message translates to:
  /// **'Submit application again'**
  String get b2bReapply;

  /// B2B status: empty-state heading
  ///
  /// In en, this message translates to:
  /// **'You have not applied yet'**
  String get b2bNoApplicationTitle;

  /// B2B status: empty-state body
  ///
  /// In en, this message translates to:
  /// **'Apply to get access to the factory wholesale catalog.'**
  String get b2bNoApplicationBody;

  /// Error: SELLER_APPLICATION_ALREADY_EXISTS
  ///
  /// In en, this message translates to:
  /// **'You already have an active application.'**
  String get errorApplicationExists;

  /// Error: SELLER_NOT_VERIFIED
  ///
  /// In en, this message translates to:
  /// **'Wholesale verification is required.'**
  String get errSellerNotVerified;

  /// Wholesale catalog screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get wholesaleCatalogTitle;

  /// Wholesale catalog empty state heading
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get wholesaleCatalogEmptyTitle;

  /// Wholesale catalog empty state body
  ///
  /// In en, this message translates to:
  /// **'Factory products will appear here soon'**
  String get wholesaleCatalogEmptyBody;

  /// Wholesale locked/403 screen heading
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get wholesaleLockedTitle;

  /// Wholesale locked/403 screen body
  ///
  /// In en, this message translates to:
  /// **'Wholesale prices are available to verified sellers only. Submit an application for verification.'**
  String get wholesaleLockedBody;

  /// CTA on wholesale locked screen
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get wholesaleLockedCta;

  /// MOQ label on product detail screen
  ///
  /// In en, this message translates to:
  /// **'Minimum order:'**
  String get wholesaleMoqLabel;

  /// Quantity selector label on wholesale product detail
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get wholesaleQuantityLabel;

  /// Add-to-cart button on wholesale product detail
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get wholesaleAddToCart;

  /// Success snackbar after adding wholesale product to cart
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get wholesaleAddedToCart;

  /// Tier table section title on product detail
  ///
  /// In en, this message translates to:
  /// **'Price table'**
  String get wholesaleTiersTitle;

  /// Hint under the tier table prompting the user to tap a tier to pick the order volume
  ///
  /// In en, this message translates to:
  /// **'Tap a tier to set quantity'**
  String get wholesaleTierSelectHint;

  /// Tier table column header: min quantity
  ///
  /// In en, this message translates to:
  /// **'from, pcs'**
  String get wholesaleTierQtyCol;

  /// Tier table column header: unit price
  ///
  /// In en, this message translates to:
  /// **'Price / pc'**
  String get wholesaleTierPriceCol;

  /// Factory row label on product detail
  ///
  /// In en, this message translates to:
  /// **'Factory:'**
  String get wholesaleFactoryLabel;

  /// Country label on factory profile
  ///
  /// In en, this message translates to:
  /// **'Country:'**
  String get factoryCountryLabel;

  /// MOQ range label on factory profile
  ///
  /// In en, this message translates to:
  /// **'MOQ: {min} – {max} pcs'**
  String factoryMoqRange(int min, int max);

  /// Description section label on factory profile
  ///
  /// In en, this message translates to:
  /// **'About the factory'**
  String get factoryDescriptionLabel;

  /// Contacts section label on factory profile
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get factoryContactsLabel;

  /// Empty state when factory is not found (404)
  ///
  /// In en, this message translates to:
  /// **'Factory not found'**
  String get factoryNotFound;

  /// Wholesale cart screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Wholesale Cart'**
  String get wholesaleCartTitle;

  /// Wholesale cart empty state heading
  ///
  /// In en, this message translates to:
  /// **'Cart is empty'**
  String get wholesaleCartEmptyTitle;

  /// Wholesale cart empty state body
  ///
  /// In en, this message translates to:
  /// **'Add products from the factory catalog'**
  String get wholesaleCartEmptyBody;

  /// Wholesale checkout screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get wholesaleCheckoutTitle;

  /// Wholesale checkout order summary section heading
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get wholesaleOrderSummaryHeading;

  /// Wholesale checkout primary CTA button
  ///
  /// In en, this message translates to:
  /// **'Confirm and pay'**
  String get wholesaleCheckoutCta;

  /// Wholesale orders list screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'My wholesale orders'**
  String get wholesaleOrdersTitle;

  /// Wholesale orders empty state heading
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get wholesaleOrdersEmptyTitle;

  /// Wholesale orders empty state body
  ///
  /// In en, this message translates to:
  /// **'Place your first order from the factory catalog'**
  String get wholesaleOrdersEmptyBody;

  /// Wholesale order detail screen AppBar prefix
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get wholesaleOrderDetailTitle;

  /// Wholesale order detail items section heading
  ///
  /// In en, this message translates to:
  /// **'Order items'**
  String get wholesaleOrderItemsHeading;

  /// Applied tier label (ICU placeholder qty: int)
  ///
  /// In en, this message translates to:
  /// **'Tier from {qty} pcs.'**
  String wholesaleTierApplied(int qty);

  /// MOQ inline error on cart item (ICU placeholder qty: int)
  ///
  /// In en, this message translates to:
  /// **'Minimum {qty} pcs.'**
  String wholesaleMoqError(int qty);

  /// Total label in checkout and order detail
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get wholesaleOrderTotalLabel;

  /// Per-factory subtotal in wholesale checkout
  ///
  /// In en, this message translates to:
  /// **'Factory subtotal'**
  String get wholesaleFactorySubtotalLabel;

  /// Sticky bottom bar CTA in wholesale cart
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get wholesaleCartCheckoutCta;

  /// Swipe-delete confirmation snackbar undo label
  ///
  /// In en, this message translates to:
  /// **'Remove item from cart?'**
  String get wholesaleCartItemRemoveConfirm;

  /// Snackbar undo action after removing cart item
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get wholesaleCartItemRemoveUndo;

  /// Checkout MOQ_NOT_MET error banner (ICU qty: int, name: String)
  ///
  /// In en, this message translates to:
  /// **'Minimum {qty} units for {name}. Update your cart.'**
  String wholesaleCheckoutMoqError(int qty, String name);

  /// Button on checkout MOQ error — return to cart
  ///
  /// In en, this message translates to:
  /// **'Return to cart'**
  String get wholesaleCheckoutReturnToCart;

  /// Button label while checkout is processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get wholesaleCheckoutProcessing;

  /// Checkout FACTORY_PRODUCT_UNAVAILABLE error banner
  ///
  /// In en, this message translates to:
  /// **'One or more products are unavailable. Update your cart.'**
  String get wholesaleCheckoutProductUnavailable;

  /// Generic checkout error retry button
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get wholesaleCheckoutRetry;

  /// MOQ chip on wholesale product card and detail (ICU placeholder moq: int)
  ///
  /// In en, this message translates to:
  /// **'min. {moq} pcs.'**
  String wholesaleMoqChip(int moq);

  /// Accessibility label for swipe-delete in wholesale cart
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get wholesaleCartRemoveItemA11y;

  /// Accessibility label for the minus button in wholesale cart
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get wholesaleCartDecreaseQtyA11y;

  /// Accessibility label for the plus button in wholesale cart
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get wholesaleCartIncreaseQtyA11y;

  /// Channel choice screen heading
  ///
  /// In en, this message translates to:
  /// **'Select mode'**
  String get channelChoiceTitle;

  /// Channel choice screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use ChinaShop'**
  String get channelChoiceSubtitle;

  /// B2C channel card label
  ///
  /// In en, this message translates to:
  /// **'Retail shopping'**
  String get channelB2cLabel;

  /// B2C channel card sublabel
  ///
  /// In en, this message translates to:
  /// **'Shop for yourself'**
  String get channelB2cSublabel;

  /// B2B channel card label
  ///
  /// In en, this message translates to:
  /// **'Wholesale'**
  String get channelB2bLabel;

  /// B2B channel card sublabel
  ///
  /// In en, this message translates to:
  /// **'Buy in bulk from factories'**
  String get channelB2bSublabel;

  /// Skip channel choice button
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get channelSkip;

  /// B2B shell home tab title
  ///
  /// In en, this message translates to:
  /// **'B2B Home'**
  String get b2bHomeTitle;

  /// B2B bottom nav: home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get b2bNavHome;

  /// B2B bottom nav: wholesale catalog
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get b2bNavCatalog;

  /// B2B bottom nav: wholesale cart
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get b2bNavCart;

  /// B2B bottom nav: wholesale orders
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get b2bNavOrders;

  /// B2B bottom nav: profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get b2bNavProfile;

  /// B2B home channel banner title
  ///
  /// In en, this message translates to:
  /// **'Wholesale channel'**
  String get b2bChannelBannerTitle;

  /// B2B home channel banner subtitle
  ///
  /// In en, this message translates to:
  /// **'You are in wholesale mode'**
  String get b2bChannelBannerSubtitle;

  /// B2B home button to browse factories
  ///
  /// In en, this message translates to:
  /// **'Browse factories'**
  String get b2bHomeViewFactories;

  /// B2B home button to view wholesale orders
  ///
  /// In en, this message translates to:
  /// **'My wholesale orders'**
  String get b2bHomeMyOrders;

  /// Switch channel action title
  ///
  /// In en, this message translates to:
  /// **'Switch channel'**
  String get switchChannelTitle;

  /// Switch to B2C channel label
  ///
  /// In en, this message translates to:
  /// **'Switch to retail'**
  String get switchToB2cLabel;

  /// Switch to B2C channel subtitle
  ///
  /// In en, this message translates to:
  /// **'Return to regular shopping'**
  String get switchToB2cSubtitle;

  /// Profile menu row label for wholesale entry
  ///
  /// In en, this message translates to:
  /// **'Wholesale goods'**
  String get profileWholesaleMenuLabel;

  /// Switch to B2B channel label
  ///
  /// In en, this message translates to:
  /// **'Switch to wholesale'**
  String get switchToB2bLabel;

  /// Switch to B2B channel subtitle
  ///
  /// In en, this message translates to:
  /// **'Access factory catalog and bulk pricing'**
  String get switchToB2bSubtitle;

  /// Channel switch confirmation title
  ///
  /// In en, this message translates to:
  /// **'Confirm channel switch'**
  String get switchChannelConfirmTitle;

  /// Channel switch confirm dialog: switching to B2C
  ///
  /// In en, this message translates to:
  /// **'Switch to retail mode?'**
  String get switchChannelConfirmB2c;

  /// Channel switch confirm dialog: switching to B2B
  ///
  /// In en, this message translates to:
  /// **'Switch to wholesale mode?'**
  String get switchChannelConfirmB2b;

  /// Note shown in channel switch confirmation that carts are preserved
  ///
  /// In en, this message translates to:
  /// **'Your cart items are preserved when switching channels.'**
  String get switchChannelCartNote;

  /// Confirm channel switch button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get switchChannelConfirmButton;

  /// Cancel channel switch button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get switchChannelCancel;

  /// Channel section heading in B2B profile
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channelSectionTitle;

  /// B2B application status section title in B2B profile
  ///
  /// In en, this message translates to:
  /// **'Application status'**
  String get b2bApplicationStatusTitle;

  /// Payment receipt flow screen AppBar title
  ///
  /// In en, this message translates to:
  /// **'Payment & receipt'**
  String get paymentReceiptTitle;

  /// Label above the amount in the receipt flow
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get paymentAmountLabel;

  /// Button that opens the pay.dc.tj payment link externally
  ///
  /// In en, this message translates to:
  /// **'Open payment link'**
  String get paymentOpenLinkCta;

  /// Explicit note that opening the link is not payment confirmation
  ///
  /// In en, this message translates to:
  /// **'Opening the link does NOT confirm payment. After paying, upload your receipt below.'**
  String get paymentLinkOpenedNote;

  /// Shown when the backend returned no redirect link
  ///
  /// In en, this message translates to:
  /// **'Payment link is unavailable. Please go back and try again.'**
  String get paymentNoLinkError;

  /// Shown when launchUrl fails to open the payment link
  ///
  /// In en, this message translates to:
  /// **'Could not open the payment link. Please try again.'**
  String get paymentLinkOpenFailed;

  /// Heading for the receipt upload step
  ///
  /// In en, this message translates to:
  /// **'Upload your receipt'**
  String get receiptStepTitle;

  /// Subtitle explaining what to upload
  ///
  /// In en, this message translates to:
  /// **'Attach a screenshot or photo of your payment confirmation.'**
  String get receiptStepSubtitle;

  /// Button to pick a receipt image from the gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get receiptChooseFromGallery;

  /// Button to capture a receipt photo with the camera
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get receiptTakePhoto;

  /// Progress label while the receipt is uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading receipt…'**
  String get receiptUploading;

  /// Title shown after a successful receipt upload
  ///
  /// In en, this message translates to:
  /// **'Receipt received'**
  String get receiptAwaitingReviewTitle;

  /// Body explaining the receipt is awaiting AI/manual review
  ///
  /// In en, this message translates to:
  /// **'Your receipt is being checked. We will confirm your payment after review.'**
  String get receiptAwaitingReviewBody;

  /// Generic receipt upload error
  ///
  /// In en, this message translates to:
  /// **'Receipt upload failed. Please try a different image.'**
  String get receiptUploadFailed;

  /// Button to leave the receipt flow after upload succeeds
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get receiptDoneCta;

  /// Button to retry picking a receipt after an error
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get receiptRetryCta;

  /// Error: DUPLICATE_RECEIPT
  ///
  /// In en, this message translates to:
  /// **'This receipt has already been uploaded.'**
  String get errDuplicateReceipt;

  /// Error: RECEIPT_FILE_INVALID
  ///
  /// In en, this message translates to:
  /// **'Invalid file. Upload a JPEG, PNG or WebP image under 5 MB.'**
  String get errReceiptFileInvalid;

  /// Error: PAYMENT_NOT_PENDING
  ///
  /// In en, this message translates to:
  /// **'This payment is no longer awaiting a receipt.'**
  String get errPaymentNotPending;

  /// Error: RECEIPT_NOT_FOUND
  ///
  /// In en, this message translates to:
  /// **'Payment not found.'**
  String get errReceiptNotFound;

  /// No description provided for @errReceiptUploadSuspended.
  ///
  /// In en, this message translates to:
  /// **'Receipt uploads are temporarily blocked for a few hours because unrelated images were submitted repeatedly.'**
  String get errReceiptUploadSuspended;

  /// Title shown while AI is verifying the uploaded receipt (checking status)
  ///
  /// In en, this message translates to:
  /// **'Verifying receipt…'**
  String get receiptCheckingTitle;

  /// Body text shown under the spinner while the receipt is being verified
  ///
  /// In en, this message translates to:
  /// **'We are checking your receipt. This usually takes a few seconds.'**
  String get receiptCheckingBody;

  /// Title shown when the receipt was approved (approved_by_ai or approved_manually)
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get receiptApprovedTitle;

  /// Body text shown after the receipt is approved
  ///
  /// In en, this message translates to:
  /// **'Your payment has been confirmed. Thank you!'**
  String get receiptApprovedBody;

  /// Title shown when the receipt requires manual operator review
  ///
  /// In en, this message translates to:
  /// **'Manual review in progress'**
  String get receiptNeedsReviewTitle;

  /// Body text shown when the receipt is queued for manual review
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing your receipt. We will notify you shortly.'**
  String get receiptNeedsReviewBody;

  /// Title shown when the receipt was rejected
  ///
  /// In en, this message translates to:
  /// **'Receipt rejected'**
  String get receiptRejectedTitle;

  /// Body text asking the user to re-upload after rejection
  ///
  /// In en, this message translates to:
  /// **'Your receipt could not be verified. Please upload a clearer image.'**
  String get receiptRejectedBody;

  /// Label shown before the admin rejection reason in the rejected state card (ADMREC-04)
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get receiptRejectedReasonLabel;

  /// Client-safe reason shown for an AI rejection categorized as amount mismatch (no exact amounts exposed)
  ///
  /// In en, this message translates to:
  /// **'The amount on the receipt doesn\'t match your order. Check it and upload a new receipt.'**
  String get receiptRejectedReasonAmountMismatch;

  /// Client-safe reason shown for an AI rejection categorized as missing transaction reference
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find the transaction number on the receipt. Please upload a clearer receipt.'**
  String get receiptRejectedReasonReferenceMissing;

  /// Client-safe reason shown for an AI rejection categorized as a duplicate receipt
  ///
  /// In en, this message translates to:
  /// **'This receipt has already been used for another payment. Please upload the correct receipt.'**
  String get receiptRejectedReasonDuplicate;

  /// Client-safe generic reason shown for an AI rejection with no specific category
  ///
  /// In en, this message translates to:
  /// **'The receipt didn\'t pass automatic verification. Please check it and upload a new one.'**
  String get receiptRejectedReasonGeneric;

  /// No description provided for @receiptRejectedReasonNotReceipt.
  ///
  /// In en, this message translates to:
  /// **'This image does not contain a payment receipt. Upload a screenshot or photo of the actual receipt.'**
  String get receiptRejectedReasonNotReceipt;

  /// Primary CTA on the rejected state card to upload a replacement receipt for the same payment (ADMREC-04)
  ///
  /// In en, this message translates to:
  /// **'Upload a new receipt'**
  String get receiptRejectedUploadNewCta;

  /// Non-actionable status shown instead of pay button when customer has uploaded a receipt under AI/manual review
  ///
  /// In en, this message translates to:
  /// **'Payment under review'**
  String get paymentUnderReview;

  /// Brand label in the B2B dark header band top row (logo + text)
  ///
  /// In en, this message translates to:
  /// **'ChinaShop Business'**
  String get b2bBandLogoLabel;

  /// Greeting headline in the B2B dark header band
  ///
  /// In en, this message translates to:
  /// **'Welcome to ChinaShop Business!'**
  String get b2bBandGreeting;

  /// Muted subtitle line below the greeting in the B2B dark header band
  ///
  /// In en, this message translates to:
  /// **'Wholesale direct from factories · price per unit drops with volume'**
  String get b2bBandGreetingSubtitle;

  /// Placeholder text inside the non-functional search bar in the B2B dark header band
  ///
  /// In en, this message translates to:
  /// **'Article, product or factory…'**
  String get b2bBandSearchHint;

  /// Inactive B2C segment label in the channel-switch pill inside the B2B header band
  ///
  /// In en, this message translates to:
  /// **'Buyer'**
  String get b2bSwitchPillBuyerLabel;

  /// Active B2B segment label in the channel-switch pill inside the B2B header band
  ///
  /// In en, this message translates to:
  /// **'Wholesale B2B'**
  String get b2bSwitchPillWholesaleLabel;

  /// KPI tile label: orders this calendar month count
  ///
  /// In en, this message translates to:
  /// **'Orders / month'**
  String get b2bKpiOrdersLabel;

  /// KPI tile label: total TJS turnover this calendar month
  ///
  /// In en, this message translates to:
  /// **'Turnover'**
  String get b2bKpiTurnoverLabel;

  /// KPI tile label: seller verification status
  ///
  /// In en, this message translates to:
  /// **'Seller status'**
  String get b2bKpiSellerStatusLabel;

  /// Static value shown in the seller-status KPI tile for verified sellers
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get b2bKpiVerifiedValue;

  /// Orders screen filter tab: show all orders
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ordersTabAll;

  /// Orders screen filter tab: orders in transit (paid through ready statuses)
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get ordersTabInTransit;

  /// Orders screen filter tab: orders with paid or placed_on_pinduoduo status
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get ordersTabPaid;

  /// Orders screen filter tab: orders with delivered status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ordersTabDelivered;

  /// App bar title for the pickup QR/code screen
  ///
  /// In en, this message translates to:
  /// **'Pickup code'**
  String get pickupCodeTitle;

  /// Helper text under the QR and grouped pickup code
  ///
  /// In en, this message translates to:
  /// **'Show this code to the pickup point employee'**
  String get pickupCodeHelper;

  /// Muted banner shown when the pickup code comes from the secure-storage cache during a network failure fallback
  ///
  /// In en, this message translates to:
  /// **'No connection — showing the saved code'**
  String get pickupCodeOfflineBanner;

  /// Heading shown on the pickup code screen when the order is already delivered
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get pickupCodeDeliveredTitle;

  /// Body shown on the pickup code screen when the order is already delivered
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get pickupCodeDeliveredBody;

  /// CTA on a ready order detail screen that opens the pickup QR/code screen
  ///
  /// In en, this message translates to:
  /// **'Show pickup code'**
  String get showPickupCodeBtn;

  /// Badge shown on ready orders in the orders list
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get readyForPickupBadge;

  /// One-shot delivered celebration overlay title shown when an order is first observed in delivered state
  ///
  /// In en, this message translates to:
  /// **'Congratulations on your purchase!'**
  String get deliveredCelebrationTitle;

  /// Section header for product characteristics
  ///
  /// In en, this message translates to:
  /// **'Characteristics'**
  String get characteristicsLabel;

  /// Section header for variant/model selection
  ///
  /// In en, this message translates to:
  /// **'Model options'**
  String get modelOptionsLabel;

  /// Label for the base/default model variant
  ///
  /// In en, this message translates to:
  /// **'Base model'**
  String get baseModelLabel;

  /// Label for the currently selected model variant
  ///
  /// In en, this message translates to:
  /// **'Selected model'**
  String get selectedModelLabel;

  /// Label shown when a variant is out of stock
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get soldOutLabel;

  /// Explanation text under model options explaining price differences
  ///
  /// In en, this message translates to:
  /// **'Price changes because this model has different characteristics.'**
  String get priceReasonLabel;

  /// Attribute label for color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get attrColor;

  /// Attribute label for size
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get attrSize;

  /// Attribute label for material
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get attrMaterial;

  /// Attribute label for weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get attrWeight;

  /// Attribute label for brand
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get attrBrand;

  /// Attribute label for model
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get attrModel;

  /// Attribute label for capacity
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get attrCapacity;

  /// Attribute label for storage/memory
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get attrStorage;

  /// Order card action button: track order
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get orderTrackBtn;

  /// Order card action button: get help
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get orderHelpBtn;

  /// Order card action button: view details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get orderDetailsBtn;

  /// Order card action button: reorder the same items
  ///
  /// In en, this message translates to:
  /// **'Order again'**
  String get orderAgainBtn;

  /// Order card action button: leave a review
  ///
  /// In en, this message translates to:
  /// **'Leave review'**
  String get orderReviewBtn;

  /// B2B home section header for factory categories
  ///
  /// In en, this message translates to:
  /// **'Factories'**
  String get b2bSectionFactories;

  /// B2B home section 'see all' link
  ///
  /// In en, this message translates to:
  /// **'All ›'**
  String get b2bSectionSeeAll;

  /// B2B home section header for popular wholesale products
  ///
  /// In en, this message translates to:
  /// **'Popular wholesale'**
  String get b2bSectionPopular;

  /// B2B home section 'catalog' link
  ///
  /// In en, this message translates to:
  /// **'Catalog ›'**
  String get b2bSectionCatalog;

  /// B2B factory category: electronics
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get b2bFactoryElectronics;

  /// B2B factory category: clothing
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get b2bFactoryClothing;

  /// B2B factory category: home goods
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get b2bFactoryHome;

  /// B2B factory category count
  ///
  /// In en, this message translates to:
  /// **'{count} factories'**
  String b2bFactoryCount(int count);

  /// Header for the product-screen review preview section
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsSectionTitle;

  /// Button navigating from the preview section to the full review list, with review count
  ///
  /// In en, this message translates to:
  /// **'All reviews ({count})'**
  String seeAllReviewsBtn(int count);

  /// Empty state title when a product has zero reviews and the user is eligible to review
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsEmptyTitle;

  /// Empty state subtitle when a product has zero reviews and the user is eligible to review
  ///
  /// In en, this message translates to:
  /// **'Be the first to tell us about the product'**
  String get reviewsEmptySubtitle;

  /// AppBar title on the full review list screen
  ///
  /// In en, this message translates to:
  /// **'All reviews'**
  String get allReviewsTitle;

  /// Review list sort chip: newest first
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewestChip;

  /// Review list sort chip: by rating
  ///
  /// In en, this message translates to:
  /// **'By rating'**
  String get sortRatingChip;

  /// Review list filter chip: only reviews with photos
  ///
  /// In en, this message translates to:
  /// **'With photos'**
  String get hasPhotosChip;

  /// Button to clear all active review list filters
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFiltersBtn;

  /// Empty state title when the review list has active filters and zero results
  ///
  /// In en, this message translates to:
  /// **'No reviews match these filters'**
  String get reviewsEmptyFilteredTitle;

  /// Empty state subtitle when the review list has active filters and zero results
  ///
  /// In en, this message translates to:
  /// **'Try removing some filters'**
  String get reviewsEmptyFilteredSubtitle;

  /// Error message shown when the review list fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load reviews'**
  String get loadReviewsError;

  /// Review count label shown next to the rating summary
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewCountLabel(int count);

  /// Entry CTA button shown on the order item and product screen when the user is eligible to review (D-01)
  ///
  /// In en, this message translates to:
  /// **'Rate product'**
  String get reviewEntryCta;

  /// AppBar title on the review form screen in create mode
  ///
  /// In en, this message translates to:
  /// **'Rate product'**
  String get reviewFormTitleCreate;

  /// AppBar title on the review form screen in edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get reviewFormTitleEdit;

  /// Submit button on the review form screen
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get reviewSubmitCta;

  /// Label shown above the submit button while the review submission is in flight
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reviewSubmitting;

  /// Photo source bottom-sheet option: camera
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get reviewPhotoSourceCamera;

  /// Photo source bottom-sheet option: gallery
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get reviewPhotoSourceGallery;

  /// Hint text for the review text field
  ///
  /// In en, this message translates to:
  /// **'Tell us about the product (optional)'**
  String get reviewTextHint;

  /// Helper text under the review form's photo grid
  ///
  /// In en, this message translates to:
  /// **'Up to 5 photos'**
  String get reviewPhotoHelper;

  /// Validation message shown when the user tries to submit a review without selecting a star rating
  ///
  /// In en, this message translates to:
  /// **'Rate the product — at least one star'**
  String get reviewRatingRequiredValidation;

  /// Validation message shown when the review text exceeds the 1000-character cap
  ///
  /// In en, this message translates to:
  /// **'No more than 1000 characters'**
  String get reviewTextTooLongValidation;

  /// Label shown under the star input for a 1-star rating
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get reviewRatingLabel1;

  /// Label shown under the star input for a 2-star rating
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get reviewRatingLabel2;

  /// Label shown under the star input for a 3-star rating
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get reviewRatingLabel3;

  /// Label shown under the star input for a 4-star rating
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewRatingLabel4;

  /// Label shown under the star input for a 5-star rating
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get reviewRatingLabel5;

  /// Error message for the REVIEW_NOT_ELIGIBLE API error code
  ///
  /// In en, this message translates to:
  /// **'You are not eligible to review this product'**
  String get errReviewNotEligible;

  /// Error message for the REVIEW_NOT_FOUND API error code
  ///
  /// In en, this message translates to:
  /// **'Review not found'**
  String get errReviewNotFound;

  /// Error message for the REVIEW_PHOTO_INVALID API error code
  ///
  /// In en, this message translates to:
  /// **'One of the photos was rejected — replace it and try again'**
  String get errReviewPhotoInvalid;

  /// Error message for the REVIEW_PHOTO_LIMIT API error code
  ///
  /// In en, this message translates to:
  /// **'Too many photos — up to 5 allowed'**
  String get errReviewPhotoLimit;

  /// Inline banner message for the REVIEW_ALREADY_EXISTS API error code on the review form screen
  ///
  /// In en, this message translates to:
  /// **'You have already reviewed this product'**
  String get errReviewAlreadyExists;

  /// Action button on the REVIEW_ALREADY_EXISTS banner
  ///
  /// In en, this message translates to:
  /// **'Open my review'**
  String get reviewOpenExistingCta;

  /// Retry action on the review submit error snackbar
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get reviewRetryCta;

  /// Title of the discard-confirmation dialog shown when leaving a dirty review form
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get reviewDiscardTitle;

  /// Body of the discard-confirmation dialog shown when leaving a dirty review form
  ///
  /// In en, this message translates to:
  /// **'Your rating, text, and photos will be lost.'**
  String get reviewDiscardBody;

  /// Stay action on the discard-confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get reviewDiscardStay;

  /// Exit action on the discard-confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get reviewDiscardExit;

  /// Title shown in the celebration overlay after a successful review submission
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get reviewSubmitCelebrationTitle;

  /// Title of the report bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Report review'**
  String get reportSheetTitle;

  /// Report reason category: spam_advertising
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get reportCategorySpam;

  /// Report reason category: abusive_content
  ///
  /// In en, this message translates to:
  /// **'Abusive content'**
  String get reportCategoryAbusive;

  /// Report reason category: false_or_irrelevant
  ///
  /// In en, this message translates to:
  /// **'False or irrelevant information'**
  String get reportCategoryFalse;

  /// Report reason category: inappropriate_photo
  ///
  /// In en, this message translates to:
  /// **'Inappropriate photo'**
  String get reportCategoryPhoto;

  /// Report reason category: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportCategoryOther;

  /// Hint text for the optional comment field on the report bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get reportCommentHint;

  /// Submit button on the report bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSubmitBtn;

  /// Snackbar shown after a successful report submission
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSubmittedToast;

  /// Persistent footer marker on a review card the current user has reported
  ///
  /// In en, this message translates to:
  /// **'You reported this'**
  String get reportedMarkerLabel;

  /// Menu item to report another user's review
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportMenuItem;

  /// Menu item to edit an existing report on a review
  ///
  /// In en, this message translates to:
  /// **'Edit report'**
  String get editReportMenuItem;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'tg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'tg':
      return AppLocalizationsTg();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
