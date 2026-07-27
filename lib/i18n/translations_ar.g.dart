///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$ar app = _Translations$app$ar._(_root);
	@override late final _Translations$common$ar common = _Translations$common$ar._(_root);
	@override late final _Translations$connectivity$ar connectivity = _Translations$connectivity$ar._(_root);
	@override late final _Translations$navigation$ar navigation = _Translations$navigation$ar._(_root);
	@override late final _Translations$onboarding$ar onboarding = _Translations$onboarding$ar._(_root);
	@override late final _Translations$pricing$ar pricing = _Translations$pricing$ar._(_root);
	@override late final _Translations$home$ar home = _Translations$home$ar._(_root);
	@override late final _Translations$settings$ar settings = _Translations$settings$ar._(_root);
	@override late final _Translations$auth$ar auth = _Translations$auth$ar._(_root);
	@override late final _Translations$profile$ar profile = _Translations$profile$ar._(_root);
	@override late final _Translations$security$ar security = _Translations$security$ar._(_root);
	@override late final _Translations$forceUpdate$ar forceUpdate = _Translations$forceUpdate$ar._(_root);
	@override late final _Translations$softUpdate$ar softUpdate = _Translations$softUpdate$ar._(_root);
	@override late final _Translations$session$ar session = _Translations$session$ar._(_root);
	@override late final _Translations$splash$ar splash = _Translations$splash$ar._(_root);
	@override late final _Translations$states$ar states = _Translations$states$ar._(_root);
	@override late final _Translations$announcements$ar announcements = _Translations$announcements$ar._(_root);
	@override late final _Translations$validation$ar validation = _Translations$validation$ar._(_root);
	@override late final _Translations$routeError$ar routeError = _Translations$routeError$ar._(_root);
	@override late final _Translations$startupFailure$ar startupFailure = _Translations$startupFailure$ar._(_root);
	@override late final _Translations$diagnostics$ar diagnostics = _Translations$diagnostics$ar._(_root);
	@override late final _Translations$devGallery$ar devGallery = _Translations$devGallery$ar._(_root);
}

// Path: app
class _Translations$app$ar extends Translations$app$en {
	_Translations$app$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get name => 'نقطة البداية';
}

// Path: common
class _Translations$common$ar extends Translations$common$en {
	_Translations$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get back => 'رجوع';
	@override String get home => 'الرئيسية';
	@override String get retry => 'إعادة المحاولة';
	@override String get save => 'حفظ';
	@override String get cancel => 'إلغاء';
	@override String get close => 'إغلاق';
	@override String get continueAction => 'متابعة';
	@override String get skip => 'تخطي';
	@override String get reset => 'إعادة تعيين';
	@override String get done => 'تم';
	@override String get previous => 'السابق';
	@override String get next => 'التالي';
	@override String get optional => 'اختياري';
	@override String get loading => 'جارٍ التحميل';
	@override String get saving => 'جارٍ الحفظ…';
	@override String get notConnected => 'هذا الإجراء غير متصل بعد.';
	@override String get legalPlaceholderTitle => 'معاينة المعلومات';
	@override String get legalPlaceholderBody => 'يعرض هذا القالب محتوى تجريبيًا واضحًا إلى أن تتم الموافقة على النص القانوني الخاص بالمنتج.';
}

// Path: connectivity
class _Translations$connectivity$ar extends Translations$connectivity$en {
	_Translations$connectivity$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get online => 'متصل';
	@override String get offline => 'أنت غير متصل. قد لا تتوفر بعض الإجراءات.';
	@override String get backOnline => 'عاد الاتصال بالإنترنت.';
	@override String get limited => 'اتصال محدود. قد تكون بعض الإجراءات بطيئة أو غير متوفرة.';
}

// Path: navigation
class _Translations$navigation$ar extends Translations$navigation$en {
	_Translations$navigation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get home => 'الرئيسية';
	@override String get pricing => 'الأسعار';
	@override String get settings => 'الإعدادات';
}

// Path: onboarding
class _Translations$onboarding$ar extends Translations$onboarding$en {
	_Translations$onboarding$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get brand => 'نقطة بداية مدروسة';
	@override String progress({required Object current, required Object total}) => 'الخطوة ${current} من ${total}';
	@override String get firstTitle => 'ابدأ من أساس متين';
	@override String get firstBody => 'ابدأ بإعدادات صريحة وفحوص جودة صارمة وواجهة جاهزة للنمو.';
	@override String get middleTitle => 'مصمم لكل شاشة';
	@override String get middleBody => 'تتكيف صفحات الإنتاج نفسها من شاشات اللمس المدمجة إلى سير عمل سطح المكتب الدقيق.';
	@override String get finalTitle => 'تفضيلاتك ملكك';
	@override String get finalBody => 'اختر المظهر واللغة وحجم النص من دون إخفاء إعدادات إمكانية الوصول في النظام.';
	@override String get openPaywall => 'مراجعة الخطط';
}

// Path: pricing
class _Translations$pricing$ar extends Translations$pricing$en {
	_Translations$pricing$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'خطط تناسب طريقة عملك';
	@override String get body => 'قارن مجموعة صغيرة وواضحة من الخطط التجريبية. الشراء غير متصل عمدًا في هذا القالب.';
	@override String get monthly => 'شهري';
	@override String get annual => 'سنوي';
	@override String get billedMonthly => 'الفوترة كل شهر';
	@override String get billedAnnually => 'الفوترة مرة كل سنة';
	@override String get periodMonth => 'شهريًا';
	@override String get periodYear => 'سنويًا';
	@override String get recommended => 'موصى بها';
	@override String get current => 'الخطة الحالية';
	@override String choosePlan({required Object plan}) => 'معاينة ${plan}';
	@override String get unavailable => 'غير متاحة';
	@override String get unavailableReason => 'اختيار الخطة غير متاح في هذه المعاينة. لا يزال بإمكانك مراجعة كل الخطط.';
	@override String get comparisonTitle => 'مقارنة الخطط';
	@override String get faqTitle => 'أسئلة شائعة';
	@override String get faqQuestion => 'هل يمكنني تغيير الخطة لاحقًا؟';
	@override String get faqAnswer => 'نعم. هذه التجربة الثابتة تعرض التخطيط فقط، ولا تنشئ أي اشتراك.';
	@override String get restore => 'استعادة المشتريات';
	@override String get restoreUnavailable => 'استعادة المشتريات غير متصلة في هذا القالب.';
	@override String get terms => 'الشروط';
	@override String get privacy => 'الخصوصية';
	@override String get staticPurchaseNotice => 'لن يتم إجراء دفع أو شراء.';
	@override String get staticSuccess => 'اكتملت معاينة اختيار الخطة. لم يتم أي شراء.';
	@override String get paywallTitle => 'واصل البناء بمساحة أكبر';
	@override String get paywallBody => 'راجع المزايا واختر دورة الفوترة أو تخطَّ وتابع استكشاف القالب.';
	@override String get paywallContinue => 'معاينة الخطة المحددة والمتابعة';
	@override String get benefitAdaptive => 'تخطيطات متكيفة للهاتف وسطح المكتب';
	@override String get benefitLocalized => 'الإنجليزية والعربية والصينية المبسطة';
	@override String get benefitAccessible => 'تحجيم وسياسات إدخال تراعي إمكانية الوصول';
	@override late final _Translations$pricing$plans$ar plans = _Translations$pricing$plans$ar._(_root);
}

// Path: home
class _Translations$home$ar extends Translations$home$en {
	_Translations$home$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'بداية متينة لتطبيقك';
	@override String get body => 'تعمل بنية التطبيق الآن بإعدادات صريحة وتنقل متكيف وعناصر مترجمة.';
	@override String greeting({required Object name}) => 'مرحبًا، ${name}';
	@override String get summary => 'القالب مضبوط وجاهز لإضافة القدرة الحقيقية التالية للمنتج.';
	@override String get quickActions => 'إجراءات سريعة';
	@override String get editProfile => 'تحديث الملف الشخصي';
	@override String get openSettings => 'فتح الإعدادات';
	@override String get openPricing => 'عرض الأسعار';
	@override String get openLogin => 'تجربة تسجيل الدخول';
	@override String get statusTitle => 'حالة الأساس';
	@override String get statusReadyTitle => 'جاهز للتوسعة';
	@override String get statusReadyBody => 'تم ربط الإعدادات والتوجيه والترجمة والتخطيط المتكيف.';
	@override String get statusAdaptiveTitle => 'متكيف افتراضيًا';
	@override String get statusAdaptiveBody => 'غيّر حجم النافذة من دون إعادة تعيين المسار أو حالة الميزة.';
	@override String get statusLocalizedTitle => 'الترجمة من جذر التطبيق';
	@override String get statusLocalizedBody => 'تستخدم نصوص التطبيق وForUI اللغة والاتجاه المحددين معًا.';
	@override String get recentTitle => 'النشاط الأخير';
	@override String get recentEmptyTitle => 'لا يوجد نشاط بعد';
	@override String get recentEmptyBody => 'يمكن أن يحل نشاط المنتج الحقيقي محل هذه الحالة الفارغة الواضحة عند اختيار مجال المنتج.';
}

