///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$connectivity$en connectivity = Translations$connectivity$en.internal(_root);
	late final Translations$navigation$en navigation = Translations$navigation$en.internal(_root);
	late final Translations$onboarding$en onboarding = Translations$onboarding$en.internal(_root);
	late final Translations$pricing$en pricing = Translations$pricing$en.internal(_root);
	late final Translations$home$en home = Translations$home$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$auth$en auth = Translations$auth$en.internal(_root);
	late final Translations$profile$en profile = Translations$profile$en.internal(_root);
	late final Translations$security$en security = Translations$security$en.internal(_root);
	late final Translations$forceUpdate$en forceUpdate = Translations$forceUpdate$en.internal(_root);
	late final Translations$softUpdate$en softUpdate = Translations$softUpdate$en.internal(_root);
	late final Translations$session$en session = Translations$session$en.internal(_root);
	late final Translations$splash$en splash = Translations$splash$en.internal(_root);
	late final Translations$states$en states = Translations$states$en.internal(_root);
	late final Translations$announcements$en announcements = Translations$announcements$en.internal(_root);
	late final Translations$validation$en validation = Translations$validation$en.internal(_root);
	late final Translations$routeError$en routeError = Translations$routeError$en.internal(_root);
	late final Translations$startupFailure$en startupFailure = Translations$startupFailure$en.internal(_root);
	late final Translations$diagnostics$en diagnostics = Translations$diagnostics$en.internal(_root);
	late final Translations$devGallery$en devGallery = Translations$devGallery$en.internal(_root);
	late final Translations$notifications$en notifications = Translations$notifications$en.internal(_root);
	late final Translations$deepLink$en deepLink = Translations$deepLink$en.internal(_root);
	late final Translations$permission$en permission = Translations$permission$en.internal(_root);
	late final Translations$share$en share = Translations$share$en.internal(_root);
	late final Translations$update$en update = Translations$update$en.internal(_root);
	late final Translations$search$en search = Translations$search$en.internal(_root);
	late final Translations$feedback$en feedback = Translations$feedback$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Starter'
	String get name => 'Starter';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Continue'
	String get continueAction => 'Continue';

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Reset'
	String get reset => 'Reset';

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Previous'
	String get previous => 'Previous';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Optional'
	String get optional => 'Optional';

	/// en: 'Loading'
	String get loading => 'Loading';

	/// en: 'Saving…'
	String get saving => 'Saving…';

	/// en: 'This action is not connected yet.'
	String get notConnected => 'This action is not connected yet.';

	/// en: 'Information preview'
	String get legalPlaceholderTitle => 'Information preview';

	/// en: 'This starter shows deterministic placeholder content until product-specific legal text is approved.'
	String get legalPlaceholderBody => 'This starter shows deterministic placeholder content until product-specific legal text is approved.';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Success'
	String get success => 'Success';

	/// en: 'Discard'
	String get discard => 'Discard';

	/// en: 'Error'
	String get error => 'Error';
}

// Path: connectivity
class Translations$connectivity$en {
	Translations$connectivity$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Online'
	String get online => 'Online';

	/// en: 'You are offline. Some actions may be unavailable.'
	String get offline => 'You are offline. Some actions may be unavailable.';

	/// en: 'You are back online.'
	String get backOnline => 'You are back online.';

	/// en: 'Limited connection. Some actions may be slow or unavailable.'
	String get limited => 'Limited connection. Some actions may be slow or unavailable.';
}

// Path: navigation
class Translations$navigation$en {
	Translations$navigation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Pricing'
	String get pricing => 'Pricing';

	/// en: 'Settings'
	String get settings => 'Settings';
}

// Path: onboarding
class Translations$onboarding$en {
	Translations$onboarding$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'A thoughtful starting point'
	String get brand => 'A thoughtful starting point';

	/// en: 'Step $current of $total'
	String progress({required Object current, required Object total}) => 'Step ${current} of ${total}';

	/// en: 'Build from a durable foundation'
	String get firstTitle => 'Build from a durable foundation';

	/// en: 'Start with explicit configuration, strict quality checks, and an interface that is ready to grow.'
	String get firstBody => 'Start with explicit configuration, strict quality checks, and an interface that is ready to grow.';

	/// en: 'Designed for every screen'
	String get middleTitle => 'Designed for every screen';

	/// en: 'The same production pages adapt from compact touch layouts to precise desktop workflows.'
	String get middleBody => 'The same production pages adapt from compact touch layouts to precise desktop workflows.';

	/// en: 'Your preferences stay yours'
	String get finalTitle => 'Your preferences stay yours';

	/// en: 'Choose appearance, language, and text size without hiding system accessibility settings.'
	String get finalBody => 'Choose appearance, language, and text size without hiding system accessibility settings.';

	/// en: 'Review plans'
	String get openPaywall => 'Review plans';
}

// Path: pricing
class Translations$pricing$en {
	Translations$pricing$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Plans for the way you work'
	String get title => 'Plans for the way you work';

	/// en: 'Compare a small, honest set of static plans. Purchasing is intentionally not connected in this starter.'
	String get body => 'Compare a small, honest set of static plans. Purchasing is intentionally not connected in this starter.';

	/// en: 'Monthly'
	String get monthly => 'Monthly';

	/// en: 'Annual'
	String get annual => 'Annual';

	/// en: 'Billed every month'
	String get billedMonthly => 'Billed every month';

	/// en: 'Billed once per year'
	String get billedAnnually => 'Billed once per year';

	/// en: 'per month'
	String get periodMonth => 'per month';

	/// en: 'per year'
	String get periodYear => 'per year';

	/// en: 'Recommended'
	String get recommended => 'Recommended';

	/// en: 'Current plan'
	String get current => 'Current plan';

	/// en: 'Preview $plan'
	String choosePlan({required Object plan}) => 'Preview ${plan}';

	/// en: 'Unavailable'
	String get unavailable => 'Unavailable';

	/// en: 'Plan selection is unavailable in this preview. You can still review every plan.'
	String get unavailableReason => 'Plan selection is unavailable in this preview. You can still review every plan.';

	/// en: 'Compare plans'
	String get comparisonTitle => 'Compare plans';

	/// en: 'Common questions'
	String get faqTitle => 'Common questions';

	/// en: 'Can I change plans later?'
	String get faqQuestion => 'Can I change plans later?';

	/// en: 'Yes. This static experience demonstrates the layout only; no subscription is created.'
	String get faqAnswer => 'Yes. This static experience demonstrates the layout only; no subscription is created.';

	/// en: 'Restore purchases'
	String get restore => 'Restore purchases';

	/// en: 'Purchase restoration is not connected in this starter.'
	String get restoreUnavailable => 'Purchase restoration is not connected in this starter.';

	/// en: 'Terms'
	String get terms => 'Terms';

	/// en: 'Privacy'
	String get privacy => 'Privacy';

	/// en: 'No payment or purchase will be made.'
	String get staticPurchaseNotice => 'No payment or purchase will be made.';

	/// en: 'Plan selection preview complete. No purchase was made.'
	String get staticSuccess => 'Plan selection preview complete. No purchase was made.';

	/// en: 'Keep building with more room'
	String get paywallTitle => 'Keep building with more room';

	/// en: 'Review the benefits, choose a billing period, or skip and continue exploring the starter.'
	String get paywallBody => 'Review the benefits, choose a billing period, or skip and continue exploring the starter.';

	/// en: 'Preview selected plan and continue'
	String get paywallContinue => 'Preview selected plan and continue';

	/// en: 'Adaptive layouts for phone and desktop'
	String get benefitAdaptive => 'Adaptive layouts for phone and desktop';

	/// en: 'English, Arabic, and Simplified Chinese'
	String get benefitLocalized => 'English, Arabic, and Simplified Chinese';

	/// en: 'Accessible scaling and input policies'
	String get benefitAccessible => 'Accessible scaling and input policies';

	late final Translations$pricing$plans$en plans = Translations$pricing$plans$en.internal(_root);
}

// Path: home
class Translations$home$en {
	Translations$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'A durable place to begin'
	String get title => 'A durable place to begin';

	/// en: 'The application shell is running with explicit configuration, adaptive navigation, and localized controls.'
	String get body => 'The application shell is running with explicit configuration, adaptive navigation, and localized controls.';

	/// en: 'Welcome, $name'
	String greeting({required Object name}) => 'Welcome, ${name}';

	/// en: 'Your starter is configured and ready for the next real product capability.'
	String get summary => 'Your starter is configured and ready for the next real product capability.';

	/// en: 'Quick actions'
	String get quickActions => 'Quick actions';

	/// en: 'Update profile'
	String get editProfile => 'Update profile';

	/// en: 'Open settings'
	String get openSettings => 'Open settings';

	/// en: 'View pricing'
	String get openPricing => 'View pricing';

	/// en: 'Try the login flow'
	String get openLogin => 'Try the login flow';

	/// en: 'Foundation status'
	String get statusTitle => 'Foundation status';

	/// en: 'Ready to extend'
	String get statusReadyTitle => 'Ready to extend';

	/// en: 'Configuration, routing, localization, and adaptive layout are connected.'
	String get statusReadyBody => 'Configuration, routing, localization, and adaptive layout are connected.';

	/// en: 'Adaptive by default'
	String get statusAdaptiveTitle => 'Adaptive by default';

	/// en: 'Resize the window without resetting the active route or feature state.'
	String get statusAdaptiveBody => 'Resize the window without resetting the active route or feature state.';

	/// en: 'Localized at the root'
	String get statusLocalizedTitle => 'Localized at the root';

	/// en: 'Application and ForUI copy share the selected language and direction.'
	String get statusLocalizedBody => 'Application and ForUI copy share the selected language and direction.';

	/// en: 'Recent activity'
	String get recentTitle => 'Recent activity';

	/// en: 'Nothing here yet'
	String get recentEmptyTitle => 'Nothing here yet';

	/// en: 'Real product activity can replace this honest empty state when a domain is chosen.'
	String get recentEmptyBody => 'Real product activity can replace this honest empty state when a domain is chosen.';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Account'
	String get account => 'Account';

	/// en: 'Subscription'
	String get subscription => 'Subscription';

	/// en: 'Privacy and About'
	String get privacyAbout => 'Privacy and About';

	/// en: 'Theme mode'
	String get themeMode => 'Theme mode';

	/// en: 'System'
	String get system => 'System';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Accent'
	String get accent => 'Accent';

	/// en: 'Neutral'
	String get accentNeutral => 'Neutral';

	/// en: 'Green'
	String get accentGreen => 'Green';

	/// en: 'Blue'
	String get accentBlue => 'Blue';

	/// en: 'Amber'
	String get accentAmber => 'Amber';

	/// en: 'Rose'
	String get accentRose => 'Rose';

	/// en: 'Violet'
	String get accentViolet => 'Violet';

	/// en: 'Text size'
	String get fontScale => 'Text size';

	/// en: 'Motion preview'
	String get motionPreview => 'Motion preview';

	/// en: 'Application language'
	String get locale => 'Application language';

	/// en: 'Use device language'
	String get languageSystem => 'Use device language';

	/// en: 'English'
	String get languageEnglish => 'English';

	/// en: 'Arabic'
	String get languageArabic => 'Arabic';

	/// en: 'Simplified Chinese'
	String get languageChinese => 'Simplified Chinese';