// Path: settings
class _Translations$settings$ar extends Translations$settings$en {
	_Translations$settings$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الإعدادات';
	@override String get appearance => 'المظهر';
	@override String get language => 'اللغة';
	@override String get account => 'الحساب';
	@override String get subscription => 'الاشتراك';
	@override String get privacyAbout => 'الخصوصية وحول التطبيق';
	@override String get themeMode => 'نمط السمة';
	@override String get system => 'النظام';
	@override String get light => 'فاتح';
	@override String get dark => 'داكن';
	@override String get accent => 'اللون المميز';
	@override String get accentNeutral => 'محايد';
	@override String get accentGreen => 'أخضر';
	@override String get accentBlue => 'أزرق';
	@override String get accentAmber => 'كهرماني';
	@override String get accentRose => 'وردي';
	@override String get accentViolet => 'بنفسجي';
	@override String get fontScale => 'حجم النص';
	@override String get motionPreview => 'معاينة الحركة';
	@override String get locale => 'لغة التطبيق';
	@override String get languageSystem => 'استخدام لغة الجهاز';
	@override String get languageEnglish => 'الإنجليزية';
	@override String get languageArabic => 'العربية';
	@override String get languageChinese => 'الصينية المبسطة';
	@override String get saved => 'تم حفظ الإعدادات';
	@override String get accountBody => 'راجع تدفقات الملف الشخصي والمصادقة الثابتة.';
	@override String get openProfile => 'تحديث الملف الشخصي';
	@override String get openLogin => 'فتح تسجيل الدخول';
	@override String get subscriptionBody => 'قارن الخطط من دون بدء عملية شراء.';
	@override String get openPricing => 'عرض الأسعار';
	@override String get privacyBody => 'يخزن هذا القالب تفضيلات المظهر واللغة فقط خلال المرحلة الثابتة.';
	@override String get aboutBuild => 'معلومات الإصدار';
	@override String get terms => 'معاينة الشروط';
	@override String get privacy => 'معاينة الخصوصية';
	@override String get enableBiometric => 'إلغاء القفل بالقياس الحيوي';
	@override late final _Translations$settings$analytics$ar analytics = _Translations$settings$analytics$ar._(_root);
}

// Path: auth
class _Translations$auth$ar extends Translations$auth$en {
	_Translations$auth$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$auth$common$ar common = _Translations$auth$common$ar._(_root);
	@override late final _Translations$auth$login$ar login = _Translations$auth$login$ar._(_root);
	@override late final _Translations$auth$register$ar register = _Translations$auth$register$ar._(_root);
	@override late final _Translations$auth$forgotPassword$ar forgotPassword = _Translations$auth$forgotPassword$ar._(_root);
	@override late final _Translations$auth$otp$ar otp = _Translations$auth$otp$ar._(_root);
	@override late final _Translations$auth$resetPassword$ar resetPassword = _Translations$auth$resetPassword$ar._(_root);
}

// Path: profile
class _Translations$profile$ar extends Translations$profile$en {
	_Translations$profile$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$profile$update$ar update = _Translations$profile$update$ar._(_root);
}

// Path: security
class _Translations$security$ar extends Translations$security$en {
	_Translations$security$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$security$biometric$ar biometric = _Translations$security$biometric$ar._(_root);
}

// Path: forceUpdate
class _Translations$forceUpdate$ar extends Translations$forceUpdate$en {
	_Translations$forceUpdate$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'يلزم تحديث التطبيق';
	@override String get body => 'لم يعد هذا الإصدار مدعومًا. حدّث إلى أحدث إصدار للمتابعة.';
	@override String get updateNow => 'تحديث الآن';
}

// Path: softUpdate
class _Translations$softUpdate$ar extends Translations$softUpdate$en {
	_Translations$softUpdate$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'يتوفر إصدار أحدث';
	@override String get body => 'حدّث إلى أحدث إصدار للحصول على أحدث التحسينات والإصلاحات.';
	@override String get update => 'تحديث';
	@override String get later => 'لاحقًا';
}

// Path: session
class _Translations$session$ar extends Translations$session$en {
	_Translations$session$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get expired => 'انتهت جلستك. يُرجى تسجيل الدخول من جديد.';
	@override String get signedOut => 'تم تسجيل خروجك.';
	@override String signedInPreview({required Object userId}) => 'تم تسجيل دخولك بصفتك ${userId}';
	@override String get unavailable => 'تسجيل الدخول غير متصل بعد.';
}

// Path: splash
class _Translations$splash$ar extends Translations$splash$en {
	_Translations$splash$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get loading => 'جارٍ التشغيل';
	@override String get tagline => 'نقطة انطلاق مدروسة';
	@override String get error => 'تعذّر إكمال التشغيل.';
}

// Path: states
class _Translations$states$ar extends Translations$states$en {
	_Translations$states$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => 'لا يوجد شيء هنا بعد';
	@override String get emptyBody => 'عند توفّر المحتوى، سيظهر هنا.';
	@override String get errorTitle => 'تعذّر تحميل هذا';
	@override String get errorBody => 'حدث خطأ أثناء التحميل. حاول مرة أخرى.';
	@override String get loadingTitle => 'جارٍ التحميل…';
}

// Path: announcements
class _Translations$announcements$ar extends Translations$announcements$en {
	_Translations$announcements$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get dismiss => 'إغلاق';
	@override String get actionLearnMore => 'اعرف المزيد';
	@override String get dismissFailed => 'تعذّر إغلاق الإعلان.';
	@override String get severityInfo => 'معلومة';
	@override String get severitySuccess => 'نجاح';
	@override String get severityWarning => 'تحذير';
	@override String get severityCritical => 'حرج';
	@override late final _Translations$announcements$fixtures$ar fixtures = _Translations$announcements$fixtures$ar._(_root);
}

// Path: validation
class _Translations$validation$ar extends Translations$validation$en {
	_Translations$validation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String required({required Object field}) => 'حقل ${field} مطلوب.';
	@override String get email => 'أدخل بريدًا إلكترونيًا صالحًا.';
	@override String get passwordWeak => 'استخدم 8 أحرف على الأقل مع حرف لاتيني كبير ورقم.';
	@override String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';
	@override String get acceptTerms => 'وافق على معاينة الشروط والخصوصية للمتابعة.';
	@override String get otpDigits => 'أدخل الأرقام الستة كاملة.';
	@override String get username => 'استخدم من 3 إلى 24 حرفًا أو رقمًا أو نقطة أو شرطة سفلية.';
	@override String bioTooLong({required Object maximum}) => 'اجعل النبذة في حدود ${maximum} حرفًا.';
}

// Path: routeError
class _Translations$routeError$ar extends Translations$routeError$en {
	_Translations$routeError$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تعذر فتح هذه الصفحة';
	@override String get body => 'العنوان غير معروف أو غير مكتمل. يمكنك العودة إلى صفحة آمنة.';
	@override String path({required Object path}) => 'العنوان المطلوب: ${path}';
	@override String get invalidOtpPurpose => 'يحتاج عنوان التحقق إلى غرض صالح للتسجيل أو إعادة تعيين كلمة المرور.';
}

// Path: startupFailure
class _Translations$startupFailure$ar extends Translations$startupFailure$en {
	_Translations$startupFailure$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تعذر تشغيل التطبيق';
	@override String get body => 'أغلق التطبيق وأعد تشغيله. إذا استمرت المشكلة، شارك معرّف التشخيص مع الدعم.';
	@override String diagnosticId({required Object id}) => 'معرّف التشخيص: ${id}';
}

// Path: diagnostics
class _Translations$diagnostics$ar extends Translations$diagnostics$en {
	_Translations$diagnostics$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تشخيصات التطوير';
	@override String get environment => 'البيئة';
	@override String get build => 'الإصدار';
	@override String get layout => 'فئة التخطيط';
	@override String get interaction => 'سياسة التفاعل';
	@override String get lifecycle => 'دورة حياة التطبيق';
	@override String get locale => 'اللغة';
	@override String get capabilities => 'إمكانات المنصة';
	@override String get secureStorage => 'التخزين الآمن';
	@override String get crashReporting => 'الإبلاغ عن الأعطال';
	@override String get crashReportingNone => 'غير مُهيَّأ';
	@override String get analytics => 'التحليلات';
	@override String get analyticsNone => 'غير مُهيّأ';
	@override String get featureFlags => 'ميزات تجريبية';
	@override String get redactedNotice => 'لا تتضمن التشخيصات بيانات الاعتماد أو محتوى المستخدم.';
}