	/// en: 'Settings saved'
	String get saved => 'Settings saved';

	/// en: 'Review the static profile and authentication flows.'
	String get accountBody => 'Review the static profile and authentication flows.';

	/// en: 'Update profile'
	String get openProfile => 'Update profile';

	/// en: 'Open login'
	String get openLogin => 'Open login';

	/// en: 'Compare plans without starting a purchase.'
	String get subscriptionBody => 'Compare plans without starting a purchase.';

	/// en: 'View pricing'
	String get openPricing => 'View pricing';

	/// en: 'This starter stores only appearance and language preferences during the static phase.'
	String get privacyBody => 'This starter stores only appearance and language preferences during the static phase.';

	/// en: 'Build information'
	String get aboutBuild => 'Build information';

	/// en: 'Terms preview'
	String get terms => 'Terms preview';

	/// en: 'Privacy preview'
	String get privacy => 'Privacy preview';

	/// en: 'Unlock with biometrics'
	String get enableBiometric => 'Unlock with biometrics';

	/// en: 'Passcode'
	String get passcode => 'Passcode';

	/// en: 'Auto-lock delay'
	String get autoLockDelay => 'Auto-lock delay';

	/// en: 'Lock when backgrounded'
	String get lockOnBackground => 'Lock when backgrounded';

	late final Translations$settings$analytics$en analytics = Translations$settings$analytics$en.internal(_root);
	late final Translations$settings$accessibility$en accessibility = Translations$settings$accessibility$en.internal(_root);
	late final Translations$settings$haptics$en haptics = Translations$settings$haptics$en.internal(_root);
	late final Translations$settings$about$en about = Translations$settings$about$en.internal(_root);
}

// Path: auth
class Translations$auth$en {
	Translations$auth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$auth$common$en common = Translations$auth$common$en.internal(_root);
	late final Translations$auth$login$en login = Translations$auth$login$en.internal(_root);
	late final Translations$auth$register$en register = Translations$auth$register$en.internal(_root);
	late final Translations$auth$forgotPassword$en forgotPassword = Translations$auth$forgotPassword$en.internal(_root);
	late final Translations$auth$otp$en otp = Translations$auth$otp$en.internal(_root);
	late final Translations$auth$resetPassword$en resetPassword = Translations$auth$resetPassword$en.internal(_root);
}

// Path: profile
class Translations$profile$en {
	Translations$profile$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$profile$update$en update = Translations$profile$update$en.internal(_root);
}

// Path: security
class Translations$security$en {
	Translations$security$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$security$biometric$en biometric = Translations$security$biometric$en.internal(_root);
	late final Translations$security$passcode$en passcode = Translations$security$passcode$en.internal(_root);
}

// Path: forceUpdate
class Translations$forceUpdate$en {
	Translations$forceUpdate$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update required'
	String get title => 'Update required';

	/// en: 'This version is no longer supported. Update to the latest version to continue.'
	String get body => 'This version is no longer supported. Update to the latest version to continue.';

	/// en: 'Update now'
	String get updateNow => 'Update now';
}

// Path: softUpdate
class Translations$softUpdate$en {
	Translations$softUpdate$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'A newer version is available'
	String get title => 'A newer version is available';

	/// en: 'Update to the latest version for the latest improvements and fixes.'
	String get body => 'Update to the latest version for the latest improvements and fixes.';

	/// en: 'Update'
	String get update => 'Update';

	/// en: 'Later'
	String get later => 'Later';
}

// Path: session
class Translations$session$en {
	Translations$session$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Your session has expired. Please sign in again.'
	String get expired => 'Your session has expired. Please sign in again.';

	/// en: 'You are signed out.'
	String get signedOut => 'You are signed out.';

	/// en: 'Signed in as $userId'
	String signedInPreview({required Object userId}) => 'Signed in as ${userId}';

	/// en: 'Sign-in is not connected yet.'
	String get unavailable => 'Sign-in is not connected yet.';
}

// Path: splash
class Translations$splash$en {
	Translations$splash$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Starting up'
	String get loading => 'Starting up';

	/// en: 'A thoughtful starting point'
	String get tagline => 'A thoughtful starting point';

	/// en: 'We couldn't finish starting up.'
	String get error => 'We couldn\'t finish starting up.';
}

// Path: states
class Translations$states$en {
	Translations$states$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Nothing here yet'
	String get emptyTitle => 'Nothing here yet';

	/// en: 'When content is available, it will appear here.'
	String get emptyBody => 'When content is available, it will appear here.';

	/// en: 'Could not load this'
	String get errorTitle => 'Could not load this';

	/// en: 'Something went wrong while loading. Try again.'
	String get errorBody => 'Something went wrong while loading. Try again.';

	/// en: 'Loading…'
	String get loadingTitle => 'Loading…';
}

// Path: announcements
class Translations$announcements$en {
	Translations$announcements$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en: 'Learn more'
	String get actionLearnMore => 'Learn more';

	/// en: 'Couldn't dismiss the announcement.'
	String get dismissFailed => 'Couldn\'t dismiss the announcement.';

	/// en: 'Information'
	String get severityInfo => 'Information';

	/// en: 'Success'
	String get severitySuccess => 'Success';

	/// en: 'Warning'
	String get severityWarning => 'Warning';

	/// en: 'Critical'
	String get severityCritical => 'Critical';

	late final Translations$announcements$fixtures$en fixtures = Translations$announcements$fixtures$en.internal(_root);
}

// Path: validation
class Translations$validation$en {
	Translations$validation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '$field is required.'
	String required({required Object field}) => '${field} is required.';

	/// en: 'Enter a valid email address.'
	String get email => 'Enter a valid email address.';

	/// en: 'Use at least 8 characters with an uppercase letter and a number.'
	String get passwordWeak => 'Use at least 8 characters with an uppercase letter and a number.';

	/// en: 'The passwords do not match.'
	String get passwordMismatch => 'The passwords do not match.';

	/// en: 'Accept the terms and privacy preview to continue.'
	String get acceptTerms => 'Accept the terms and privacy preview to continue.';

	/// en: 'Enter all six digits.'
	String get otpDigits => 'Enter all six digits.';

	/// en: 'Use 3–24 letters, numbers, periods, or underscores.'
	String get username => 'Use 3–24 letters, numbers, periods, or underscores.';

	/// en: 'Keep the bio to $maximum characters or fewer.'
	String bioTooLong({required Object maximum}) => 'Keep the bio to ${maximum} characters or fewer.';
}

// Path: routeError
class Translations$routeError$en {
	Translations$routeError$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'We could not open that page'
	String get title => 'We could not open that page';

	/// en: 'The address is unknown or incomplete. You can return to a safe page.'
	String get body => 'The address is unknown or incomplete. You can return to a safe page.';

	/// en: 'Requested address: $path'
	String path({required Object path}) => 'Requested address: ${path}';

	/// en: 'The verification address needs a valid registration or password-reset purpose.'
	String get invalidOtpPurpose => 'The verification address needs a valid registration or password-reset purpose.';
}

// Path: startupFailure
class Translations$startupFailure$en {
	Translations$startupFailure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'The application could not start'
	String get title => 'The application could not start';

	/// en: 'Close and restart the application. If the problem continues, share the diagnostic ID with support.'
	String get body => 'Close and restart the application. If the problem continues, share the diagnostic ID with support.';

	/// en: 'Diagnostic ID: $id'
	String diagnosticId({required Object id}) => 'Diagnostic ID: ${id}';
}

// Path: diagnostics
class Translations$diagnostics$en {
	Translations$diagnostics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Development diagnostics'
	String get title => 'Development diagnostics';

	/// en: 'Environment'
	String get environment => 'Environment';

	/// en: 'Build'
	String get build => 'Build';

	/// en: 'Layout class'
	String get layout => 'Layout class';

	/// en: 'Interaction policy'
	String get interaction => 'Interaction policy';

	/// en: 'App lifecycle'
	String get lifecycle => 'App lifecycle';

	/// en: 'Locale'
	String get locale => 'Locale';

	/// en: 'Platform capabilities'
	String get capabilities => 'Platform capabilities';

	/// en: 'Secure storage'
	String get secureStorage => 'Secure storage';

	/// en: 'Crash reporting'
	String get crashReporting => 'Crash reporting';

	/// en: 'Not configured'
	String get crashReportingNone => 'Not configured';

	/// en: 'Analytics'
	String get analytics => 'Analytics';

	/// en: 'Not configured'
	String get analyticsNone => 'Not configured';

	/// en: 'Feature flags'
	String get featureFlags => 'Feature flags';

	/// en: 'Diagnostics exclude credentials and user content.'
	String get redactedNotice => 'Diagnostics exclude credentials and user content.';

	late final Translations$diagnostics$experiments$en experiments = Translations$diagnostics$experiments$en.internal(_root);
}

// Path: devGallery
class Translations$devGallery$en {
	Translations$devGallery$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Production screen gallery'
	String get title => 'Production screen gallery';

	/// en: 'Search cases'
	String get search => 'Search cases';

	/// en: 'Screen'
	String get screen => 'Screen';

	/// en: 'Gallery case'
	String get galleryCase => 'Gallery case';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Viewport'
	String get viewport => 'Viewport';

	/// en: 'Locale'
	String get locale => 'Locale';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Accent'
	String get accent => 'Accent';

	/// en: 'Text scaling'
	String get textScale => 'Text scaling';

	/// en: 'System text scaling'
	String get systemTextScale => 'System text scaling';

	/// en: 'Interaction policy'
	String get interaction => 'Interaction policy';

	/// en: 'Motion'
	String get motion => 'Motion';

	/// en: 'High contrast'
	String get highContrast => 'High contrast';

	/// en: 'Bold text'
	String get boldText => 'Bold text';

	/// en: 'Safe-area padding'
	String get safeArea => 'Safe-area padding';

	/// en: 'Keyboard inset'
	String get keyboardInsets => 'Keyboard inset';

	/// en: 'Display feature'
	String get displayFeature => 'Display feature';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Enabled'
	String get enabled => 'Enabled';

	/// en: 'Disabled'
	String get disabled => 'Disabled';

	/// en: 'Normal'
	String get normal => 'Normal';

	/// en: 'Maximum nonlinear'
	String get maximum => 'Maximum nonlinear';

	/// en: 'Touch'
	String get touch => 'Touch';

	/// en: 'Precision pointer'
	String get precision => 'Precision pointer';

	/// en: 'Hybrid input'
	String get hybrid => 'Hybrid input';

	/// en: 'None'
	String get none => 'None';

	/// en: 'Vertical fold'
	String get fold => 'Vertical fold';

	/// en: 'Reset preview controls'
	String get resetControls => 'Reset preview controls';

	/// en: 'Compact phone'
	String get viewportCompactPhone => 'Compact phone';

	/// en: 'Short landscape phone'
	String get viewportShortPhone => 'Short landscape phone';

	/// en: 'Below medium boundary'
	String get viewportBelowMedium => 'Below medium boundary';

	/// en: 'At medium boundary'
	String get viewportAtMedium => 'At medium boundary';

	/// en: 'Medium window'
	String get viewportMedium => 'Medium window';

	/// en: 'Below expanded boundary'
	String get viewportBelowExpanded => 'Below expanded boundary';

	/// en: 'At expanded boundary'
	String get viewportAtExpanded => 'At expanded boundary';

	/// en: 'Desktop'
	String get viewportDesktop => 'Desktop';

	/// en: 'Narrow resized desktop'
	String get viewportNarrowDesktop => 'Narrow resized desktop';

	/// en: 'Onboarding'
	String get screenOnboarding => 'Onboarding';

	/// en: 'Onboarding paywall'
	String get screenPaywall => 'Onboarding paywall';

	/// en: 'Home'
	String get screenHome => 'Home';

	/// en: 'Login'
	String get screenLogin => 'Login';

	/// en: 'Register'
	String get screenRegister => 'Register';

	/// en: 'Forgot password'
	String get screenForgotPassword => 'Forgot password';

	/// en: 'Registration verification'
	String get screenOtpRegistration => 'Registration verification';

	/// en: 'Reset verification'
	String get screenOtpPasswordReset => 'Reset verification';

	/// en: 'Reset password'
	String get screenResetPassword => 'Reset password';

	/// en: 'Update profile'
	String get screenProfile => 'Update profile';

	/// en: 'Pricing'
	String get screenPricing => 'Pricing';

	/// en: 'Settings'
	String get screenSettings => 'Settings';

	/// en: 'Connectivity banner'
	String get screenConnectivity => 'Connectivity banner';

	/// en: 'Force update'
	String get screenForceUpdate => 'Force update';

	/// en: 'Soft update'
	String get screenSoftUpdate => 'Soft update';

	/// en: 'Busy indicators'
	String get screenBusy => 'Busy indicators';

	/// en: 'System surfaces'
	String get screenSystem => 'System surfaces';

	/// en: 'Overlays'
	String get screenOverlays => 'Overlays';

	/// en: 'In-app splash'
	String get screenSplash => 'In-app splash';

	/// en: 'State views'
	String get screenStateViews => 'State views';

	/// en: 'Form scaffolding'
	String get screenFormScaffolding => 'Form scaffolding';

	/// en: 'Announcements banner'
	String get screenAnnouncements => 'Announcements banner';

	/// en: 'Loading'
	String get caseSplashLoading => 'Loading';

	/// en: 'Ready'
	String get caseSplashReady => 'Ready';

	/// en: 'Startup error'
	String get caseSplashError => 'Startup error';

	/// en: 'Empty'
	String get caseStateEmpty => 'Empty';

	/// en: 'Error'
	String get caseStateError => 'Error';

	/// en: 'Loading'
	String get caseStateLoading => 'Loading';

	/// en: 'Submit disabled'
	String get caseFormScaffoldDisabled => 'Submit disabled';

	/// en: 'Submit enabled'
	String get caseFormScaffoldEnabled => 'Submit enabled';

	/// en: 'Submitting'
	String get caseFormScaffoldSubmitting => 'Submitting';

	/// en: 'Info'
	String get caseAnnouncementsInfo => 'Info';

	/// en: 'Success'
	String get caseAnnouncementsSuccess => 'Success';

	/// en: 'Warning'
	String get caseAnnouncementsWarning => 'Warning';

	/// en: 'Critical'
	String get caseAnnouncementsCritical => 'Critical';

	/// en: 'Default'
	String get caseDefault => 'Default';

	/// en: 'Hard block'
	String get caseHardBlock => 'Hard block';

	/// en: 'Soft update'
	String get caseSoftUpdate => 'Soft update';

	/// en: 'Indeterminate'
	String get caseBusyIndeterminate => 'Indeterminate';

	/// en: 'Determinate'
	String get caseBusyDeterminate => 'Determinate';

	/// en: 'Modal overlay'
	String get caseBusyOverlay => 'Modal overlay';

	/// en: 'Expanded copy'
	String get caseExpandedCopy => 'Expanded copy';

	/// en: 'First'
	String get caseFirst => 'First';

	/// en: 'Middle'
	String get caseMiddle => 'Middle';

	/// en: 'Final'
	String get caseFinal => 'Final';

	/// en: 'Monthly'
	String get caseMonthly => 'Monthly';

	/// en: 'Annual'
	String get caseAnnual => 'Annual';

	/// en: 'Recommended'
	String get caseRecommended => 'Recommended';

	/// en: 'Unavailable'
	String get caseUnavailable => 'Unavailable';

	/// en: 'Empty'
	String get caseEmpty => 'Empty';

	/// en: 'Focused'
	String get caseFocused => 'Focused';

	/// en: 'Invalid'
	String get caseInvalid => 'Invalid';

	/// en: 'Submitting'
	String get caseSubmitting => 'Submitting';

	/// en: 'Field error'
	String get caseFieldError => 'Field error';

	/// en: 'Global error'
	String get caseGlobalError => 'Global error';

	/// en: 'Success'
	String get caseSuccess => 'Success';

	/// en: 'Partial'
	String get casePartial => 'Partial';

	/// en: 'Pasted complete'
	String get casePastedComplete => 'Pasted complete';

	/// en: 'Expired'
	String get caseExpired => 'Expired';

	/// en: 'Resending'
	String get caseResending => 'Resending';

	/// en: 'Saving'
	String get caseSaving => 'Saving';

	/// en: 'Saved'
	String get caseSaved => 'Saved';

	/// en: 'Dirty'
	String get caseDirty => 'Dirty';

	/// en: 'Discard prompt'
	String get caseDiscardPrompt => 'Discard prompt';

	/// en: 'Startup failure'
	String get caseStartupFailure => 'Startup failure';

	/// en: 'Unknown route'
	String get caseUnknownRoute => 'Unknown route';

	/// en: 'Malformed OTP purpose'
	String get caseMalformedOtp => 'Malformed OTP purpose';

	/// en: 'Diagnostics'
	String get caseDiagnostics => 'Diagnostics';

	/// en: 'Dialog'
	String get caseDialog => 'Dialog';

	/// en: 'Sheet'
	String get caseSheet => 'Sheet';

	/// en: 'Toast'
	String get caseToast => 'Toast';

	/// en: 'Popover'
	String get casePopover => 'Popover';

	/// en: 'Tooltip'
	String get caseTooltip => 'Tooltip';

	/// en: 'Keyboard-inset form'
	String get caseKeyboardInset => 'Keyboard-inset form';

	/// en: 'Session'
	String get screenSession => 'Session';

	/// en: 'Logged out'
	String get caseSessionLoggedOut => 'Logged out';

	/// en: 'Logged in'
	String get caseSessionLoggedIn => 'Logged in';

	/// en: 'Analytics opt-in'
	String get screenAnalytics => 'Analytics opt-in';

	/// en: 'Biometric lock'
	String get screenBiometricLock => 'Biometric lock';

	/// en: 'Locked'
	String get caseLocked => 'Locked';

	/// en: 'The requested gallery case is not registered.'
	String get caseNotFound => 'The requested gallery case is not registered.';

	/// en: 'Accessibility presets'
	String get screenAccessibility => 'Accessibility presets';

	/// en: 'Comfortable preset'
	String get caseAccessibilityComfortable => 'Comfortable preset';

	/// en: 'Large preset'
	String get caseAccessibilityLarge => 'Large preset';

	/// en: 'Dyslexia preset'
	String get caseAccessibilityDyslexia => 'Dyslexia preset';

	/// en: 'Pull-to-refresh'
	String get screenPullRefresh => 'Pull-to-refresh';

	/// en: 'Refreshable list'
	String get casePullRefreshList => 'Refreshable list';

	/// en: 'Responsive grid'
	String get casePullRefreshGrid => 'Responsive grid';

	/// en: 'Haptics'
	String get screenHaptics => 'Haptics';

	/// en: 'All kinds'
	String get caseHapticKinds => 'All kinds';

	/// en: 'Selection'
	String get caseHapticSelection => 'Selection';

	/// en: 'Light impact'
	String get caseHapticImpactLight => 'Light impact';

	/// en: 'Medium impact'
	String get caseHapticImpactMedium => 'Medium impact';

	/// en: 'Heavy impact'
	String get caseHapticImpactHeavy => 'Heavy impact';

	/// en: 'Success'
	String get caseHapticSuccess => 'Success';

	/// en: 'Warning'
	String get caseHapticWarning => 'Warning';

	/// en: 'Error'
	String get caseHapticError => 'Error';

	/// en: 'Skeleton loading'
	String get screenSkeleton => 'Skeleton loading';

	/// en: 'Static (reduce-motion)'
	String get caseSkeletonStatic => 'Static (reduce-motion)';

	/// en: 'Shimmer'
	String get caseSkeletonShimmer => 'Shimmer';

	/// en: 'MFA verification'
	String get screenOtpMfa => 'MFA verification';

	/// en: 'Countdown'
	String get caseCountdown => 'Countdown';

	/// en: 'Notifications'
	String get screenNotifications => 'Notifications';

	/// en: 'Permission rationale'
	String get caseNotificationsNotRequested => 'Permission rationale';

	/// en: 'Granted'
	String get caseNotificationsGranted => 'Granted';

	/// en: 'Blocked'
	String get caseNotificationsDenied => 'Blocked';

	/// en: 'Permissions'
	String get screenPermissions => 'Permissions';

	/// en: 'Rationale'
	String get casePermissionRationale => 'Rationale';

	/// en: 'Denied'
	String get casePermissionDenied => 'Denied';

	/// en: 'Permanently denied'
	String get casePermissionPermanentlyDenied => 'Permanently denied';

	/// en: 'Licenses'
	String get screenLicense => 'Licenses';

	/// en: 'Share sheet'
	String get screenShare => 'Share sheet';

	/// en: 'In-app update'
	String get screenAppUpdate => 'In-app update';

	/// en: 'Search & pagination'
	String get screenSearchPagination => 'Search & pagination';

	/// en: 'Search field'
	String get caseSearchField => 'Search field';

	/// en: 'Paged list'
	String get caseSearchPaged => 'Paged list';

	/// en: 'Paged list (no backend)'
	String get caseSearchPagedNoBackend => 'Paged list (no backend)';

	/// en: 'Toasts & dialogs'
	String get screenToastDialogs => 'Toasts & dialogs';

	/// en: 'Success toast'
	String get caseToastSuccess => 'Success toast';

	/// en: 'Info toast'
	String get caseToastInfo => 'Info toast';

	/// en: 'Warning toast'
	String get caseToastWarning => 'Warning toast';

	/// en: 'Error toast'
	String get caseToastError => 'Error toast';

	/// en: 'Confirm dialog'
	String get caseDialogConfirm => 'Confirm dialog';

	/// en: 'Destroy dialog'
	String get caseDialogDestroy => 'Destroy dialog';

	/// en: 'Passcode entry'
	String get screenPasscodeEntry => 'Passcode entry';

	/// en: 'Passcode setup'
	String get screenPasscodeSetup => 'Passcode setup';

	/// en: 'Idle'
	String get casePasscodeIdle => 'Idle';

	/// en: 'Incorrect'
	String get casePasscodeError => 'Incorrect';

	/// en: 'Locked out'
	String get casePasscodeLockedOut => 'Locked out';

	/// en: 'Confirm mismatch'
	String get casePasscodeSetupMismatch => 'Confirm mismatch';

	/// en: 'Feedback'
	String get screenFeedback => 'Feedback';

	/// en: 'Drafting'
	String get caseFeedbackDrafting => 'Drafting';