// Path: devGallery
class _Translations$devGallery$ar extends Translations$devGallery$en {
	_Translations$devGallery$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'معرض شاشات الإنتاج';
	@override String get search => 'البحث في الحالات';
	@override String get screen => 'الشاشة';
	@override String get galleryCase => 'حالة المعرض';
	@override String get preview => 'المعاينة';
	@override String get viewport => 'مساحة العرض';
	@override String get locale => 'اللغة';
	@override String get theme => 'السمة';
	@override String get accent => 'لون التمييز';
	@override String get textScale => 'تحجيم النص';
	@override String get systemTextScale => 'تحجيم نص النظام';
	@override String get interaction => 'سياسة التفاعل';
	@override String get motion => 'الحركة';
	@override String get highContrast => 'تباين عالٍ';
	@override String get boldText => 'نص عريض';
	@override String get safeArea => 'حشو المنطقة الآمنة';
	@override String get keyboardInsets => 'إزاحة لوحة المفاتيح';
	@override String get displayFeature => 'ميزة العرض';
	@override String get light => 'فاتحة';
	@override String get dark => 'داكنة';
	@override String get enabled => 'مفعّل';
	@override String get disabled => 'معطّل';
	@override String get normal => 'عادي';
	@override String get maximum => 'أقصى تحجيم غير خطي';
	@override String get touch => 'لمس';
	@override String get precision => 'مؤشر دقيق';
	@override String get hybrid => 'إدخال هجين';
	@override String get none => 'بلا';
	@override String get fold => 'طي رأسي';
	@override String get resetControls => 'إعادة ضبط عناصر المعاينة';
	@override String get viewportCompactPhone => 'هاتف مدمج';
	@override String get viewportShortPhone => 'هاتف أفقي قصير';
	@override String get viewportBelowMedium => 'قبل حد التخطيط المتوسط';
	@override String get viewportAtMedium => 'عند حد التخطيط المتوسط';
	@override String get viewportMedium => 'نافذة متوسطة';
	@override String get viewportBelowExpanded => 'قبل حد التخطيط الموسع';
	@override String get viewportAtExpanded => 'عند حد التخطيط الموسع';
	@override String get viewportDesktop => 'سطح المكتب';
	@override String get viewportNarrowDesktop => 'سطح مكتب ضيق بعد تغيير الحجم';
	@override String get screenOnboarding => 'التعريف';
	@override String get screenPaywall => 'عرض خطط التعريف';
	@override String get screenHome => 'الرئيسية';
	@override String get screenLogin => 'تسجيل الدخول';
	@override String get screenRegister => 'إنشاء حساب';
	@override String get screenForgotPassword => 'نسيت كلمة المرور';
	@override String get screenOtpRegistration => 'التحقق من التسجيل';
	@override String get screenOtpPasswordReset => 'التحقق من إعادة التعيين';
	@override String get screenResetPassword => 'إعادة تعيين كلمة المرور';
	@override String get screenProfile => 'تحديث الملف الشخصي';
	@override String get screenPricing => 'الأسعار';
	@override String get screenSettings => 'الإعدادات';
	@override String get screenConnectivity => 'شريط حالة الاتصال';
	@override String get screenForceUpdate => 'تحديث إلزامي';
	@override String get screenSoftUpdate => 'تحديث اختياري';
	@override String get screenBusy => 'مؤشرات الانشغال';
	@override String get screenSystem => 'واجهات النظام';
	@override String get screenOverlays => 'الطبقات العلوية';
	@override String get screenSplash => 'شاشة البداية داخل التطبيق';
	@override String get screenStateViews => 'حالات العرض';
	@override String get screenFormScaffolding => 'هيكل النموذج';
	@override String get screenAnnouncements => 'شريط الإعلانات';
	@override String get caseSplashLoading => 'جارٍ التشغيل';
	@override String get caseSplashReady => 'جاهز';
	@override String get caseSplashError => 'خطأ في التشغيل';
	@override String get caseStateEmpty => 'فارغة';
	@override String get caseStateError => 'خطأ';
	@override String get caseStateLoading => 'جارٍ التحميل';
	@override String get caseFormScaffoldDisabled => 'إرسال معطّل';
	@override String get caseFormScaffoldEnabled => 'إرسال مفعّل';
	@override String get caseFormScaffoldSubmitting => 'جارٍ الإرسال';
	@override String get caseAnnouncementsInfo => 'معلومة';
	@override String get caseAnnouncementsSuccess => 'نجاح';
	@override String get caseAnnouncementsWarning => 'تحذير';
	@override String get caseAnnouncementsCritical => 'حرج';
	@override String get caseDefault => 'افتراضية';
	@override String get caseHardBlock => 'حظر إلزامي';
	@override String get caseSoftUpdate => 'تحديث اختياري';
	@override String get caseBusyIndeterminate => 'غير محدد';
	@override String get caseBusyDeterminate => 'محدد';
	@override String get caseBusyOverlay => 'طبقة مشروطة';
	@override String get caseExpandedCopy => 'نص موسّع';
	@override String get caseFirst => 'الأولى';
	@override String get caseMiddle => 'الوسطى';
	@override String get caseFinal => 'الأخيرة';
	@override String get caseMonthly => 'شهرية';
	@override String get caseAnnual => 'سنوية';
	@override String get caseRecommended => 'موصى بها';
	@override String get caseUnavailable => 'غير متاحة';
	@override String get caseEmpty => 'فارغة';
	@override String get caseFocused => 'مركّزة';
	@override String get caseInvalid => 'غير صالحة';
	@override String get caseSubmitting => 'قيد الإرسال';
	@override String get caseFieldError => 'خطأ حقل';
	@override String get caseGlobalError => 'خطأ عام';
	@override String get caseSuccess => 'نجاح';
	@override String get casePartial => 'جزئية';
	@override String get casePastedComplete => 'لصق مكتمل';
	@override String get caseExpired => 'منتهية';
	@override String get caseResending => 'إعادة الإرسال';
	@override String get caseSaving => 'قيد الحفظ';
	@override String get caseSaved => 'محفوظة';
	@override String get caseDirty => 'تغييرات غير محفوظة';
	@override String get caseDiscardPrompt => 'مطالبة بالتجاهل';
	@override String get caseStartupFailure => 'فشل بدء التشغيل';
	@override String get caseUnknownRoute => 'مسار غير معروف';
	@override String get caseMalformedOtp => 'غرض تحقق غير صالح';
	@override String get caseDiagnostics => 'التشخيصات';
	@override String get caseDialog => 'مربع حوار';
	@override String get caseSheet => 'لوحة';
	@override String get caseToast => 'إشعار عابر';
	@override String get casePopover => 'نافذة منبثقة';
	@override String get caseTooltip => 'تلميح';
	@override String get caseKeyboardInset => 'نموذج مع إزاحة لوحة المفاتيح';
	@override String get screenSession => 'الجلسة';
	@override String get caseSessionLoggedOut => 'تم تسجيل الخروج';
	@override String get caseSessionLoggedIn => 'تم تسجيل الدخول';
	@override String get screenAnalytics => 'الاشتراك في التحليلات';
	@override String get screenBiometricLock => 'قفل القياس الحيوي';
	@override String get caseLocked => 'مقفل';
	@override String get caseNotFound => 'حالة المعرض المطلوبة غير مسجلة.';
}

// Path: pricing.plans
class _Translations$pricing$plans$ar extends Translations$pricing$plans$en {
	_Translations$pricing$plans$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basicName => 'أساسية';
	@override String get basicDescription => 'أساس مركز للمشاريع الشخصية.';
	@override String get basicBenefitOne => 'شاشات القالب الأساسية';
	@override String get basicBenefitTwo => 'إعدادات السمة واللغة';
	@override String get basicBenefitThree => 'سير عمل مجتمعي';
	@override String get proName => 'احترافية';
	@override String get proDescription => 'بنية أوسع للمنتجات والفرق النامية.';
	@override String get proBenefitOne => 'كل ما في الأساسية';
	@override String get proBenefitTwo => 'معرض كامل للتدفقات الثابتة';
	@override String get proBenefitThree => 'فحوص جودة موسعة';
	@override String get teamName => 'فريق';
	@override String get teamDescription => 'نقطة بداية مشتركة للتسليم المنسق.';
	@override String get teamBenefitOne => 'كل ما في الاحترافية';
	@override String get teamBenefitTwo => 'قواعد جاهزة للفريق';
	@override String get teamBenefitThree => 'سير إصدار متعدد المنصات';
}

// Path: settings.analytics
class _Translations$settings$analytics$ar extends Translations$settings$analytics$en {
	_Translations$settings$analytics$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get optInTitle => 'التحليلات';
	@override String get optInBody => 'ساعدنا في تحسين التطبيق عبر إرسال بيانات استخدام مجهولة الهوية. يمكنك إيقاف ذلك في أي وقت.';
	@override String get statusOn => 'مُفعّل';
	@override String get statusOff => 'غير مُفعّل';
}