	/// en: 'Submitting'
	String get caseFeedbackSubmitting => 'Submitting';

	/// en: 'Failed'
	String get caseFeedbackFailed => 'Failed';

	/// en: 'Success'
	String get caseFeedbackSuccess => 'Success';
}

// Path: notifications
class Translations$notifications$en {
	Translations$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Turn on notifications'
	String get enableTitle => 'Turn on notifications';

	/// en: 'Get timely updates about your account and activity. You can change this anytime.'
	String get enableBody => 'Get timely updates about your account and activity. You can change this anytime.';

	/// en: 'Not now'
	String get deny => 'Not now';

	/// en: 'Allow'
	String get allow => 'Allow';

	/// en: 'Notifications are blocked'
	String get enableBlockedTitle => 'Notifications are blocked';

	/// en: 'Open system settings to allow notifications for this app.'
	String get enableBlockedBody => 'Open system settings to allow notifications for this app.';

	/// en: 'Notifications are not connected in this starter.'
	String get disabled => 'Notifications are not connected in this starter.';
}

// Path: deepLink
class Translations$deepLink$en {
	Translations$deepLink$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This link could not be opened in the app.'
	String get unsupported => 'This link could not be opened in the app.';
}

// Path: permission
class Translations$permission$en {
	Translations$permission$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$permission$camera$en camera = Translations$permission$camera$en.internal(_root);
	late final Translations$permission$photos$en photos = Translations$permission$photos$en.internal(_root);
	late final Translations$permission$location$en location = Translations$permission$location$en.internal(_root);

	/// en: 'Continue'
	String get continueRequest => 'Continue';

	/// en: 'Not now'
	String get notNow => 'Not now';

	/// en: 'Open settings'
	String get openSettings => 'Open settings';

	/// en: 'Permission was denied. You can try again any time.'
	String get denied => 'Permission was denied. You can try again any time.';

	/// en: 'Permission is blocked. Turn it on in system settings to continue.'
	String get permanentlyDenied => 'Permission is blocked. Turn it on in system settings to continue.';
}

// Path: share
class Translations$share$en {
	Translations$share$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Shared'
	String get success => 'Shared';

	/// en: 'Sharing is not available on this device.'
	String get unavailable => 'Sharing is not available on this device.';

	/// en: 'Share cancelled.'
	String get cancelled => 'Share cancelled.';
}

// Path: update
class Translations$update$en {
	Translations$update$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Check for updates'
	String get checkForUpdates => 'Check for updates';

	/// en: 'An update is available.'
	String get available => 'An update is available.';

	/// en: 'You're on the latest version.'
	String get notAvailable => 'You\'re on the latest version.';

	/// en: 'An update is required to continue.'
	String get required => 'An update is required to continue.';
}

// Path: search
class Translations$search$en {
	Translations$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search'
	String get title => 'Search';

	/// en: 'Search…'
	String get placeholder => 'Search…';

	/// en: 'No results'
	String get emptyTitle => 'No results';

	/// en: 'Try a different search term.'
	String get emptyBody => 'Try a different search term.';

	/// en: 'Search is unavailable'
	String get errorTitle => 'Search is unavailable';
}

// Path: feedback
class Translations$feedback$en {
	Translations$feedback$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Send feedback'
	String get title => 'Send feedback';

	/// en: 'Message'
	String get messageLabel => 'Message';

	/// en: 'What happened, or what could be better?'
	String get messageHint => 'What happened, or what could be better?';

	/// en: 'Include a screenshot'
	String get includeScreenshot => 'Include a screenshot';

	/// en: 'Reply-to email'
	String get emailOptional => 'Reply-to email';

	/// en: 'Send'
	String get submit => 'Send';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Thanks!'
	String get successTitle => 'Thanks!';

	/// en: 'Your feedback was sent.'
	String get successBody => 'Your feedback was sent.';

	/// en: 'We couldn't send your feedback right now.'
	String get failedTitle => 'We couldn\'t send your feedback right now.';

	/// en: 'Open feedback on shake'
	String get shakeEnabled => 'Open feedback on shake';
}

// Path: pricing.plans
class Translations$pricing$plans$en {
	Translations$pricing$plans$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Basic'
	String get basicName => 'Basic';

	/// en: 'A focused foundation for personal projects.'
	String get basicDescription => 'A focused foundation for personal projects.';

	/// en: 'Core starter screens'
	String get basicBenefitOne => 'Core starter screens';

	/// en: 'Theme and language settings'
	String get basicBenefitTwo => 'Theme and language settings';

	/// en: 'Community workflow'
	String get basicBenefitThree => 'Community workflow';

	/// en: 'Pro'
	String get proName => 'Pro';

	/// en: 'More structure for growing products and teams.'
	String get proDescription => 'More structure for growing products and teams.';

	/// en: 'Everything in Basic'
	String get proBenefitOne => 'Everything in Basic';

	/// en: 'Complete static flow gallery'
	String get proBenefitTwo => 'Complete static flow gallery';

	/// en: 'Expanded quality checks'
	String get proBenefitThree => 'Expanded quality checks';

	/// en: 'Team'
	String get teamName => 'Team';

	/// en: 'A shared starting point for coordinated delivery.'
	String get teamDescription => 'A shared starting point for coordinated delivery.';

	/// en: 'Everything in Pro'
	String get teamBenefitOne => 'Everything in Pro';

	/// en: 'Team-ready conventions'
	String get teamBenefitTwo => 'Team-ready conventions';

	/// en: 'Multi-platform release workflow'
	String get teamBenefitThree => 'Multi-platform release workflow';
}

// Path: settings.analytics
class Translations$settings$analytics$en {
	Translations$settings$analytics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Analytics'
	String get optInTitle => 'Analytics';

	/// en: 'Help improve the app by sending anonymous usage data. You can turn this off anytime.'
	String get optInBody => 'Help improve the app by sending anonymous usage data. You can turn this off anytime.';

	/// en: 'On'
	String get statusOn => 'On';

	/// en: 'Off'
	String get statusOff => 'Off';
}

// Path: settings.accessibility
class Translations$settings$accessibility$en {
	Translations$settings$accessibility$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Accessibility'
	String get title => 'Accessibility';

	late final Translations$settings$accessibility$preset$en preset = Translations$settings$accessibility$preset$en.internal(_root);
}

// Path: settings.haptics
class Translations$settings$haptics$en {
	Translations$settings$haptics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Haptic feedback'
	String get title => 'Haptic feedback';

	/// en: 'Enable haptic feedback on key actions'
	String get enable => 'Enable haptic feedback on key actions';
}

// Path: settings.about
class Translations$settings$about$en {
	Translations$settings$about$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Licenses'
	String get license => 'Licenses';
}

// Path: auth.common
class Translations$auth$common$en {
	Translations$auth$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Email address'
	String get email => 'Email address';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Confirm password'
	String get confirmPassword => 'Confirm password';

	/// en: 'Display name'
	String get displayName => 'Display name';

	/// en: 'Show password'
	String get showPassword => 'Show password';

	/// en: 'Hide password'
	String get hidePassword => 'Hide password';

	/// en: 'Use at least 8 characters with an uppercase letter and a number.'
	String get passwordRequirements => 'Use at least 8 characters with an uppercase letter and a number.';

	/// en: 'Return to login'
	String get returnToLogin => 'Return to login';
}

// Path: auth.login
class Translations$auth$login$en {
	Translations$auth$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome back'
	String get title => 'Welcome back';

	/// en: 'Use the static form to review validation, focus, and navigation behavior.'
	String get body => 'Use the static form to review validation, focus, and navigation behavior.';

	/// en: 'Remember my email on this device'
	String get rememberMe => 'Remember my email on this device';

	/// en: 'Forgot password?'
	String get forgotPassword => 'Forgot password?';

	/// en: 'Create an account'
	String get register => 'Create an account';

	/// en: 'Sign in'
	String get submit => 'Sign in';

	/// en: 'Signing in'
	String get submitting => 'Signing in';

	/// en: 'We could not complete the static sign-in. Your values were kept.'
	String get globalError => 'We could not complete the static sign-in. Your values were kept.';

	/// en: 'Static sign-in complete.'
	String get success => 'Static sign-in complete.';

	/// en: 'Too many attempts'
	String get lockedTitle => 'Too many attempts';

	/// en: 'Too many failed attempts. Please wait.'
	String get tooManyAttempts => 'Too many failed attempts. Please wait.';

	/// en: '(one) {1 attempt remaining} (other) {$count attempts remaining}'
	String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 attempt remaining',
		other: '${count} attempts remaining',
	);

	/// en: '(zero) {Try again now.} (one) {Try again in 1 second.} (other) {Try again in $seconds seconds.}'
	String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'Try again now.',
		one: 'Try again in 1 second.',
		other: 'Try again in ${seconds} seconds.',
	);
}

// Path: auth.register
class Translations$auth$register$en {
	Translations$auth$register$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create your account'
	String get title => 'Create your account';

	/// en: 'Enter the details used to demonstrate registration and confirmation behavior.'
	String get body => 'Enter the details used to demonstrate registration and confirmation behavior.';

	/// en: 'I agree to the terms and privacy preview.'
	String get acceptTerms => 'I agree to the terms and privacy preview.';

	/// en: 'Review terms'
	String get terms => 'Review terms';

	/// en: 'Review privacy'
	String get privacy => 'Review privacy';

	/// en: 'Create account'
	String get submit => 'Create account';

	/// en: 'Creating account'
	String get submitting => 'Creating account';

	/// en: 'We could not complete registration. Review the highlighted fields and try again.'
	String get globalError => 'We could not complete registration. Review the highlighted fields and try again.';

	/// en: 'Registration details accepted.'
	String get success => 'Registration details accepted.';

	/// en: 'Discard registration details?'
	String get discardTitle => 'Discard registration details?';

	/// en: 'Your unsaved registration values will be cleared.'
	String get discardBody => 'Your unsaved registration values will be cleared.';

	/// en: 'Keep editing'
	String get stay => 'Keep editing';

	/// en: 'Discard details'
	String get discard => 'Discard details';
}

// Path: auth.forgotPassword
class Translations$auth$forgotPassword$en {
	Translations$auth$forgotPassword$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reset your password'
	String get title => 'Reset your password';

	/// en: 'Enter an email address. The confirmation remains neutral and does not reveal whether an account exists.'
	String get body => 'Enter an email address. The confirmation remains neutral and does not reveal whether an account exists.';

	/// en: 'Send verification code'
	String get submit => 'Send verification code';

	/// en: 'Preparing verification'
	String get submitting => 'Preparing verification';

	/// en: 'If the address can receive a reset, a verification code will be available.'
	String get success => 'If the address can receive a reset, a verification code will be available.';
}

// Path: auth.otp
class Translations$auth$otp$en {
	Translations$auth$otp$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Verify your registration'
	String get registrationTitle => 'Verify your registration';

	/// en: 'Enter the six-digit code to finish the static registration flow.'
	String get registrationBody => 'Enter the six-digit code to finish the static registration flow.';

	/// en: 'Verify your reset request'
	String get passwordResetTitle => 'Verify your reset request';

	/// en: 'Enter the six-digit code before choosing a new password.'
	String get passwordResetBody => 'Enter the six-digit code before choosing a new password.';

	/// en: 'Verification code'
	String get code => 'Verification code';