// Path: auth.common
class _Translations$auth$common$ar extends Translations$auth$common$en {
	_Translations$auth$common$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get email => 'البريد الإلكتروني';
	@override String get password => 'كلمة المرور';
	@override String get confirmPassword => 'تأكيد كلمة المرور';
	@override String get displayName => 'الاسم المعروض';
	@override String get showPassword => 'إظهار كلمة المرور';
	@override String get hidePassword => 'إخفاء كلمة المرور';
	@override String get passwordRequirements => 'استخدم 8 أحرف على الأقل مع حرف لاتيني كبير ورقم.';
	@override String get returnToLogin => 'العودة إلى تسجيل الدخول';
}

// Path: auth.login
class _Translations$auth$login$ar extends Translations$auth$login$en {
	_Translations$auth$login$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مرحبًا بعودتك';
	@override String get body => 'استخدم النموذج الثابت لمراجعة التحقق والتركيز وسلوك التنقل.';
	@override String get rememberMe => 'تذكر بريدي الإلكتروني على هذا الجهاز';
	@override String get forgotPassword => 'هل نسيت كلمة المرور؟';
	@override String get register => 'إنشاء حساب';
	@override String get submit => 'تسجيل الدخول';
	@override String get submitting => 'جارٍ تسجيل الدخول';
	@override String get globalError => 'تعذر إكمال تسجيل الدخول الثابت. تم الاحتفاظ بالقيم.';
	@override String get success => 'اكتمل تسجيل الدخول الثابت.';
	@override String get lockedTitle => 'محاولات كثيرة';
	@override String get tooManyAttempts => 'محاولات فاشلة كثيرة. يرجى الانتظار.';
	@override String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا محاولات متبقية',
		one: 'محاولة واحدة متبقية',
		two: 'محاولتان متبقيتان',
		few: '${count} محاولات متبقية',
		many: '${count} محاولة متبقية',
		other: '${count} محاولة متبقية',
	);
	@override String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'أعد المحاولة الآن.',
		one: 'أعد المحاولة خلال ثانية واحدة.',
		two: 'أعد المحاولة خلال ثانيتين.',
		few: 'أعد المحاولة خلال ${seconds} ثوانٍ.',
		many: 'أعد المحاولة خلال ${seconds} ثانية.',
		other: 'أعد المحاولة خلال ${seconds} ثانية.',
	);
}

// Path: auth.register
class _Translations$auth$register$ar extends Translations$auth$register$en {
	_Translations$auth$register$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إنشاء حسابك';
	@override String get body => 'أدخل التفاصيل المستخدمة لعرض سلوك التسجيل والتأكيد.';
	@override String get acceptTerms => 'أوافق على معاينة الشروط والخصوصية.';
	@override String get terms => 'مراجعة الشروط';
	@override String get privacy => 'مراجعة الخصوصية';
	@override String get submit => 'إنشاء الحساب';
	@override String get submitting => 'جارٍ إنشاء الحساب';
	@override String get globalError => 'تعذر إكمال التسجيل. راجع الحقول المميزة وحاول مرة أخرى.';
	@override String get success => 'تم قبول تفاصيل التسجيل.';
	@override String get discardTitle => 'هل تريد تجاهل تفاصيل التسجيل؟';
	@override String get discardBody => 'سيتم مسح قيم التسجيل غير المحفوظة.';
	@override String get stay => 'متابعة التحرير';
	@override String get discard => 'تجاهل التفاصيل';
}

// Path: auth.forgotPassword
class _Translations$auth$forgotPassword$ar extends Translations$auth$forgotPassword$en {
	_Translations$auth$forgotPassword$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إعادة تعيين كلمة المرور';
	@override String get body => 'أدخل بريدًا إلكترونيًا. يبقى التأكيد محايدًا ولا يكشف عن وجود حساب.';
	@override String get submit => 'إرسال رمز التحقق';
	@override String get submitting => 'جارٍ إعداد التحقق';
	@override String get success => 'إذا كان العنوان قادرًا على استقبال إعادة التعيين، فسيكون رمز التحقق متاحًا.';
}

// Path: auth.otp
class _Translations$auth$otp$ar extends Translations$auth$otp$en {
	_Translations$auth$otp$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get registrationTitle => 'تحقق من التسجيل';
	@override String get registrationBody => 'أدخل الرمز المكون من ستة أرقام لإكمال تدفق التسجيل الثابت.';
	@override String get passwordResetTitle => 'تحقق من طلب إعادة التعيين';
	@override String get passwordResetBody => 'أدخل الرمز المكون من ستة أرقام قبل اختيار كلمة مرور جديدة.';
	@override String get code => 'رمز التحقق';
	@override String get submit => 'تحقق من الرمز';
	@override String get submitting => 'جارٍ التحقق من الرمز';
	@override String get resend => 'إعادة إرسال الرمز';
	@override String resendIn({required Object seconds}) => 'تتوفر إعادة الإرسال خلال ${seconds} ثانية';
	@override String get resending => 'جارٍ إعادة إرسال الرمز';
	@override String get invalid => 'رمز التحقق غير صالح.';
	@override String get expired => 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.';
	@override String get registrationSuccess => 'تم التحقق من التسجيل.';
	@override String get passwordResetSuccess => 'تم التحقق من طلب إعادة التعيين.';
	@override String get lockedTitle => 'محاولات كثيرة';
	@override String get tooManyAttempts => 'محاولات فاشلة كثيرة. يرجى الانتظار.';
	@override String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'لا محاولات متبقية',
		one: 'محاولة واحدة متبقية',
		two: 'محاولتان متبقيتان',
		few: '${count} محاولات متبقية',
		many: '${count} محاولة متبقية',
		other: '${count} محاولة متبقية',
	);
	@override String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n,
		zero: 'أعد المحاولة الآن.',
		one: 'أعد المحاولة خلال ثانية واحدة.',
		two: 'أعد المحاولة خلال ثانيتين.',
		few: 'أعد المحاولة خلال ${seconds} ثوانٍ.',
		many: 'أعد المحاولة خلال ${seconds} ثانية.',
		other: 'أعد المحاولة خلال ${seconds} ثانية.',
	);
}

// Path: auth.resetPassword
class _Translations$auth$resetPassword$ar extends Translations$auth$resetPassword$en {
	_Translations$auth$resetPassword$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'اختر كلمة مرور جديدة';
	@override String get body => 'استخدم كلمة مرور قوية وأدخلها بالطريقة نفسها مرتين.';
	@override String get newPassword => 'كلمة المرور الجديدة';
	@override String get submit => 'تحديث كلمة المرور';
	@override String get submitting => 'جارٍ تحديث كلمة المرور';
	@override String get globalError => 'تعذر إكمال تحديث كلمة المرور الثابت.';
	@override String get success => 'اكتملت معاينة تحديث كلمة المرور. عُد إلى تسجيل الدخول.';
}

// Path: profile.update
class _Translations$profile$update$ar extends Translations$profile$update$en {
	_Translations$profile$update$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'تحديث الملف الشخصي';
	@override String get body => 'حرر تفاصيل الحساب غير الحساسة. تبقى المسودات فقط أثناء بقاء هذه الصفحة مفتوحة.';
	@override String get avatar => 'عنصر نائب لصورة الملف الشخصي';
	@override String get changeAvatar => 'تغيير صورة الملف الشخصي';
	@override String get avatarUnavailable => 'اختيار الصور غير متصل ولم يتم طلب أي إذن.';
	@override String get displayName => 'الاسم المعروض';
	@override String get username => 'اسم المستخدم';
	@override String get email => 'البريد الإلكتروني';
	@override String get emailReadOnly => 'لا يمكن تغيير البريد الإلكتروني في هذه المرحلة الثابتة.';
	@override String get bio => 'نبذة';
	@override String bioCounter({required Object count, required Object maximum}) => '${count} من ${maximum} حرفًا';
	@override String get save => 'حفظ الملف الشخصي';
	@override String get saving => 'جارٍ حفظ الملف الشخصي';
	@override String get saved => 'تم حفظ تغييرات الملف الشخصي لهذه الجلسة.';
	@override String get globalError => 'تعذر إكمال حفظ الملف الشخصي الثابت. تم الاحتفاظ بالقيم.';
	@override String get discardTitle => 'هل تريد تجاهل تغييرات الملف الشخصي؟';
	@override String get discardBody => 'سيتم مسح تغييرات الملف الشخصي غير المحفوظة.';
	@override String get stay => 'متابعة التحرير';
	@override String get discard => 'تجاهل التغييرات';
}

// Path: security.biometric
class _Translations$security$biometric$ar extends Translations$security$biometric$en {
	_Translations$security$biometric$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get lockTitle => 'إلغاء القفل بالقياس الحيوي';
	@override String get lockBody => 'استخدم بصمتك أو وجهك لإلغاء قفل التطبيق.';
	@override String get unlock => 'إلغاء القفل';
	@override String get unlocking => 'جارٍ إلغاء القفل';
	@override String get unavailableTitle => 'إلغاء القفل بالقياس الحيوي غير متاح';
	@override String get unavailableBody => 'لا يتوفر إلغاء القفل بالقياس الحيوي على هذا الجهاز. استخدم بيانات اعتماد جهازك بدلًا من ذلك.';
	@override String get useFallback => 'استخدام بيانات الاعتماد';
}