	/// en: 'Verify code'
	String get submit => 'Verify code';

	/// en: 'Verifying code'
	String get submitting => 'Verifying code';

	/// en: 'Resend code'
	String get resend => 'Resend code';

	/// en: 'Resend available in $seconds seconds'
	String resendIn({required Object seconds}) => 'Resend available in ${seconds} seconds';

	/// en: 'Resending code'
	String get resending => 'Resending code';

	/// en: 'That verification code is not valid.'
	String get invalid => 'That verification code is not valid.';

	/// en: 'That verification code has expired. Request a new code.'
	String get expired => 'That verification code has expired. Request a new code.';

	/// en: 'Registration verified.'
	String get registrationSuccess => 'Registration verified.';

	/// en: 'Reset request verified.'
	String get passwordResetSuccess => 'Reset request verified.';

	/// en: 'Sign-in verified.'
	String get mfaSuccess => 'Sign-in verified.';

	/// en: 'Too many attempts'
	String get lockedTitle => 'Too many attempts';

	/// en: 'Too many failed attempts. Please wait.'
	String get tooManyAttempts => 'Too many failed attempts. Please wait.';

	/// en: '(one) {1 attempt remaining} (other) {$count attempts remaining}'
	String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 attempt remaining',
		other: '${count} attempts remaining',
	);

	/// en: '(zero) {Try again now.} (one) {Try again in 1 second.} (other) {Try again in $seconds seconds.}'
	String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'Try again now.',
		one: 'Try again in 1 second.',
		other: 'Try again in ${seconds} seconds.',
	);

	/// en: 'Verify your sign-in'
	String get mfaTitle => 'Verify your sign-in';

	/// en: 'Enter the six-digit code we sent to complete sign-in.'
	String get mfaBody => 'Enter the six-digit code we sent to complete sign-in.';

	/// en: '(one) {Expires in 1 second} (other) {Expires in $seconds seconds}'
	String expiresIn({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Expires in 1 second',
		other: 'Expires in ${seconds} seconds',
	);

	/// en: 'Code expired'
	String get expiredTitle => 'Code expired';

	/// en: 'Your verification code expired. Request a new code to continue.'
	String get expiredBody => 'Your verification code expired. Request a new code to continue.';
}

// Path: auth.resetPassword
class Translations$auth$resetPassword$en {
	Translations$auth$resetPassword$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose a new password'
	String get title => 'Choose a new password';

	/// en: 'Use a strong password and enter it exactly the same way twice.'
	String get body => 'Use a strong password and enter it exactly the same way twice.';

	/// en: 'New password'
	String get newPassword => 'New password';

	/// en: 'Update password'
	String get submit => 'Update password';

	/// en: 'Updating password'
	String get submitting => 'Updating password';

	/// en: 'The static password update could not be completed.'
	String get globalError => 'The static password update could not be completed.';

	/// en: 'Password update preview complete. Return to login.'
	String get success => 'Password update preview complete. Return to login.';
}

// Path: profile.update
class Translations$profile$update$en {
	Translations$profile$update$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update profile'
	String get title => 'Update profile';

	/// en: 'Edit non-sensitive account details. Drafts remain only while this page is mounted.'
	String get body => 'Edit non-sensitive account details. Drafts remain only while this page is mounted.';

	/// en: 'Profile image placeholder'
	String get avatar => 'Profile image placeholder';

	/// en: 'Change profile image'
	String get changeAvatar => 'Change profile image';

	/// en: 'Image selection is not connected and no permission was requested.'
	String get avatarUnavailable => 'Image selection is not connected and no permission was requested.';

	/// en: 'Display name'
	String get displayName => 'Display name';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Email address'
	String get email => 'Email address';

	/// en: 'Email cannot be changed in this static phase.'
	String get emailReadOnly => 'Email cannot be changed in this static phase.';

	/// en: 'Bio'
	String get bio => 'Bio';

	/// en: '$count of $maximum characters'
	String bioCounter({required Object count, required Object maximum}) => '${count} of ${maximum} characters';

	/// en: 'Save profile'
	String get save => 'Save profile';

	/// en: 'Saving profile'
	String get saving => 'Saving profile';

	/// en: 'Profile changes saved for this session.'
	String get saved => 'Profile changes saved for this session.';

	/// en: 'The static profile save could not be completed. Your values were kept.'
	String get globalError => 'The static profile save could not be completed. Your values were kept.';

	/// en: 'Discard profile changes?'
	String get discardTitle => 'Discard profile changes?';

	/// en: 'Your unsaved profile changes will be cleared.'
	String get discardBody => 'Your unsaved profile changes will be cleared.';

	/// en: 'Keep editing'
	String get stay => 'Keep editing';

	/// en: 'Discard changes'
	String get discard => 'Discard changes';
}

// Path: security.biometric
class Translations$security$biometric$en {
	Translations$security$biometric$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unlock with biometrics'
	String get lockTitle => 'Unlock with biometrics';

	/// en: 'Use your fingerprint or face to unlock the app.'
	String get lockBody => 'Use your fingerprint or face to unlock the app.';

	/// en: 'Authentication failed. Try again.'
	String get authFailedTitle => 'Authentication failed. Try again.';

	/// en: 'Unlock'
	String get unlock => 'Unlock';

	/// en: 'Unlocking'
	String get unlocking => 'Unlocking';

	/// en: 'Biometric unlock unavailable'
	String get unavailableTitle => 'Biometric unlock unavailable';

	/// en: 'Biometric unlock is not available on this device. Use your device credentials instead.'
	String get unavailableBody => 'Biometric unlock is not available on this device. Use your device credentials instead.';

	/// en: 'Use credentials'
	String get useFallback => 'Use credentials';
}

// Path: security.passcode
class Translations$security$passcode$en {
	Translations$security$passcode$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Enter passcode'
	String get enterTitle => 'Enter passcode';

	/// en: 'Enter your passcode to unlock the app.'
	String get enterBody => 'Enter your passcode to unlock the app.';

	/// en: 'Set a passcode'
	String get setupTitle => 'Set a passcode';

	/// en: 'Choose a numeric passcode you can use when biometrics are unavailable.'
	String get setupBody => 'Choose a numeric passcode you can use when biometrics are unavailable.';

	/// en: 'Confirm passcode'
	String get confirmTitle => 'Confirm passcode';

	/// en: 'Re-enter passcode'
	String get reenter => 'Re-enter passcode';

	/// en: 'The passcodes do not match. Try again.'
	String get mismatch => 'The passcodes do not match. Try again.';

	/// en: '(one) {Incorrect passcode. 1 attempt remaining.} (other) {Incorrect passcode. $attempts attempts remaining.}'
	String incorrect({required num n, required Object attempts}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: 'Incorrect passcode. 1 attempt remaining.',
		other: 'Incorrect passcode. ${attempts} attempts remaining.',
	);

	/// en: '(zero) {Too many attempts. Try again now.} (one) {Too many attempts. Try again in 1 second.} (other) {Too many attempts. Try again in $seconds seconds.}'
	String lockedOut({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		zero: 'Too many attempts. Try again now.',
		one: 'Too many attempts. Try again in 1 second.',
		other: 'Too many attempts. Try again in ${seconds} seconds.',
	);

	/// en: 'Disable passcode'
	String get disable => 'Disable passcode';
}

// Path: announcements.fixtures
class Translations$announcements$fixtures$en {
	Translations$announcements$fixtures$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$announcements$fixtures$welcome$en welcome = Translations$announcements$fixtures$welcome$en.internal(_root);
	late final Translations$announcements$fixtures$changelog$en changelog = Translations$announcements$fixtures$changelog$en.internal(_root);
	late final Translations$announcements$fixtures$deprecation$en deprecation = Translations$announcements$fixtures$deprecation$en.internal(_root);
	late final Translations$announcements$fixtures$outage$en outage = Translations$announcements$fixtures$outage$en.internal(_root);
}

// Path: diagnostics.experiments
class Translations$diagnostics$experiments$en {
	Translations$diagnostics$experiments$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Experiments'
	String get title => 'Experiments';

	/// en: 'Source'
	String get source => 'Source';
}

// Path: permission.camera
class Translations$permission$camera$en {
	Translations$permission$camera$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Camera access'
	String get title => 'Camera access';

	/// en: 'We use the camera to take a new profile photo. You can decline any time.'
	String get rationale => 'We use the camera to take a new profile photo. You can decline any time.';
}

// Path: permission.photos
class Translations$permission$photos$en {
	Translations$permission$photos$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Photo library access'
	String get title => 'Photo library access';

	/// en: 'We read your photo library so you can pick a profile photo. You can decline any time.'
	String get rationale => 'We read your photo library so you can pick a profile photo. You can decline any time.';
}

// Path: permission.location
class Translations$permission$location$en {
	Translations$permission$location$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Location access'
	String get title => 'Location access';

	/// en: 'We use your location to personalize your experience. You can decline any time.'
	String get rationale => 'We use your location to personalize your experience. You can decline any time.';
}

// Path: settings.accessibility.preset
class Translations$settings$accessibility$preset$en {
	Translations$settings$accessibility$preset$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Comfortable'
	String get comfortable => 'Comfortable';

	/// en: 'Default text size for everyday reading.'
	String get comfortableDescription => 'Default text size for everyday reading.';

	/// en: 'Large'
	String get large => 'Large';

	/// en: 'Larger text for easier reading at a glance.'
	String get largeDescription => 'Larger text for easier reading at a glance.';

	/// en: 'Dyslexia-friendly'
	String get dyslexia => 'Dyslexia-friendly';

	/// en: 'Slightly larger text with a dyslexia-friendly font where available.'
	String get dyslexiaDescription => 'Slightly larger text with a dyslexia-friendly font where available.';
}

// Path: announcements.fixtures.welcome
class Translations$announcements$fixtures$welcome$en {
	Translations$announcements$fixtures$welcome$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome to the starter'
	String get title => 'Welcome to the starter';

	/// en: 'A durable foundation for your next product. Dismiss this to explore the shell.'
	String get message => 'A durable foundation for your next product. Dismiss this to explore the shell.';
}

// Path: announcements.fixtures.changelog
class Translations$announcements$fixtures$changelog$en {
	Translations$announcements$fixtures$changelog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New in this version'
	String get title => 'New in this version';

	/// en: 'Announcements keep everyone in the loop without an app update.'
	String get message => 'Announcements keep everyone in the loop without an app update.';
}

// Path: announcements.fixtures.deprecation
class Translations$announcements$fixtures$deprecation$en {
	Translations$announcements$fixtures$deprecation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'A newer version is available'
	String get title => 'A newer version is available';

	/// en: 'This build will be deprecated soon. Update when you can.'
	String get message => 'This build will be deprecated soon. Update when you can.';
}

// Path: announcements.fixtures.outage
class Translations$announcements$fixtures$outage$en {
	Translations$announcements$fixtures$outage$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Service outage'
	String get title => 'Service outage';

	/// en: 'Some actions may fail while we resolve a service disruption.'
	String get message => 'Some actions may fail while we resolve a service disruption.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Starter',
			'common.back' => 'Back',
			'common.home' => 'Home',
			'common.retry' => 'Retry',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.close' => 'Close',
			'common.continueAction' => 'Continue',
			'common.skip' => 'Skip',
			'common.reset' => 'Reset',
			'common.done' => 'Done',
			'common.previous' => 'Previous',
			'common.next' => 'Next',
			'common.optional' => 'Optional',
			'common.loading' => 'Loading',
			'common.saving' => 'Saving…',
			'common.notConnected' => 'This action is not connected yet.',
			'common.legalPlaceholderTitle' => 'Information preview',
			'common.legalPlaceholderBody' => 'This starter shows deterministic placeholder content until product-specific legal text is approved.',
			'common.confirm' => 'Confirm',
			'common.success' => 'Success',
			'common.discard' => 'Discard',
			'common.error' => 'Error',
			'connectivity.online' => 'Online',
			'connectivity.offline' => 'You are offline. Some actions may be unavailable.',
			'connectivity.backOnline' => 'You are back online.',
			'connectivity.limited' => 'Limited connection. Some actions may be slow or unavailable.',
			'navigation.home' => 'Home',
			'navigation.pricing' => 'Pricing',
			'navigation.settings' => 'Settings',
			'onboarding.brand' => 'A thoughtful starting point',
			'onboarding.progress' => ({required Object current, required Object total}) => 'Step ${current} of ${total}',
			'onboarding.firstTitle' => 'Build from a durable foundation',
			'onboarding.firstBody' => 'Start with explicit configuration, strict quality checks, and an interface that is ready to grow.',
			'onboarding.middleTitle' => 'Designed for every screen',
			'onboarding.middleBody' => 'The same production pages adapt from compact touch layouts to precise desktop workflows.',
			'onboarding.finalTitle' => 'Your preferences stay yours',
			'onboarding.finalBody' => 'Choose appearance, language, and text size without hiding system accessibility settings.',
			'onboarding.openPaywall' => 'Review plans',
			'pricing.title' => 'Plans for the way you work',
			'pricing.body' => 'Compare a small, honest set of static plans. Purchasing is intentionally not connected in this starter.',
			'pricing.monthly' => 'Monthly',
			'pricing.annual' => 'Annual',
			'pricing.billedMonthly' => 'Billed every month',
			'pricing.billedAnnually' => 'Billed once per year',
			'pricing.periodMonth' => 'per month',
			'pricing.periodYear' => 'per year',
			'pricing.recommended' => 'Recommended',
			'pricing.current' => 'Current plan',
			'pricing.choosePlan' => ({required Object plan}) => 'Preview ${plan}',
			'pricing.unavailable' => 'Unavailable',
			'pricing.unavailableReason' => 'Plan selection is unavailable in this preview. You can still review every plan.',
			'pricing.comparisonTitle' => 'Compare plans',
			'pricing.faqTitle' => 'Common questions',
			'pricing.faqQuestion' => 'Can I change plans later?',
			'pricing.faqAnswer' => 'Yes. This static experience demonstrates the layout only; no subscription is created.',
			'pricing.restore' => 'Restore purchases',
			'pricing.restoreUnavailable' => 'Purchase restoration is not connected in this starter.',
			'pricing.terms' => 'Terms',
			'pricing.privacy' => 'Privacy',
			'pricing.staticPurchaseNotice' => 'No payment or purchase will be made.',
			'pricing.staticSuccess' => 'Plan selection preview complete. No purchase was made.',
			'pricing.paywallTitle' => 'Keep building with more room',
			'pricing.paywallBody' => 'Review the benefits, choose a billing period, or skip and continue exploring the starter.',
			'pricing.paywallContinue' => 'Preview selected plan and continue',
			'pricing.benefitAdaptive' => 'Adaptive layouts for phone and desktop',
			'pricing.benefitLocalized' => 'English, Arabic, and Simplified Chinese',
			'pricing.benefitAccessible' => 'Accessible scaling and input policies',
			'pricing.plans.basicName' => 'Basic',
			'pricing.plans.basicDescription' => 'A focused foundation for personal projects.',
			'pricing.plans.basicBenefitOne' => 'Core starter screens',
			'pricing.plans.basicBenefitTwo' => 'Theme and language settings',
			'pricing.plans.basicBenefitThree' => 'Community workflow',
			'pricing.plans.proName' => 'Pro',
			'pricing.plans.proDescription' => 'More structure for growing products and teams.',
			'pricing.plans.proBenefitOne' => 'Everything in Basic',
			'pricing.plans.proBenefitTwo' => 'Complete static flow gallery',
			'pricing.plans.proBenefitThree' => 'Expanded quality checks',
			'pricing.plans.teamName' => 'Team',
			'pricing.plans.teamDescription' => 'A shared starting point for coordinated delivery.',
			'pricing.plans.teamBenefitOne' => 'Everything in Pro',
			'pricing.plans.teamBenefitTwo' => 'Team-ready conventions',
			'pricing.plans.teamBenefitThree' => 'Multi-platform release workflow',
			'home.title' => 'A durable place to begin',
			'home.body' => 'The application shell is running with explicit configuration, adaptive navigation, and localized controls.',
			'home.greeting' => ({required Object name}) => 'Welcome, ${name}',
			'home.summary' => 'Your starter is configured and ready for the next real product capability.',
			'home.quickActions' => 'Quick actions',
			'home.editProfile' => 'Update profile',
			'home.openSettings' => 'Open settings',
			'home.openPricing' => 'View pricing',
			'home.openLogin' => 'Try the login flow',
			'home.statusTitle' => 'Foundation status',
			'home.statusReadyTitle' => 'Ready to extend',
			'home.statusReadyBody' => 'Configuration, routing, localization, and adaptive layout are connected.',
			'home.statusAdaptiveTitle' => 'Adaptive by default',
			'home.statusAdaptiveBody' => 'Resize the window without resetting the active route or feature state.',
			'home.statusLocalizedTitle' => 'Localized at the root',
			'home.statusLocalizedBody' => 'Application and ForUI copy share the selected language and direction.',
			'home.recentTitle' => 'Recent activity',
			'home.recentEmptyTitle' => 'Nothing here yet',
			'home.recentEmptyBody' => 'Real product activity can replace this honest empty state when a domain is chosen.',
			'settings.title' => 'Settings',
			'settings.appearance' => 'Appearance',
			'settings.language' => 'Language',
			'settings.account' => 'Account',
			'settings.subscription' => 'Subscription',
			'settings.privacyAbout' => 'Privacy and About',
			'settings.themeMode' => 'Theme mode',
			'settings.system' => 'System',
			'settings.light' => 'Light',
			'settings.dark' => 'Dark',
			'settings.accent' => 'Accent',
			'settings.accentNeutral' => 'Neutral',
			'settings.accentGreen' => 'Green',
			'settings.accentBlue' => 'Blue',
			'settings.accentAmber' => 'Amber',
			'settings.accentRose' => 'Rose',
			'settings.accentViolet' => 'Violet',
			'settings.fontScale' => 'Text size',
			'settings.motionPreview' => 'Motion preview',
			'settings.locale' => 'Application language',
			'settings.languageSystem' => 'Use device language',
			'settings.languageEnglish' => 'English',
			'settings.languageArabic' => 'Arabic',
			'settings.languageChinese' => 'Simplified Chinese',
			'settings.saved' => 'Settings saved',
			'settings.accountBody' => 'Review the static profile and authentication flows.',
			'settings.openProfile' => 'Update profile',
			'settings.openLogin' => 'Open login',
			'settings.subscriptionBody' => 'Compare plans without starting a purchase.',
			'settings.openPricing' => 'View pricing',
			'settings.privacyBody' => 'This starter stores only appearance and language preferences during the static phase.',
			'settings.aboutBuild' => 'Build information',
			'settings.terms' => 'Terms preview',
			'settings.privacy' => 'Privacy preview',
			'settings.enableBiometric' => 'Unlock with biometrics',
			'settings.passcode' => 'Passcode',
			'settings.autoLockDelay' => 'Auto-lock delay',
			'settings.lockOnBackground' => 'Lock when backgrounded',
			'settings.analytics.optInTitle' => 'Analytics',
			'settings.analytics.optInBody' => 'Help improve the app by sending anonymous usage data. You can turn this off anytime.',
			'settings.analytics.statusOn' => 'On',
			'settings.analytics.statusOff' => 'Off',
			'settings.accessibility.title' => 'Accessibility',
			'settings.accessibility.preset.comfortable' => 'Comfortable',
			'settings.accessibility.preset.comfortableDescription' => 'Default text size for everyday reading.',
			'settings.accessibility.preset.large' => 'Large',
			'settings.accessibility.preset.largeDescription' => 'Larger text for easier reading at a glance.',
			'settings.accessibility.preset.dyslexia' => 'Dyslexia-friendly',
			'settings.accessibility.preset.dyslexiaDescription' => 'Slightly larger text with a dyslexia-friendly font where available.',
			'settings.haptics.title' => 'Haptic feedback',
			'settings.haptics.enable' => 'Enable haptic feedback on key actions',
			'settings.about.license' => 'Licenses',
			'auth.common.email' => 'Email address',
			'auth.common.password' => 'Password',
			'auth.common.confirmPassword' => 'Confirm password',
			'auth.common.displayName' => 'Display name',
			'auth.common.showPassword' => 'Show password',
			'auth.common.hidePassword' => 'Hide password',
			'auth.common.passwordRequirements' => 'Use at least 8 characters with an uppercase letter and a number.',
			'auth.common.returnToLogin' => 'Return to login',
			'auth.login.title' => 'Welcome back',
			'auth.login.body' => 'Use the static form to review validation, focus, and navigation behavior.',
			'auth.login.rememberMe' => 'Remember my email on this device',
			'auth.login.forgotPassword' => 'Forgot password?',
			'auth.login.register' => 'Create an account',
			'auth.login.submit' => 'Sign in',
			'auth.login.submitting' => 'Signing in',
			'auth.login.globalError' => 'We could not complete the static sign-in. Your values were kept.',
			'auth.login.success' => 'Static sign-in complete.',
			'auth.login.lockedTitle' => 'Too many attempts',
			'auth.login.tooManyAttempts' => 'Too many failed attempts. Please wait.',
			'auth.login.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 attempt remaining', other: '${count} attempts remaining', ), 
			'auth.login.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'Try again now.', one: 'Try again in 1 second.', other: 'Try again in ${seconds} seconds.', ), 
			'auth.register.title' => 'Create your account',
			'auth.register.body' => 'Enter the details used to demonstrate registration and confirmation behavior.',
			'auth.register.acceptTerms' => 'I agree to the terms and privacy preview.',
			'auth.register.terms' => 'Review terms',
			'auth.register.privacy' => 'Review privacy',
			'auth.register.submit' => 'Create account',
			'auth.register.submitting' => 'Creating account',
			'auth.register.globalError' => 'We could not complete registration. Review the highlighted fields and try again.',
			'auth.register.success' => 'Registration details accepted.',
			'auth.register.discardTitle' => 'Discard registration details?',
			'auth.register.discardBody' => 'Your unsaved registration values will be cleared.',
			'auth.register.stay' => 'Keep editing',
			'auth.register.discard' => 'Discard details',
			'auth.forgotPassword.title' => 'Reset your password',
			'auth.forgotPassword.body' => 'Enter an email address. The confirmation remains neutral and does not reveal whether an account exists.',
			'auth.forgotPassword.submit' => 'Send verification code',
			'auth.forgotPassword.submitting' => 'Preparing verification',
			'auth.forgotPassword.success' => 'If the address can receive a reset, a verification code will be available.',
			'auth.otp.registrationTitle' => 'Verify your registration',
			'auth.otp.registrationBody' => 'Enter the six-digit code to finish the static registration flow.',
			'auth.otp.passwordResetTitle' => 'Verify your reset request',
			'auth.otp.passwordResetBody' => 'Enter the six-digit code before choosing a new password.',
			'auth.otp.code' => 'Verification code',
			'auth.otp.submit' => 'Verify code',
			'auth.otp.submitting' => 'Verifying code',
			'auth.otp.resend' => 'Resend code',
			'auth.otp.resendIn' => ({required Object seconds}) => 'Resend available in ${seconds} seconds',
			'auth.otp.resending' => 'Resending code',
			'auth.otp.invalid' => 'That verification code is not valid.',
			'auth.otp.expired' => 'That verification code has expired. Request a new code.',
			'auth.otp.registrationSuccess' => 'Registration verified.',
			'auth.otp.passwordResetSuccess' => 'Reset request verified.',
			'auth.otp.mfaSuccess' => 'Sign-in verified.',
			'auth.otp.lockedTitle' => 'Too many attempts',
			'auth.otp.tooManyAttempts' => 'Too many failed attempts. Please wait.',
			'auth.otp.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 attempt remaining', other: '${count} attempts remaining', ), 
			'auth.otp.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'Try again now.', one: 'Try again in 1 second.', other: 'Try again in ${seconds} seconds.', ), 
			'auth.otp.mfaTitle' => 'Verify your sign-in',
			'auth.otp.mfaBody' => 'Enter the six-digit code we sent to complete sign-in.',
			'auth.otp.expiresIn' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Expires in 1 second', other: 'Expires in ${seconds} seconds', ), 
			'auth.otp.expiredTitle' => 'Code expired',
			'auth.otp.expiredBody' => 'Your verification code expired. Request a new code to continue.',
			'auth.resetPassword.title' => 'Choose a new password',
			'auth.resetPassword.body' => 'Use a strong password and enter it exactly the same way twice.',
			'auth.resetPassword.newPassword' => 'New password',
			'auth.resetPassword.submit' => 'Update password',
			'auth.resetPassword.submitting' => 'Updating password',
			'auth.resetPassword.globalError' => 'The static password update could not be completed.',
			'auth.resetPassword.success' => 'Password update preview complete. Return to login.',
			'profile.update.title' => 'Update profile',
			'profile.update.body' => 'Edit non-sensitive account details. Drafts remain only while this page is mounted.',
			'profile.update.avatar' => 'Profile image placeholder',
			'profile.update.changeAvatar' => 'Change profile image',
			'profile.update.avatarUnavailable' => 'Image selection is not connected and no permission was requested.',
			'profile.update.displayName' => 'Display name',
			'profile.update.username' => 'Username',
			'profile.update.email' => 'Email address',
			'profile.update.emailReadOnly' => 'Email cannot be changed in this static phase.',
			'profile.update.bio' => 'Bio',
			'profile.update.bioCounter' => ({required Object count, required Object maximum}) => '${count} of ${maximum} characters',
			'profile.update.save' => 'Save profile',
			'profile.update.saving' => 'Saving profile',
			'profile.update.saved' => 'Profile changes saved for this session.',
			'profile.update.globalError' => 'The static profile save could not be completed. Your values were kept.',
			'profile.update.discardTitle' => 'Discard profile changes?',
			'profile.update.discardBody' => 'Your unsaved profile changes will be cleared.',
			'profile.update.stay' => 'Keep editing',
			'profile.update.discard' => 'Discard changes',
			'security.biometric.lockTitle' => 'Unlock with biometrics',
			'security.biometric.lockBody' => 'Use your fingerprint or face to unlock the app.',
			'security.biometric.authFailedTitle' => 'Authentication failed. Try again.',
			'security.biometric.unlock' => 'Unlock',
			'security.biometric.unlocking' => 'Unlocking',
			'security.biometric.unavailableTitle' => 'Biometric unlock unavailable',
			'security.biometric.unavailableBody' => 'Biometric unlock is not available on this device. Use your device credentials instead.',
			'security.biometric.useFallback' => 'Use credentials',
			'security.passcode.enterTitle' => 'Enter passcode',
			'security.passcode.enterBody' => 'Enter your passcode to unlock the app.',
			'security.passcode.setupTitle' => 'Set a passcode',
			'security.passcode.setupBody' => 'Choose a numeric passcode you can use when biometrics are unavailable.',
			'security.passcode.confirmTitle' => 'Confirm passcode',
			'security.passcode.reenter' => 'Re-enter passcode',
			'security.passcode.mismatch' => 'The passcodes do not match. Try again.',
			'security.passcode.incorrect' => ({required num n, required Object attempts}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: 'Incorrect passcode. 1 attempt remaining.', other: 'Incorrect passcode. ${attempts} attempts remaining.', ), 
			'security.passcode.lockedOut' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, zero: 'Too many attempts. Try again now.', one: 'Too many attempts. Try again in 1 second.', other: 'Too many attempts. Try again in ${seconds} seconds.', ), 
			'security.passcode.disable' => 'Disable passcode',
			'forceUpdate.title' => 'Update required',
			'forceUpdate.body' => 'This version is no longer supported. Update to the latest version to continue.',
			'forceUpdate.updateNow' => 'Update now',
			'softUpdate.title' => 'A newer version is available',
			'softUpdate.body' => 'Update to the latest version for the latest improvements and fixes.',
			'softUpdate.update' => 'Update',
			'softUpdate.later' => 'Later',
			'session.expired' => 'Your session has expired. Please sign in again.',
			'session.signedOut' => 'You are signed out.',
			'session.signedInPreview' => ({required Object userId}) => 'Signed in as ${userId}',
			'session.unavailable' => 'Sign-in is not connected yet.',
			'splash.loading' => 'Starting up',
			'splash.tagline' => 'A thoughtful starting point',
			'splash.error' => 'We couldn\'t finish starting up.',
			'states.emptyTitle' => 'Nothing here yet',
			'states.emptyBody' => 'When content is available, it will appear here.',
			'states.errorTitle' => 'Could not load this',
			'states.errorBody' => 'Something went wrong while loading. Try again.',
			'states.loadingTitle' => 'Loading…',
			'announcements.dismiss' => 'Dismiss',
			'announcements.actionLearnMore' => 'Learn more',
			'announcements.dismissFailed' => 'Couldn\'t dismiss the announcement.',
			'announcements.severityInfo' => 'Information',
			'announcements.severitySuccess' => 'Success',
			'announcements.severityWarning' => 'Warning',
			'announcements.severityCritical' => 'Critical',
			'announcements.fixtures.welcome.title' => 'Welcome to the starter',
			'announcements.fixtures.welcome.message' => 'A durable foundation for your next product. Dismiss this to explore the shell.',
			'announcements.fixtures.changelog.title' => 'New in this version',
			'announcements.fixtures.changelog.message' => 'Announcements keep everyone in the loop without an app update.',
			'announcements.fixtures.deprecation.title' => 'A newer version is available',
			'announcements.fixtures.deprecation.message' => 'This build will be deprecated soon. Update when you can.',
			'announcements.fixtures.outage.title' => 'Service outage',
			'announcements.fixtures.outage.message' => 'Some actions may fail while we resolve a service disruption.',
			'validation.required' => ({required Object field}) => '${field} is required.',
			'validation.email' => 'Enter a valid email address.',
			'validation.passwordWeak' => 'Use at least 8 characters with an uppercase letter and a number.',
			'validation.passwordMismatch' => 'The passwords do not match.',
			'validation.acceptTerms' => 'Accept the terms and privacy preview to continue.',
			'validation.otpDigits' => 'Enter all six digits.',
			'validation.username' => 'Use 3–24 letters, numbers, periods, or underscores.',
			'validation.bioTooLong' => ({required Object maximum}) => 'Keep the bio to ${maximum} characters or fewer.',
			'routeError.title' => 'We could not open that page',
			'routeError.body' => 'The address is unknown or incomplete. You can return to a safe page.',
			'routeError.path' => ({required Object path}) => 'Requested address: ${path}',
			'routeError.invalidOtpPurpose' => 'The verification address needs a valid registration or password-reset purpose.',
			'startupFailure.title' => 'The application could not start',
			'startupFailure.body' => 'Close and restart the application. If the problem continues, share the diagnostic ID with support.',
			'startupFailure.diagnosticId' => ({required Object id}) => 'Diagnostic ID: ${id}',
			'diagnostics.title' => 'Development diagnostics',
			'diagnostics.environment' => 'Environment',
			'diagnostics.build' => 'Build',
			'diagnostics.layout' => 'Layout class',
			'diagnostics.interaction' => 'Interaction policy',
			'diagnostics.lifecycle' => 'App lifecycle',
			'diagnostics.locale' => 'Locale',
			'diagnostics.capabilities' => 'Platform capabilities',
			'diagnostics.secureStorage' => 'Secure storage',
			'diagnostics.crashReporting' => 'Crash reporting',
			'diagnostics.crashReportingNone' => 'Not configured',
			'diagnostics.analytics' => 'Analytics',
			'diagnostics.analyticsNone' => 'Not configured',
			'diagnostics.featureFlags' => 'Feature flags',
			'diagnostics.redactedNotice' => 'Diagnostics exclude credentials and user content.',
			'diagnostics.experiments.title' => 'Experiments',
			'diagnostics.experiments.source' => 'Source',
			'devGallery.title' => 'Production screen gallery',
			'devGallery.search' => 'Search cases',
			'devGallery.screen' => 'Screen',
			'devGallery.galleryCase' => 'Gallery case',
			'devGallery.preview' => 'Preview',
			'devGallery.viewport' => 'Viewport',
			'devGallery.locale' => 'Locale',
			'devGallery.theme' => 'Theme',
			'devGallery.accent' => 'Accent',
			'devGallery.textScale' => 'Text scaling',
			'devGallery.systemTextScale' => 'System text scaling',
			'devGallery.interaction' => 'Interaction policy',
			'devGallery.motion' => 'Motion',
			'devGallery.highContrast' => 'High contrast',
			'devGallery.boldText' => 'Bold text',
			'devGallery.safeArea' => 'Safe-area padding',
			'devGallery.keyboardInsets' => 'Keyboard inset',
			'devGallery.displayFeature' => 'Display feature',
			'devGallery.light' => 'Light',
			'devGallery.dark' => 'Dark',
			'devGallery.enabled' => 'Enabled',
			'devGallery.disabled' => 'Disabled',
			'devGallery.normal' => 'Normal',
			'devGallery.maximum' => 'Maximum nonlinear',
			'devGallery.touch' => 'Touch',
			'devGallery.precision' => 'Precision pointer',
			'devGallery.hybrid' => 'Hybrid input',
			'devGallery.none' => 'None',
			'devGallery.fold' => 'Vertical fold',
			'devGallery.resetControls' => 'Reset preview controls',
			'devGallery.viewportCompactPhone' => 'Compact phone',
			'devGallery.viewportShortPhone' => 'Short landscape phone',
			'devGallery.viewportBelowMedium' => 'Below medium boundary',
			'devGallery.viewportAtMedium' => 'At medium boundary',
			'devGallery.viewportMedium' => 'Medium window',
			'devGallery.viewportBelowExpanded' => 'Below expanded boundary',
			'devGallery.viewportAtExpanded' => 'At expanded boundary',
			'devGallery.viewportDesktop' => 'Desktop',
			'devGallery.viewportNarrowDesktop' => 'Narrow resized desktop',
			'devGallery.screenOnboarding' => 'Onboarding',
			'devGallery.screenPaywall' => 'Onboarding paywall',
			'devGallery.screenHome' => 'Home',
			'devGallery.screenLogin' => 'Login',
			'devGallery.screenRegister' => 'Register',
			'devGallery.screenForgotPassword' => 'Forgot password',
			'devGallery.screenOtpRegistration' => 'Registration verification',
			'devGallery.screenOtpPasswordReset' => 'Reset verification',
			'devGallery.screenResetPassword' => 'Reset password',
			'devGallery.screenProfile' => 'Update profile',
			'devGallery.screenPricing' => 'Pricing',
			'devGallery.screenSettings' => 'Settings',
			'devGallery.screenConnectivity' => 'Connectivity banner',
			'devGallery.screenForceUpdate' => 'Force update',
			'devGallery.screenSoftUpdate' => 'Soft update',
			'devGallery.screenBusy' => 'Busy indicators',
			'devGallery.screenSystem' => 'System surfaces',
			'devGallery.screenOverlays' => 'Overlays',
			'devGallery.screenSplash' => 'In-app splash',
			'devGallery.screenStateViews' => 'State views',
			'devGallery.screenFormScaffolding' => 'Form scaffolding',
			'devGallery.screenAnnouncements' => 'Announcements banner',
			'devGallery.caseSplashLoading' => 'Loading',
			'devGallery.caseSplashReady' => 'Ready',
			'devGallery.caseSplashError' => 'Startup error',
			'devGallery.caseStateEmpty' => 'Empty',
			'devGallery.caseStateError' => 'Error',
			'devGallery.caseStateLoading' => 'Loading',
			'devGallery.caseFormScaffoldDisabled' => 'Submit disabled',
			'devGallery.caseFormScaffoldEnabled' => 'Submit enabled',
			'devGallery.caseFormScaffoldSubmitting' => 'Submitting',
			'devGallery.caseAnnouncementsInfo' => 'Info',
			'devGallery.caseAnnouncementsSuccess' => 'Success',
			'devGallery.caseAnnouncementsWarning' => 'Warning',
			'devGallery.caseAnnouncementsCritical' => 'Critical',
			'devGallery.caseDefault' => 'Default',
			'devGallery.caseHardBlock' => 'Hard block',
			'devGallery.caseSoftUpdate' => 'Soft update',
			'devGallery.caseBusyIndeterminate' => 'Indeterminate',
			'devGallery.caseBusyDeterminate' => 'Determinate',
			'devGallery.caseBusyOverlay' => 'Modal overlay',
			'devGallery.caseExpandedCopy' => 'Expanded copy',
			'devGallery.caseFirst' => 'First',
			'devGallery.caseMiddle' => 'Middle',
			'devGallery.caseFinal' => 'Final',
			'devGallery.caseMonthly' => 'Monthly',
			'devGallery.caseAnnual' => 'Annual',
			'devGallery.caseRecommended' => 'Recommended',
			'devGallery.caseUnavailable' => 'Unavailable',
			'devGallery.caseEmpty' => 'Empty',
			'devGallery.caseFocused' => 'Focused',
			'devGallery.caseInvalid' => 'Invalid',
			'devGallery.caseSubmitting' => 'Submitting',
			'devGallery.caseFieldError' => 'Field error',
			'devGallery.caseGlobalError' => 'Global error',
			'devGallery.caseSuccess' => 'Success',
			'devGallery.casePartial' => 'Partial',
			'devGallery.casePastedComplete' => 'Pasted complete',
			'devGallery.caseExpired' => 'Expired',
			'devGallery.caseResending' => 'Resending',
			'devGallery.caseSaving' => 'Saving',
			'devGallery.caseSaved' => 'Saved',
			'devGallery.caseDirty' => 'Dirty',
			'devGallery.caseDiscardPrompt' => 'Discard prompt',
			'devGallery.caseStartupFailure' => 'Startup failure',
			'devGallery.caseUnknownRoute' => 'Unknown route',
			'devGallery.caseMalformedOtp' => 'Malformed OTP purpose',
			'devGallery.caseDiagnostics' => 'Diagnostics',
			'devGallery.caseDialog' => 'Dialog',
			'devGallery.caseSheet' => 'Sheet',
			'devGallery.caseToast' => 'Toast',
			'devGallery.casePopover' => 'Popover',
			'devGallery.caseTooltip' => 'Tooltip',
			'devGallery.caseKeyboardInset' => 'Keyboard-inset form',
			'devGallery.screenSession' => 'Session',
			'devGallery.caseSessionLoggedOut' => 'Logged out',
			'devGallery.caseSessionLoggedIn' => 'Logged in',
			'devGallery.screenAnalytics' => 'Analytics opt-in',
			'devGallery.screenBiometricLock' => 'Biometric lock',
			'devGallery.caseLocked' => 'Locked',
			'devGallery.caseNotFound' => 'The requested gallery case is not registered.',
			'devGallery.screenAccessibility' => 'Accessibility presets',
			'devGallery.caseAccessibilityComfortable' => 'Comfortable preset',
			'devGallery.caseAccessibilityLarge' => 'Large preset',
			'devGallery.caseAccessibilityDyslexia' => 'Dyslexia preset',
			'devGallery.screenPullRefresh' => 'Pull-to-refresh',
			'devGallery.casePullRefreshList' => 'Refreshable list',
			'devGallery.casePullRefreshGrid' => 'Responsive grid',
			'devGallery.screenHaptics' => 'Haptics',
			'devGallery.caseHapticKinds' => 'All kinds',
			'devGallery.caseHapticSelection' => 'Selection',
			'devGallery.caseHapticImpactLight' => 'Light impact',
			'devGallery.caseHapticImpactMedium' => 'Medium impact',
			'devGallery.caseHapticImpactHeavy' => 'Heavy impact',
			'devGallery.caseHapticSuccess' => 'Success',
			'devGallery.caseHapticWarning' => 'Warning',
			'devGallery.caseHapticError' => 'Error',
			'devGallery.screenSkeleton' => 'Skeleton loading',
			'devGallery.caseSkeletonStatic' => 'Static (reduce-motion)',
			'devGallery.caseSkeletonShimmer' => 'Shimmer',
			'devGallery.screenOtpMfa' => 'MFA verification',
			'devGallery.caseCountdown' => 'Countdown',
			'devGallery.screenNotifications' => 'Notifications',
			'devGallery.caseNotificationsNotRequested' => 'Permission rationale',
			'devGallery.caseNotificationsGranted' => 'Granted',
			'devGallery.caseNotificationsDenied' => 'Blocked',
			'devGallery.screenPermissions' => 'Permissions',
			'devGallery.casePermissionRationale' => 'Rationale',
			'devGallery.casePermissionDenied' => 'Denied',
			'devGallery.casePermissionPermanentlyDenied' => 'Permanently denied',
			'devGallery.screenLicense' => 'Licenses',
			'devGallery.screenShare' => 'Share sheet',
			'devGallery.screenAppUpdate' => 'In-app update',
			'devGallery.screenSearchPagination' => 'Search & pagination',
			'devGallery.caseSearchField' => 'Search field',
			'devGallery.caseSearchPaged' => 'Paged list',
			'devGallery.caseSearchPagedNoBackend' => 'Paged list (no backend)',
			'devGallery.screenToastDialogs' => 'Toasts & dialogs',
			'devGallery.caseToastSuccess' => 'Success toast',
			'devGallery.caseToastInfo' => 'Info toast',
			'devGallery.caseToastWarning' => 'Warning toast',
			'devGallery.caseToastError' => 'Error toast',
			'devGallery.caseDialogConfirm' => 'Confirm dialog',
			'devGallery.caseDialogDestroy' => 'Destroy dialog',
			'devGallery.screenPasscodeEntry' => 'Passcode entry',
			'devGallery.screenPasscodeSetup' => 'Passcode setup',
			'devGallery.casePasscodeIdle' => 'Idle',
			'devGallery.casePasscodeError' => 'Incorrect',
			'devGallery.casePasscodeLockedOut' => 'Locked out',
			'devGallery.casePasscodeSetupMismatch' => 'Confirm mismatch',
			'devGallery.screenFeedback' => 'Feedback',
			'devGallery.caseFeedbackDrafting' => 'Drafting',
			'devGallery.caseFeedbackSubmitting' => 'Submitting',
			'devGallery.caseFeedbackFailed' => 'Failed',
			'devGallery.caseFeedbackSuccess' => 'Success',
			'notifications.enableTitle' => 'Turn on notifications',
			'notifications.enableBody' => 'Get timely updates about your account and activity. You can change this anytime.',
			'notifications.deny' => 'Not now',
			'notifications.allow' => 'Allow',
			'notifications.enableBlockedTitle' => 'Notifications are blocked',
			'notifications.enableBlockedBody' => 'Open system settings to allow notifications for this app.',
			'notifications.disabled' => 'Notifications are not connected in this starter.',
			'deepLink.unsupported' => 'This link could not be opened in the app.',
			'permission.camera.title' => 'Camera access',
			'permission.camera.rationale' => 'We use the camera to take a new profile photo. You can decline any time.',
			'permission.photos.title' => 'Photo library access',
			_ => null,
		} ?? switch (path) {
			'permission.photos.rationale' => 'We read your photo library so you can pick a profile photo. You can decline any time.',
			'permission.location.title' => 'Location access',
			'permission.location.rationale' => 'We use your location to personalize your experience. You can decline any time.',
			'permission.continueRequest' => 'Continue',
			'permission.notNow' => 'Not now',
			'permission.openSettings' => 'Open settings',
			'permission.denied' => 'Permission was denied. You can try again any time.',
			'permission.permanentlyDenied' => 'Permission is blocked. Turn it on in system settings to continue.',
			'share.success' => 'Shared',
			'share.unavailable' => 'Sharing is not available on this device.',
			'share.cancelled' => 'Share cancelled.',
			'update.checkForUpdates' => 'Check for updates',
			'update.available' => 'An update is available.',
			'update.notAvailable' => 'You\'re on the latest version.',
			'update.required' => 'An update is required to continue.',
			'search.title' => 'Search',
			'search.placeholder' => 'Search…',
			'search.emptyTitle' => 'No results',
			'search.emptyBody' => 'Try a different search term.',
			'search.errorTitle' => 'Search is unavailable',
			'feedback.title' => 'Send feedback',
			'feedback.messageLabel' => 'Message',
			'feedback.messageHint' => 'What happened, or what could be better?',
			'feedback.includeScreenshot' => 'Include a screenshot',
			'feedback.emailOptional' => 'Reply-to email',
			'feedback.submit' => 'Send',
			'feedback.cancel' => 'Cancel',
			'feedback.successTitle' => 'Thanks!',
			'feedback.successBody' => 'Your feedback was sent.',
			'feedback.failedTitle' => 'We couldn\'t send your feedback right now.',
			'feedback.shakeEnabled' => 'Open feedback on shake',
			_ => null,
		};
	}
}