// Path: announcements.fixtures
class _Translations$announcements$fixtures$ar extends Translations$announcements$fixtures$en {
	_Translations$announcements$fixtures$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$announcements$fixtures$welcome$ar welcome = _Translations$announcements$fixtures$welcome$ar._(_root);
	@override late final _Translations$announcements$fixtures$changelog$ar changelog = _Translations$announcements$fixtures$changelog$ar._(_root);
	@override late final _Translations$announcements$fixtures$deprecation$ar deprecation = _Translations$announcements$fixtures$deprecation$ar._(_root);
	@override late final _Translations$announcements$fixtures$outage$ar outage = _Translations$announcements$fixtures$outage$ar._(_root);
}

// Path: announcements.fixtures.welcome
class _Translations$announcements$fixtures$welcome$ar extends Translations$announcements$fixtures$welcome$en {
	_Translations$announcements$fixtures$welcome$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'أهلًا بك في نقطة الانطلاق';
	@override String get message => 'أساس متين لمنتجك القادم. أغلق هذا الإعلان لاستكشاف الواجهة.';
}

// Path: announcements.fixtures.changelog
class _Translations$announcements$fixtures$changelog$ar extends Translations$announcements$fixtures$changelog$en {
	_Translations$announcements$fixtures$changelog$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الجديد في هذا الإصدار';
	@override String get message => 'تبقي الإعلانات الجميع على اطلاع دون الحاجة إلى تحديث التطبيق.';
}

// Path: announcements.fixtures.deprecation
class _Translations$announcements$fixtures$deprecation$ar extends Translations$announcements$fixtures$deprecation$en {
	_Translations$announcements$fixtures$deprecation$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'يتوفر إصدار أحدث';
	@override String get message => 'سيُوقف دعم هذا الإصدار قريبًا. حدّث عندما يمكنك ذلك.';
}

// Path: announcements.fixtures.outage
class _Translations$announcements$fixtures$outage$ar extends Translations$announcements$fixtures$outage$en {
	_Translations$announcements$fixtures$outage$ar._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'انقطاع الخدمة';
	@override String get message => 'قد تفشل بعض الإجراءات أثناء معالجة اضطراب في الخدمة.';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'نقطة البداية',
			'common.back' => 'رجوع',
			'common.home' => 'الرئيسية',
			'common.retry' => 'إعادة المحاولة',
			'common.save' => 'حفظ',
			'common.cancel' => 'إلغاء',
			'common.close' => 'إغلاق',
			'common.continueAction' => 'متابعة',
			'common.skip' => 'تخطي',
			'common.reset' => 'إعادة تعيين',
			'common.done' => 'تم',
			'common.previous' => 'السابق',
			'common.next' => 'التالي',
			'common.optional' => 'اختياري',
			'common.loading' => 'جارٍ التحميل',
			'common.saving' => 'جارٍ الحفظ…',
			'common.notConnected' => 'هذا الإجراء غير متصل بعد.',
			'common.legalPlaceholderTitle' => 'معاينة المعلومات',
			'common.legalPlaceholderBody' => 'يعرض هذا القالب محتوى تجريبيًا واضحًا إلى أن تتم الموافقة على النص القانوني الخاص بالمنتج.',
			'connectivity.online' => 'متصل',
			'connectivity.offline' => 'أنت غير متصل. قد لا تتوفر بعض الإجراءات.',
			'connectivity.backOnline' => 'عاد الاتصال بالإنترنت.',
			'connectivity.limited' => 'اتصال محدود. قد تكون بعض الإجراءات بطيئة أو غير متوفرة.',
			'navigation.home' => 'الرئيسية',
			'navigation.pricing' => 'الأسعار',
			'navigation.settings' => 'الإعدادات',
			'onboarding.brand' => 'نقطة بداية مدروسة',
			'onboarding.progress' => ({required Object current, required Object total}) => 'الخطوة ${current} من ${total}',
			'onboarding.firstTitle' => 'ابدأ من أساس متين',
			'onboarding.firstBody' => 'ابدأ بإعدادات صريحة وفحوص جودة صارمة وواجهة جاهزة للنمو.',
			'onboarding.middleTitle' => 'مصمم لكل شاشة',
			'onboarding.middleBody' => 'تتكيف صفحات الإنتاج نفسها من شاشات اللمس المدمجة إلى سير عمل سطح المكتب الدقيق.',
			'onboarding.finalTitle' => 'تفضيلاتك ملكك',
			'onboarding.finalBody' => 'اختر المظهر واللغة وحجم النص من دون إخفاء إعدادات إمكانية الوصول في النظام.',
			'onboarding.openPaywall' => 'مراجعة الخطط',
			'pricing.title' => 'خطط تناسب طريقة عملك',
			'pricing.body' => 'قارن مجموعة صغيرة وواضحة من الخطط التجريبية. الشراء غير متصل عمدًا في هذا القالب.',
			'pricing.monthly' => 'شهري',
			'pricing.annual' => 'سنوي',
			'pricing.billedMonthly' => 'الفوترة كل شهر',
			'pricing.billedAnnually' => 'الفوترة مرة كل سنة',
			'pricing.periodMonth' => 'شهريًا',
			'pricing.periodYear' => 'سنويًا',
			'pricing.recommended' => 'موصى بها',
			'pricing.current' => 'الخطة الحالية',
			'pricing.choosePlan' => ({required Object plan}) => 'معاينة ${plan}',
			'pricing.unavailable' => 'غير متاحة',
			'pricing.unavailableReason' => 'اختيار الخطة غير متاح في هذه المعاينة. لا يزال بإمكانك مراجعة كل الخطط.',
			'pricing.comparisonTitle' => 'مقارنة الخطط',
			'pricing.faqTitle' => 'أسئلة شائعة',
			'pricing.faqQuestion' => 'هل يمكنني تغيير الخطة لاحقًا؟',
			'pricing.faqAnswer' => 'نعم. هذه التجربة الثابتة تعرض التخطيط فقط، ولا تنشئ أي اشتراك.',
			'pricing.restore' => 'استعادة المشتريات',
			'pricing.restoreUnavailable' => 'استعادة المشتريات غير متصلة في هذا القالب.',
			'pricing.terms' => 'الشروط',
			'pricing.privacy' => 'الخصوصية',
			'pricing.staticPurchaseNotice' => 'لن يتم إجراء دفع أو شراء.',
			'pricing.staticSuccess' => 'اكتملت معاينة اختيار الخطة. لم يتم أي شراء.',
			'pricing.paywallTitle' => 'واصل البناء بمساحة أكبر',
			'pricing.paywallBody' => 'راجع المزايا واختر دورة الفوترة أو تخطَّ وتابع استكشاف القالب.',
			'pricing.paywallContinue' => 'معاينة الخطة المحددة والمتابعة',
			'pricing.benefitAdaptive' => 'تخطيطات متكيفة للهاتف وسطح المكتب',
			'pricing.benefitLocalized' => 'الإنجليزية والعربية والصينية المبسطة',
			'pricing.benefitAccessible' => 'تحجيم وسياسات إدخال تراعي إمكانية الوصول',
			'pricing.plans.basicName' => 'أساسية',
			'pricing.plans.basicDescription' => 'أساس مركز للمشاريع الشخصية.',
			'pricing.plans.basicBenefitOne' => 'شاشات القالب الأساسية',
			'pricing.plans.basicBenefitTwo' => 'إعدادات السمة واللغة',
			'pricing.plans.basicBenefitThree' => 'سير عمل مجتمعي',
			'pricing.plans.proName' => 'احترافية',
			'pricing.plans.proDescription' => 'بنية أوسع للمنتجات والفرق النامية.',
			'pricing.plans.proBenefitOne' => 'كل ما في الأساسية',
			'pricing.plans.proBenefitTwo' => 'معرض كامل للتدفقات الثابتة',
			'pricing.plans.proBenefitThree' => 'فحوص جودة موسعة',
			'pricing.plans.teamName' => 'فريق',
			'pricing.plans.teamDescription' => 'نقطة بداية مشتركة للتسليم المنسق.',
			'pricing.plans.teamBenefitOne' => 'كل ما في الاحترافية',
			'pricing.plans.teamBenefitTwo' => 'قواعد جاهزة للفريق',
			'pricing.plans.teamBenefitThree' => 'سير إصدار متعدد المنصات',
			'home.title' => 'بداية متينة لتطبيقك',
			'home.body' => 'تعمل بنية التطبيق الآن بإعدادات صريحة وتنقل متكيف وعناصر مترجمة.',
			'home.greeting' => ({required Object name}) => 'مرحبًا، ${name}',
			'home.summary' => 'القالب مضبوط وجاهز لإضافة القدرة الحقيقية التالية للمنتج.',
			'home.quickActions' => 'إجراءات سريعة',
			'home.editProfile' => 'تحديث الملف الشخصي',
			'home.openSettings' => 'فتح الإعدادات',
			'home.openPricing' => 'عرض الأسعار',
			'home.openLogin' => 'تجربة تسجيل الدخول',
			'home.statusTitle' => 'حالة الأساس',
			'home.statusReadyTitle' => 'جاهز للتوسعة',
			'home.statusReadyBody' => 'تم ربط الإعدادات والتوجيه والترجمة والتخطيط المتكيف.',
			'home.statusAdaptiveTitle' => 'متكيف افتراضيًا',
			'home.statusAdaptiveBody' => 'غيّر حجم النافذة من دون إعادة تعيين المسار أو حالة الميزة.',
			'home.statusLocalizedTitle' => 'الترجمة من جذر التطبيق',
			'home.statusLocalizedBody' => 'تستخدم نصوص التطبيق وForUI اللغة والاتجاه المحددين معًا.',
			'home.recentTitle' => 'النشاط الأخير',
			'home.recentEmptyTitle' => 'لا يوجد نشاط بعد',
			'home.recentEmptyBody' => 'يمكن أن يحل نشاط المنتج الحقيقي محل هذه الحالة الفارغة الواضحة عند اختيار مجال المنتج.',
			'settings.title' => 'الإعدادات',
			'settings.appearance' => 'المظهر',
			'settings.language' => 'اللغة',
			'settings.account' => 'الحساب',
			'settings.subscription' => 'الاشتراك',
			'settings.privacyAbout' => 'الخصوصية وحول التطبيق',
			'settings.themeMode' => 'نمط السمة',
			'settings.system' => 'النظام',
			'settings.light' => 'فاتح',
			'settings.dark' => 'داكن',
			'settings.accent' => 'اللون المميز',
			'settings.accentNeutral' => 'محايد',
			'settings.accentGreen' => 'أخضر',
			'settings.accentBlue' => 'أزرق',
			'settings.accentAmber' => 'كهرماني',
			'settings.accentRose' => 'وردي',
			'settings.accentViolet' => 'بنفسجي',
			'settings.fontScale' => 'حجم النص',
			'settings.motionPreview' => 'معاينة الحركة',
			'settings.locale' => 'لغة التطبيق',
			'settings.languageSystem' => 'استخدام لغة الجهاز',
			'settings.languageEnglish' => 'الإنجليزية',
			'settings.languageArabic' => 'العربية',
			'settings.languageChinese' => 'الصينية المبسطة',
			'settings.saved' => 'تم حفظ الإعدادات',
			'settings.accountBody' => 'راجع تدفقات الملف الشخصي والمصادقة الثابتة.',
			'settings.openProfile' => 'تحديث الملف الشخصي',
			'settings.openLogin' => 'فتح تسجيل الدخول',
			'settings.subscriptionBody' => 'قارن الخطط من دون بدء عملية شراء.',
			'settings.openPricing' => 'عرض الأسعار',
			'settings.privacyBody' => 'يخزن هذا القالب تفضيلات المظهر واللغة فقط خلال المرحلة الثابتة.',
			'settings.aboutBuild' => 'معلومات الإصدار',
			'settings.terms' => 'معاينة الشروط',
			'settings.privacy' => 'معاينة الخصوصية',
			'settings.enableBiometric' => 'إلغاء القفل بالقياس الحيوي',
			'settings.analytics.optInTitle' => 'التحليلات',
			'settings.analytics.optInBody' => 'ساعدنا في تحسين التطبيق عبر إرسال بيانات استخدام مجهولة الهوية. يمكنك إيقاف ذلك في أي وقت.',
			'settings.analytics.statusOn' => 'مُفعّل',
			'settings.analytics.statusOff' => 'غير مُفعّل',
			'auth.common.email' => 'البريد الإلكتروني',
			'auth.common.password' => 'كلمة المرور',
			'auth.common.confirmPassword' => 'تأكيد كلمة المرور',
			'auth.common.displayName' => 'الاسم المعروض',
			'auth.common.showPassword' => 'إظهار كلمة المرور',
			'auth.common.hidePassword' => 'إخفاء كلمة المرور',
			'auth.common.passwordRequirements' => 'استخدم 8 أحرف على الأقل مع حرف لاتيني كبير ورقم.',
			'auth.common.returnToLogin' => 'العودة إلى تسجيل الدخول',
			'auth.login.title' => 'مرحبًا بعودتك',
			'auth.login.body' => 'استخدم النموذج الثابت لمراجعة التحقق والتركيز وسلوك التنقل.',
			'auth.login.rememberMe' => 'تذكر بريدي الإلكتروني على هذا الجهاز',
			'auth.login.forgotPassword' => 'هل نسيت كلمة المرور؟',
			'auth.login.register' => 'إنشاء حساب',
			'auth.login.submit' => 'تسجيل الدخول',
			'auth.login.submitting' => 'جارٍ تسجيل الدخول',
			'auth.login.globalError' => 'تعذر إكمال تسجيل الدخول الثابت. تم الاحتفاظ بالقيم.',
			'auth.login.success' => 'اكتمل تسجيل الدخول الثابت.',
			'auth.login.lockedTitle' => 'محاولات كثيرة',
			'auth.login.tooManyAttempts' => 'محاولات فاشلة كثيرة. يرجى الانتظار.',
			'auth.login.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا محاولات متبقية', one: 'محاولة واحدة متبقية', two: 'محاولتان متبقيتان', few: '${count} محاولات متبقية', many: '${count} محاولة متبقية', other: '${count} محاولة متبقية', ), 
			'auth.login.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'أعد المحاولة الآن.', one: 'أعد المحاولة خلال ثانية واحدة.', two: 'أعد المحاولة خلال ثانيتين.', few: 'أعد المحاولة خلال ${seconds} ثوانٍ.', many: 'أعد المحاولة خلال ${seconds} ثانية.', other: 'أعد المحاولة خلال ${seconds} ثانية.', ), 
			'auth.register.title' => 'إنشاء حسابك',
			'auth.register.body' => 'أدخل التفاصيل المستخدمة لعرض سلوك التسجيل والتأكيد.',
			'auth.register.acceptTerms' => 'أوافق على معاينة الشروط والخصوصية.',
			'auth.register.terms' => 'مراجعة الشروط',
			'auth.register.privacy' => 'مراجعة الخصوصية',
			'auth.register.submit' => 'إنشاء الحساب',
			'auth.register.submitting' => 'جارٍ إنشاء الحساب',
			'auth.register.globalError' => 'تعذر إكمال التسجيل. راجع الحقول المميزة وحاول مرة أخرى.',
			'auth.register.success' => 'تم قبول تفاصيل التسجيل.',
			'auth.register.discardTitle' => 'هل تريد تجاهل تفاصيل التسجيل؟',
			'auth.register.discardBody' => 'سيتم مسح قيم التسجيل غير المحفوظة.',
			'auth.register.stay' => 'متابعة التحرير',
			'auth.register.discard' => 'تجاهل التفاصيل',
			'auth.forgotPassword.title' => 'إعادة تعيين كلمة المرور',
			'auth.forgotPassword.body' => 'أدخل بريدًا إلكترونيًا. يبقى التأكيد محايدًا ولا يكشف عن وجود حساب.',
			'auth.forgotPassword.submit' => 'إرسال رمز التحقق',
			'auth.forgotPassword.submitting' => 'جارٍ إعداد التحقق',
			'auth.forgotPassword.success' => 'إذا كان العنوان قادرًا على استقبال إعادة التعيين، فسيكون رمز التحقق متاحًا.',
			'auth.otp.registrationTitle' => 'تحقق من التسجيل',
			'auth.otp.registrationBody' => 'أدخل الرمز المكون من ستة أرقام لإكمال تدفق التسجيل الثابت.',
			'auth.otp.passwordResetTitle' => 'تحقق من طلب إعادة التعيين',
			'auth.otp.passwordResetBody' => 'أدخل الرمز المكون من ستة أرقام قبل اختيار كلمة مرور جديدة.',
			'auth.otp.code' => 'رمز التحقق',
			'auth.otp.submit' => 'تحقق من الرمز',
			'auth.otp.submitting' => 'جارٍ التحقق من الرمز',
			'auth.otp.resend' => 'إعادة إرسال الرمز',
			'auth.otp.resendIn' => ({required Object seconds}) => 'تتوفر إعادة الإرسال خلال ${seconds} ثانية',
			'auth.otp.resending' => 'جارٍ إعادة إرسال الرمز',
			'auth.otp.invalid' => 'رمز التحقق غير صالح.',
			'auth.otp.expired' => 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.',
			'auth.otp.registrationSuccess' => 'تم التحقق من التسجيل.',
			'auth.otp.passwordResetSuccess' => 'تم التحقق من طلب إعادة التعيين.',
			'auth.otp.lockedTitle' => 'محاولات كثيرة',
			'auth.otp.tooManyAttempts' => 'محاولات فاشلة كثيرة. يرجى الانتظار.',
			'auth.otp.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'لا محاولات متبقية', one: 'محاولة واحدة متبقية', two: 'محاولتان متبقيتان', few: '${count} محاولات متبقية', many: '${count} محاولة متبقية', other: '${count} محاولة متبقية', ), 
			'auth.otp.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(n, zero: 'أعد المحاولة الآن.', one: 'أعد المحاولة خلال ثانية واحدة.', two: 'أعد المحاولة خلال ثانيتين.', few: 'أعد المحاولة خلال ${seconds} ثوانٍ.', many: 'أعد المحاولة خلال ${seconds} ثانية.', other: 'أعد المحاولة خلال ${seconds} ثانية.', ), 
			'auth.resetPassword.title' => 'اختر كلمة مرور جديدة',
			'auth.resetPassword.body' => 'استخدم كلمة مرور قوية وأدخلها بالطريقة نفسها مرتين.',
			'auth.resetPassword.newPassword' => 'كلمة المرور الجديدة',
			'auth.resetPassword.submit' => 'تحديث كلمة المرور',
			'auth.resetPassword.submitting' => 'جارٍ تحديث كلمة المرور',
			'auth.resetPassword.globalError' => 'تعذر إكمال تحديث كلمة المرور الثابت.',
			'auth.resetPassword.success' => 'اكتملت معاينة تحديث كلمة المرور. عُد إلى تسجيل الدخول.',
			'profile.update.title' => 'تحديث الملف الشخصي',
			'profile.update.body' => 'حرر تفاصيل الحساب غير الحساسة. تبقى المسودات فقط أثناء بقاء هذه الصفحة مفتوحة.',
			'profile.update.avatar' => 'عنصر نائب لصورة الملف الشخصي',
			'profile.update.changeAvatar' => 'تغيير صورة الملف الشخصي',
			'profile.update.avatarUnavailable' => 'اختيار الصور غير متصل ولم يتم طلب أي إذن.',
			'profile.update.displayName' => 'الاسم المعروض',
			'profile.update.username' => 'اسم المستخدم',
			'profile.update.email' => 'البريد الإلكتروني',
			'profile.update.emailReadOnly' => 'لا يمكن تغيير البريد الإلكتروني في هذه المرحلة الثابتة.',
			'profile.update.bio' => 'نبذة',
			'profile.update.bioCounter' => ({required Object count, required Object maximum}) => '${count} من ${maximum} حرفًا',
			'profile.update.save' => 'حفظ الملف الشخصي',
			'profile.update.saving' => 'جارٍ حفظ الملف الشخصي',
			'profile.update.saved' => 'تم حفظ تغييرات الملف الشخصي لهذه الجلسة.',
			'profile.update.globalError' => 'تعذر إكمال حفظ الملف الشخصي الثابت. تم الاحتفاظ بالقيم.',
			'profile.update.discardTitle' => 'هل تريد تجاهل تغييرات الملف الشخصي؟',
			'profile.update.discardBody' => 'سيتم مسح تغييرات الملف الشخصي غير المحفوظة.',
			'profile.update.stay' => 'متابعة التحرير',
			'profile.update.discard' => 'تجاهل التغييرات',
			'security.biometric.lockTitle' => 'إلغاء القفل بالقياس الحيوي',
			'security.biometric.lockBody' => 'استخدم بصمتك أو وجهك لإلغاء قفل التطبيق.',
			'security.biometric.unlock' => 'إلغاء القفل',
			'security.biometric.unlocking' => 'جارٍ إلغاء القفل',
			'security.biometric.unavailableTitle' => 'إلغاء القفل بالقياس الحيوي غير متاح',
			'security.biometric.unavailableBody' => 'لا يتوفر إلغاء القفل بالقياس الحيوي على هذا الجهاز. استخدم بيانات اعتماد جهازك بدلًا من ذلك.',
			'security.biometric.useFallback' => 'استخدام بيانات الاعتماد',
			'forceUpdate.title' => 'يلزم تحديث التطبيق',
			'forceUpdate.body' => 'لم يعد هذا الإصدار مدعومًا. حدّث إلى أحدث إصدار للمتابعة.',
			'forceUpdate.updateNow' => 'تحديث الآن',
			'softUpdate.title' => 'يتوفر إصدار أحدث',
			'softUpdate.body' => 'حدّث إلى أحدث إصدار للحصول على أحدث التحسينات والإصلاحات.',
			'softUpdate.update' => 'تحديث',
			'softUpdate.later' => 'لاحقًا',
			'session.expired' => 'انتهت جلستك. يُرجى تسجيل الدخول من جديد.',
			'session.signedOut' => 'تم تسجيل خروجك.',
			'session.signedInPreview' => ({required Object userId}) => 'تم تسجيل دخولك بصفتك ${userId}',
			'session.unavailable' => 'تسجيل الدخول غير متصل بعد.',
			'splash.loading' => 'جارٍ التشغيل',
			'splash.tagline' => 'نقطة انطلاق مدروسة',
			'splash.error' => 'تعذّر إكمال التشغيل.',
			'states.emptyTitle' => 'لا يوجد شيء هنا بعد',
			'states.emptyBody' => 'عند توفّر المحتوى، سيظهر هنا.',
			'states.errorTitle' => 'تعذّر تحميل هذا',
			'states.errorBody' => 'حدث خطأ أثناء التحميل. حاول مرة أخرى.',
			'states.loadingTitle' => 'جارٍ التحميل…',
			'announcements.dismiss' => 'إغلاق',
			'announcements.actionLearnMore' => 'اعرف المزيد',
			'announcements.dismissFailed' => 'تعذّر إغلاق الإعلان.',
			'announcements.severityInfo' => 'معلومة',
			'announcements.severitySuccess' => 'نجاح',
			'announcements.severityWarning' => 'تحذير',
			'announcements.severityCritical' => 'حرج',
			'announcements.fixtures.welcome.title' => 'أهلًا بك في نقطة الانطلاق',
			'announcements.fixtures.welcome.message' => 'أساس متين لمنتجك القادم. أغلق هذا الإعلان لاستكشاف الواجهة.',
			'announcements.fixtures.changelog.title' => 'الجديد في هذا الإصدار',
			'announcements.fixtures.changelog.message' => 'تبقي الإعلانات الجميع على اطلاع دون الحاجة إلى تحديث التطبيق.',
			'announcements.fixtures.deprecation.title' => 'يتوفر إصدار أحدث',
			'announcements.fixtures.deprecation.message' => 'سيُوقف دعم هذا الإصدار قريبًا. حدّث عندما يمكنك ذلك.',
			'announcements.fixtures.outage.title' => 'انقطاع الخدمة',
			'announcements.fixtures.outage.message' => 'قد تفشل بعض الإجراءات أثناء معالجة اضطراب في الخدمة.',
			'validation.required' => ({required Object field}) => 'حقل ${field} مطلوب.',
			'validation.email' => 'أدخل بريدًا إلكترونيًا صالحًا.',
			'validation.passwordWeak' => 'استخدم 8 أحرف على الأقل مع حرف لاتيني كبير ورقم.',
			'validation.passwordMismatch' => 'كلمتا المرور غير متطابقتين.',
			'validation.acceptTerms' => 'وافق على معاينة الشروط والخصوصية للمتابعة.',
			'validation.otpDigits' => 'أدخل الأرقام الستة كاملة.',
			'validation.username' => 'استخدم من 3 إلى 24 حرفًا أو رقمًا أو نقطة أو شرطة سفلية.',
			'validation.bioTooLong' => ({required Object maximum}) => 'اجعل النبذة في حدود ${maximum} حرفًا.',
			'routeError.title' => 'تعذر فتح هذه الصفحة',
			'routeError.body' => 'العنوان غير معروف أو غير مكتمل. يمكنك العودة إلى صفحة آمنة.',
			'routeError.path' => ({required Object path}) => 'العنوان المطلوب: ${path}',
			'routeError.invalidOtpPurpose' => 'يحتاج عنوان التحقق إلى غرض صالح للتسجيل أو إعادة تعيين كلمة المرور.',
			'startupFailure.title' => 'تعذر تشغيل التطبيق',
			'startupFailure.body' => 'أغلق التطبيق وأعد تشغيله. إذا استمرت المشكلة، شارك معرّف التشخيص مع الدعم.',
			'startupFailure.diagnosticId' => ({required Object id}) => 'معرّف التشخيص: ${id}',
			'diagnostics.title' => 'تشخيصات التطوير',
			'diagnostics.environment' => 'البيئة',
			'diagnostics.build' => 'الإصدار',
			'diagnostics.layout' => 'فئة التخطيط',
			'diagnostics.interaction' => 'سياسة التفاعل',
			'diagnostics.lifecycle' => 'دورة حياة التطبيق',
			'diagnostics.locale' => 'اللغة',
			'diagnostics.capabilities' => 'إمكانات المنصة',
			'diagnostics.secureStorage' => 'التخزين الآمن',
			'diagnostics.crashReporting' => 'الإبلاغ عن الأعطال',
			'diagnostics.crashReportingNone' => 'غير مُهيَّأ',
			'diagnostics.analytics' => 'التحليلات',
			'diagnostics.analyticsNone' => 'غير مُهيّأ',
			'diagnostics.featureFlags' => 'ميزات تجريبية',
			'diagnostics.redactedNotice' => 'لا تتضمن التشخيصات بيانات الاعتماد أو محتوى المستخدم.',
			'devGallery.title' => 'معرض شاشات الإنتاج',
			'devGallery.search' => 'البحث في الحالات',
			'devGallery.screen' => 'الشاشة',
			'devGallery.galleryCase' => 'حالة المعرض',
			'devGallery.preview' => 'المعاينة',
			'devGallery.viewport' => 'مساحة العرض',
			'devGallery.locale' => 'اللغة',
			'devGallery.theme' => 'السمة',
			'devGallery.accent' => 'لون التمييز',
			'devGallery.textScale' => 'تحجيم النص',
			'devGallery.systemTextScale' => 'تحجيم نص النظام',
			'devGallery.interaction' => 'سياسة التفاعل',
			'devGallery.motion' => 'الحركة',
			'devGallery.highContrast' => 'تباين عالٍ',
			'devGallery.boldText' => 'نص عريض',
			'devGallery.safeArea' => 'حشو المنطقة الآمنة',
			'devGallery.keyboardInsets' => 'إزاحة لوحة المفاتيح',
			'devGallery.displayFeature' => 'ميزة العرض',
			'devGallery.light' => 'فاتحة',
			'devGallery.dark' => 'داكنة',
			'devGallery.enabled' => 'مفعّل',
			'devGallery.disabled' => 'معطّل',
			'devGallery.normal' => 'عادي',
			'devGallery.maximum' => 'أقصى تحجيم غير خطي',
			'devGallery.touch' => 'لمس',
			'devGallery.precision' => 'مؤشر دقيق',
			'devGallery.hybrid' => 'إدخال هجين',
			'devGallery.none' => 'بلا',
			'devGallery.fold' => 'طي رأسي',
			'devGallery.resetControls' => 'إعادة ضبط عناصر المعاينة',
			'devGallery.viewportCompactPhone' => 'هاتف مدمج',
			'devGallery.viewportShortPhone' => 'هاتف أفقي قصير',
			'devGallery.viewportBelowMedium' => 'قبل حد التخطيط المتوسط',
			'devGallery.viewportAtMedium' => 'عند حد التخطيط المتوسط',
			'devGallery.viewportMedium' => 'نافذة متوسطة',
			'devGallery.viewportBelowExpanded' => 'قبل حد التخطيط الموسع',
			'devGallery.viewportAtExpanded' => 'عند حد التخطيط الموسع',
			'devGallery.viewportDesktop' => 'سطح المكتب',
			'devGallery.viewportNarrowDesktop' => 'سطح مكتب ضيق بعد تغيير الحجم',
			'devGallery.screenOnboarding' => 'التعريف',
			'devGallery.screenPaywall' => 'عرض خطط التعريف',
			'devGallery.screenHome' => 'الرئيسية',
			'devGallery.screenLogin' => 'تسجيل الدخول',
			'devGallery.screenRegister' => 'إنشاء حساب',
			'devGallery.screenForgotPassword' => 'نسيت كلمة المرور',
			'devGallery.screenOtpRegistration' => 'التحقق من التسجيل',
			'devGallery.screenOtpPasswordReset' => 'التحقق من إعادة التعيين',
			'devGallery.screenResetPassword' => 'إعادة تعيين كلمة المرور',
			'devGallery.screenProfile' => 'تحديث الملف الشخصي',
			'devGallery.screenPricing' => 'الأسعار',
			'devGallery.screenSettings' => 'الإعدادات',
			'devGallery.screenConnectivity' => 'شريط حالة الاتصال',
			'devGallery.screenForceUpdate' => 'تحديث إلزامي',
			'devGallery.screenSoftUpdate' => 'تحديث اختياري',
			'devGallery.screenBusy' => 'مؤشرات الانشغال',
			'devGallery.screenSystem' => 'واجهات النظام',
			'devGallery.screenOverlays' => 'الطبقات العلوية',
			'devGallery.screenSplash' => 'شاشة البداية داخل التطبيق',
			'devGallery.screenStateViews' => 'حالات العرض',
			'devGallery.screenFormScaffolding' => 'هيكل النموذج',
			'devGallery.screenAnnouncements' => 'شريط الإعلانات',
			'devGallery.caseSplashLoading' => 'جارٍ التشغيل',
			'devGallery.caseSplashReady' => 'جاهز',
			'devGallery.caseSplashError' => 'خطأ في التشغيل',
			'devGallery.caseStateEmpty' => 'فارغة',
			'devGallery.caseStateError' => 'خطأ',
			'devGallery.caseStateLoading' => 'جارٍ التحميل',
			'devGallery.caseFormScaffoldDisabled' => 'إرسال معطّل',
			'devGallery.caseFormScaffoldEnabled' => 'إرسال مفعّل',
			'devGallery.caseFormScaffoldSubmitting' => 'جارٍ الإرسال',
			'devGallery.caseAnnouncementsInfo' => 'معلومة',
			'devGallery.caseAnnouncementsSuccess' => 'نجاح',
			'devGallery.caseAnnouncementsWarning' => 'تحذير',
			'devGallery.caseAnnouncementsCritical' => 'حرج',
			'devGallery.caseDefault' => 'افتراضية',
			'devGallery.caseHardBlock' => 'حظر إلزامي',
			'devGallery.caseSoftUpdate' => 'تحديث اختياري',
			'devGallery.caseBusyIndeterminate' => 'غير محدد',
			'devGallery.caseBusyDeterminate' => 'محدد',
			'devGallery.caseBusyOverlay' => 'طبقة مشروطة',
			'devGallery.caseExpandedCopy' => 'نص موسّع',
			'devGallery.caseFirst' => 'الأولى',
			'devGallery.caseMiddle' => 'الوسطى',
			'devGallery.caseFinal' => 'الأخيرة',
			'devGallery.caseMonthly' => 'شهرية',
			'devGallery.caseAnnual' => 'سنوية',
			'devGallery.caseRecommended' => 'موصى بها',
			'devGallery.caseUnavailable' => 'غير متاحة',
			'devGallery.caseEmpty' => 'فارغة',
			'devGallery.caseFocused' => 'مركّزة',
			'devGallery.caseInvalid' => 'غير صالحة',
			'devGallery.caseSubmitting' => 'قيد الإرسال',
			'devGallery.caseFieldError' => 'خطأ حقل',
			'devGallery.caseGlobalError' => 'خطأ عام',
			'devGallery.caseSuccess' => 'نجاح',
			'devGallery.casePartial' => 'جزئية',
			'devGallery.casePastedComplete' => 'لصق مكتمل',
			'devGallery.caseExpired' => 'منتهية',
			'devGallery.caseResending' => 'إعادة الإرسال',
			'devGallery.caseSaving' => 'قيد الحفظ',
			'devGallery.caseSaved' => 'محفوظة',
			'devGallery.caseDirty' => 'تغييرات غير محفوظة',
			'devGallery.caseDiscardPrompt' => 'مطالبة بالتجاهل',
			'devGallery.caseStartupFailure' => 'فشل بدء التشغيل',
			'devGallery.caseUnknownRoute' => 'مسار غير معروف',
			'devGallery.caseMalformedOtp' => 'غرض تحقق غير صالح',
			'devGallery.caseDiagnostics' => 'التشخيصات',
			'devGallery.caseDialog' => 'مربع حوار',
			'devGallery.caseSheet' => 'لوحة',
			'devGallery.caseToast' => 'إشعار عابر',
			'devGallery.casePopover' => 'نافذة منبثقة',
			'devGallery.caseTooltip' => 'تلميح',
			'devGallery.caseKeyboardInset' => 'نموذج مع إزاحة لوحة المفاتيح',
			'devGallery.screenSession' => 'الجلسة',
			'devGallery.caseSessionLoggedOut' => 'تم تسجيل الخروج',
			'devGallery.caseSessionLoggedIn' => 'تم تسجيل الدخول',
			'devGallery.screenAnalytics' => 'الاشتراك في التحليلات',
			'devGallery.screenBiometricLock' => 'قفل القياس الحيوي',
			'devGallery.caseLocked' => 'مقفل',
			'devGallery.caseNotFound' => 'حالة المعرض المطلوبة غير مسجلة.',
			_ => null,
		};
	}
}
