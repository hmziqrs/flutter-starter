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
class TranslationsZhHans extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhHans({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhHans,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh-Hans>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZhHans _root = this; // ignore: unused_field

	@override 
	TranslationsZhHans $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhHans(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$zh_Hans app = _Translations$app$zh_Hans._(_root);
	@override late final _Translations$common$zh_Hans common = _Translations$common$zh_Hans._(_root);
	@override late final _Translations$connectivity$zh_Hans connectivity = _Translations$connectivity$zh_Hans._(_root);
	@override late final _Translations$navigation$zh_Hans navigation = _Translations$navigation$zh_Hans._(_root);
	@override late final _Translations$onboarding$zh_Hans onboarding = _Translations$onboarding$zh_Hans._(_root);
	@override late final _Translations$pricing$zh_Hans pricing = _Translations$pricing$zh_Hans._(_root);
	@override late final _Translations$home$zh_Hans home = _Translations$home$zh_Hans._(_root);
	@override late final _Translations$settings$zh_Hans settings = _Translations$settings$zh_Hans._(_root);
	@override late final _Translations$auth$zh_Hans auth = _Translations$auth$zh_Hans._(_root);
	@override late final _Translations$profile$zh_Hans profile = _Translations$profile$zh_Hans._(_root);
	@override late final _Translations$security$zh_Hans security = _Translations$security$zh_Hans._(_root);
	@override late final _Translations$forceUpdate$zh_Hans forceUpdate = _Translations$forceUpdate$zh_Hans._(_root);
	@override late final _Translations$softUpdate$zh_Hans softUpdate = _Translations$softUpdate$zh_Hans._(_root);
	@override late final _Translations$session$zh_Hans session = _Translations$session$zh_Hans._(_root);
	@override late final _Translations$splash$zh_Hans splash = _Translations$splash$zh_Hans._(_root);
	@override late final _Translations$states$zh_Hans states = _Translations$states$zh_Hans._(_root);
	@override late final _Translations$announcements$zh_Hans announcements = _Translations$announcements$zh_Hans._(_root);
	@override late final _Translations$validation$zh_Hans validation = _Translations$validation$zh_Hans._(_root);
	@override late final _Translations$routeError$zh_Hans routeError = _Translations$routeError$zh_Hans._(_root);
	@override late final _Translations$startupFailure$zh_Hans startupFailure = _Translations$startupFailure$zh_Hans._(_root);
	@override late final _Translations$diagnostics$zh_Hans diagnostics = _Translations$diagnostics$zh_Hans._(_root);
	@override late final _Translations$devGallery$zh_Hans devGallery = _Translations$devGallery$zh_Hans._(_root);
	@override late final _Translations$notifications$zh_Hans notifications = _Translations$notifications$zh_Hans._(_root);
	@override late final _Translations$permission$zh_Hans permission = _Translations$permission$zh_Hans._(_root);
	@override late final _Translations$share$zh_Hans share = _Translations$share$zh_Hans._(_root);
	@override late final _Translations$update$zh_Hans update = _Translations$update$zh_Hans._(_root);
	@override late final _Translations$search$zh_Hans search = _Translations$search$zh_Hans._(_root);
	@override late final _Translations$feedback$zh_Hans feedback = _Translations$feedback$zh_Hans._(_root);
}

// Path: app
class _Translations$app$zh_Hans extends Translations$app$en {
	_Translations$app$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get name => '起点';
}

// Path: common
class _Translations$common$zh_Hans extends Translations$common$en {
	_Translations$common$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get back => '返回';
	@override String get home => '主页';
	@override String get retry => '重试';
	@override String get save => '保存';
	@override String get cancel => '取消';
	@override String get close => '关闭';
	@override String get continueAction => '继续';
	@override String get skip => '跳过';
	@override String get reset => '重置';
	@override String get done => '完成';
	@override String get previous => '上一步';
	@override String get next => '下一步';
	@override String get optional => '可选';
	@override String get loading => '正在加载';
	@override String get saving => '正在保存…';
	@override String get notConnected => '此操作尚未连接。';
	@override String get legalPlaceholderTitle => '信息预览';
	@override String get legalPlaceholderBody => '在产品专属法律文本获批前，此模板会显示明确且可复现的占位内容。';
	@override String get confirm => '确认';
	@override String get success => '成功';
	@override String get discard => '放弃';
	@override String get error => '错误';
}

// Path: connectivity
class _Translations$connectivity$zh_Hans extends Translations$connectivity$en {
	_Translations$connectivity$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get online => '已连接';
	@override String get offline => '你已离线。部分操作可能不可用。';
	@override String get backOnline => '网络已恢复。';
	@override String get limited => '连接受限。部分操作可能缓慢或不可用。';
}

// Path: navigation
class _Translations$navigation$zh_Hans extends Translations$navigation$en {
	_Translations$navigation$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get home => '主页';
	@override String get pricing => '价格';
	@override String get settings => '设置';
}

// Path: onboarding
class _Translations$onboarding$zh_Hans extends Translations$onboarding$en {
	_Translations$onboarding$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get brand => '经过思考的起点';
	@override String progress({required Object current, required Object total}) => '第 ${current} 步，共 ${total} 步';
	@override String get firstTitle => '从可靠的基础开始';
	@override String get firstBody => '从明确配置、严格质量检查和可持续扩展的界面开始构建。';
	@override String get middleTitle => '为每一种屏幕而设计';
	@override String get middleBody => '同一套生产页面可从紧凑触控布局适配到精确的桌面工作流。';
	@override String get finalTitle => '偏好始终由你掌控';
	@override String get finalBody => '自由选择外观、语言和文字大小，同时保留系统无障碍设置。';
	@override String get openPaywall => '查看方案';
}

// Path: pricing
class _Translations$pricing$zh_Hans extends Translations$pricing$en {
	_Translations$pricing$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '适合不同工作方式的方案';
	@override String get body => '比较一组精简、透明的静态方案。此模板不会连接真实购买流程。';
	@override String get monthly => '按月';
	@override String get annual => '按年';
	@override String get billedMonthly => '每月结算';
	@override String get billedAnnually => '每年结算一次';
	@override String get periodMonth => '每月';
	@override String get periodYear => '每年';
	@override String get recommended => '推荐';
	@override String get current => '当前方案';
	@override String choosePlan({required Object plan}) => '预览${plan}';
	@override String get unavailable => '不可用';
	@override String get unavailableReason => '此预览中的方案选择不可用。你仍可查看所有方案。';
	@override String get comparisonTitle => '方案对比';
	@override String get faqTitle => '常见问题';
	@override String get faqQuestion => '以后可以更换方案吗？';
	@override String get faqAnswer => '可以。此静态体验仅演示布局，不会创建任何订阅。';
	@override String get restore => '恢复购买';
	@override String get restoreUnavailable => '此模板未连接购买恢复功能。';
	@override String get terms => '条款';
	@override String get privacy => '隐私';
	@override String get staticPurchaseNotice => '不会产生付款或购买。';
	@override String get staticSuccess => '方案选择预览已完成，未产生购买。';
	@override String get paywallTitle => '用更多空间继续构建';
	@override String get paywallBody => '查看权益并选择结算周期，也可以跳过后继续探索模板。';
	@override String get paywallContinue => '预览所选方案并继续';
	@override String get benefitAdaptive => '适配手机和桌面的布局';
	@override String get benefitLocalized => '支持英语、阿拉伯语和简体中文';
	@override String get benefitAccessible => '兼顾无障碍的缩放和输入策略';
	@override late final _Translations$pricing$plans$zh_Hans plans = _Translations$pricing$plans$zh_Hans._(_root);
}

// Path: home
class _Translations$home$zh_Hans extends Translations$home$en {
	_Translations$home$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '从可靠的基础开始';
	@override String get body => '应用外壳已使用显式配置、自适应导航和本地化控件运行。';
	@override String greeting({required Object name}) => '欢迎，${name}';
	@override String get summary => '模板已配置完成，可以开始添加下一个真实产品能力。';
	@override String get quickActions => '快捷操作';
	@override String get editProfile => '更新个人资料';
	@override String get openSettings => '打开设置';
	@override String get openPricing => '查看价格';
	@override String get openLogin => '体验登录流程';
	@override String get statusTitle => '基础状态';
	@override String get statusReadyTitle => '可继续扩展';
	@override String get statusReadyBody => '配置、路由、本地化和自适应布局已连接。';
	@override String get statusAdaptiveTitle => '默认自适应';
	@override String get statusAdaptiveBody => '调整窗口大小时不会重置当前路由或功能状态。';
	@override String get statusLocalizedTitle => '从应用根节点本地化';
	@override String get statusLocalizedBody => '应用文案与 ForUI 文案共同使用所选语言和方向。';
	@override String get recentTitle => '最近活动';
	@override String get recentEmptyTitle => '暂无活动';
	@override String get recentEmptyBody => '确定产品领域后，真实活动可以替换这一明确的空状态。';
}

// Path: settings
class _Translations$settings$zh_Hans extends Translations$settings$en {
	_Translations$settings$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get appearance => '外观';
	@override String get language => '语言';
	@override String get account => '账户';
	@override String get subscription => '订阅';
	@override String get privacyAbout => '隐私与关于';
	@override String get themeMode => '主题模式';
	@override String get system => '跟随系统';
	@override String get light => '浅色';
	@override String get dark => '深色';
	@override String get accent => '强调色';
	@override String get accentNeutral => '中性';
	@override String get accentGreen => '绿色';
	@override String get accentBlue => '蓝色';
	@override String get accentAmber => '琥珀色';
	@override String get accentRose => '玫瑰色';
	@override String get accentViolet => '紫色';
	@override String get fontScale => '文字大小';
	@override String get motionPreview => '动画预览';
	@override String get locale => '应用语言';
	@override String get languageSystem => '使用设备语言';
	@override String get languageEnglish => '英语';
	@override String get languageArabic => '阿拉伯语';
	@override String get languageChinese => '简体中文';
	@override String get saved => '设置已保存';
	@override String get accountBody => '查看静态个人资料和身份验证流程。';
	@override String get openProfile => '更新个人资料';
	@override String get openLogin => '打开登录';
	@override String get subscriptionBody => '比较方案，不会启动购买流程。';
	@override String get openPricing => '查看价格';
	@override String get privacyBody => '静态阶段仅保存外观和语言偏好。';
	@override String get aboutBuild => '构建信息';
	@override String get terms => '条款预览';
	@override String get privacy => '隐私预览';
	@override String get enableBiometric => '使用生物识别解锁';
	@override String get passcode => '密码';
	@override String get autoLockDelay => '自动锁定延迟';
	@override String get lockOnBackground => '切到后台时锁定';
	@override late final _Translations$settings$analytics$zh_Hans analytics = _Translations$settings$analytics$zh_Hans._(_root);
	@override late final _Translations$settings$accessibility$zh_Hans accessibility = _Translations$settings$accessibility$zh_Hans._(_root);
	@override late final _Translations$settings$haptics$zh_Hans haptics = _Translations$settings$haptics$zh_Hans._(_root);
	@override late final _Translations$settings$about$zh_Hans about = _Translations$settings$about$zh_Hans._(_root);
}

// Path: auth
class _Translations$auth$zh_Hans extends Translations$auth$en {
	_Translations$auth$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$auth$common$zh_Hans common = _Translations$auth$common$zh_Hans._(_root);
	@override late final _Translations$auth$login$zh_Hans login = _Translations$auth$login$zh_Hans._(_root);
	@override late final _Translations$auth$register$zh_Hans register = _Translations$auth$register$zh_Hans._(_root);
	@override late final _Translations$auth$forgotPassword$zh_Hans forgotPassword = _Translations$auth$forgotPassword$zh_Hans._(_root);
	@override late final _Translations$auth$otp$zh_Hans otp = _Translations$auth$otp$zh_Hans._(_root);
	@override late final _Translations$auth$resetPassword$zh_Hans resetPassword = _Translations$auth$resetPassword$zh_Hans._(_root);
}

// Path: profile
class _Translations$profile$zh_Hans extends Translations$profile$en {
	_Translations$profile$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$profile$update$zh_Hans update = _Translations$profile$update$zh_Hans._(_root);
}

// Path: security
class _Translations$security$zh_Hans extends Translations$security$en {
	_Translations$security$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$security$biometric$zh_Hans biometric = _Translations$security$biometric$zh_Hans._(_root);
	@override late final _Translations$security$passcode$zh_Hans passcode = _Translations$security$passcode$zh_Hans._(_root);
}

// Path: forceUpdate
class _Translations$forceUpdate$zh_Hans extends Translations$forceUpdate$en {
	_Translations$forceUpdate$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '需要更新';
	@override String get body => '此版本已不再受支持。请更新至最新版本以继续。';
	@override String get updateNow => '立即更新';
}

// Path: softUpdate
class _Translations$softUpdate$zh_Hans extends Translations$softUpdate$en {
	_Translations$softUpdate$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '有新版本可用';
	@override String get body => '更新至最新版本以获取最新改进和修复。';
	@override String get update => '更新';
	@override String get later => '稍后';
}

// Path: session
class _Translations$session$zh_Hans extends Translations$session$en {
	_Translations$session$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get expired => '您的会话已过期，请重新登录。';
	@override String get signedOut => '您已退出登录。';
	@override String signedInPreview({required Object userId}) => '已以 ${userId} 身份登录';
	@override String get unavailable => '登录功能尚未连接。';
}

// Path: splash
class _Translations$splash$zh_Hans extends Translations$splash$en {
	_Translations$splash$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get loading => '正在启动';
	@override String get tagline => '精心打造的起点';
	@override String get error => '无法完成启动。';
}

// Path: states
class _Translations$states$zh_Hans extends Translations$states$en {
	_Translations$states$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get emptyTitle => '暂时没有内容';
	@override String get emptyBody => '内容可用后将显示在这里。';
	@override String get errorTitle => '无法加载';
	@override String get errorBody => '加载时出现问题。请重试。';
	@override String get loadingTitle => '加载中…';
}

// Path: announcements
class _Translations$announcements$zh_Hans extends Translations$announcements$en {
	_Translations$announcements$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get dismiss => '关闭';
	@override String get actionLearnMore => '了解更多';
	@override String get dismissFailed => '无法关闭此公告。';
	@override String get severityInfo => '信息';
	@override String get severitySuccess => '成功';
	@override String get severityWarning => '警告';
	@override String get severityCritical => '严重';
	@override late final _Translations$announcements$fixtures$zh_Hans fixtures = _Translations$announcements$fixtures$zh_Hans._(_root);
}

// Path: validation
class _Translations$validation$zh_Hans extends Translations$validation$en {
	_Translations$validation$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String required({required Object field}) => '${field} 为必填项。';
	@override String get email => '请输入有效的电子邮箱。';
	@override String get passwordWeak => '至少使用 8 个字符，并包含一个大写字母和一个数字。';
	@override String get passwordMismatch => '两次输入的密码不一致。';
	@override String get acceptTerms => '同意条款与隐私预览后才能继续。';
	@override String get otpDigits => '请输入完整的六位数字。';
	@override String get username => '使用 3–24 个字母、数字、句点或下划线。';
	@override String bioTooLong({required Object maximum}) => '个人简介不能超过 ${maximum} 个字符。';
}

// Path: routeError
class _Translations$routeError$zh_Hans extends Translations$routeError$en {
	_Translations$routeError$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '无法打开该页面';
	@override String get body => '地址未知或不完整。你可以返回安全页面。';
	@override String path({required Object path}) => '请求的地址：${path}';
	@override String get invalidOtpPurpose => '验证地址必须包含有效的注册或密码重置用途。';
}

// Path: startupFailure
class _Translations$startupFailure$zh_Hans extends Translations$startupFailure$en {
	_Translations$startupFailure$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '应用无法启动';
	@override String get body => '请关闭并重新启动应用。如果问题仍然存在，请向支持人员提供诊断 ID。';
	@override String diagnosticId({required Object id}) => '诊断 ID：${id}';
}

// Path: diagnostics
class _Translations$diagnostics$zh_Hans extends Translations$diagnostics$en {
	_Translations$diagnostics$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '开发诊断';
	@override String get environment => '环境';
	@override String get build => '构建版本';
	@override String get layout => '布局类别';
	@override String get interaction => '交互策略';
	@override String get lifecycle => '应用生命周期';
	@override String get viewingEnvironment => '观看环境';
	@override String get locale => '语言区域';
	@override String get capabilities => '平台能力';
	@override String get secureStorage => '安全存储';
	@override String get crashReporting => '崩溃报告';
	@override String get crashReportingNone => '未配置';
	@override String get analytics => '分析';
	@override String get analyticsNone => '未配置';
	@override String get featureFlags => '功能开关';
	@override String get redactedNotice => '诊断信息不包含凭据或用户内容。';
	@override late final _Translations$diagnostics$experiments$zh_Hans experiments = _Translations$diagnostics$experiments$zh_Hans._(_root);
}

// Path: devGallery
class _Translations$devGallery$zh_Hans extends Translations$devGallery$en {
	_Translations$devGallery$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '生产页面图库';
	@override String get search => '搜索用例';
	@override String get screen => '页面';
	@override String get galleryCase => '图库状态';
	@override String get preview => '预览';
	@override String get viewport => '视口';
	@override String get locale => '语言区域';
	@override String get theme => '主题';
	@override String get accent => '强调色';
	@override String get textScale => '文字缩放';
	@override String get systemTextScale => '系统文字缩放';
	@override String get interaction => '交互策略';
	@override String get viewingEnvironment => '观看环境';
	@override String get tvPlatform => '电视平台';
	@override String get motion => '动画';
	@override String get highContrast => '高对比度';
	@override String get boldText => '粗体文字';
	@override String get safeArea => '安全区域内边距';
	@override String get keyboardInsets => '键盘遮挡';
	@override String get displayFeature => '显示特征';
	@override String get light => '浅色';
	@override String get dark => '深色';
	@override String get enabled => '启用';
	@override String get disabled => '禁用';
	@override String get normal => '正常';
	@override String get maximum => '最大非线性缩放';
	@override String get touch => '触控';
	@override String get precision => '精确指针';
	@override String get hybrid => '混合输入';
	@override String get remote => '遥控器';
	@override String get hybridRemote => '遥控器和指针';
	@override String get nearField => '近距离';
	@override String get tenFoot => '十英尺界面';
	@override String get androidTv => 'Android TV';
	@override String get tvOS => 'tvOS';
	@override String get none => '无';
	@override String get fold => '垂直折叠';
	@override String get resetControls => '重置预览控制项';
	@override String get viewportCompactPhone => '紧凑手机';
	@override String get viewportShortPhone => '横屏短手机';
	@override String get viewportBelowMedium => '中等断点之前';
	@override String get viewportAtMedium => '中等断点';
	@override String get viewportMedium => '中等窗口';
	@override String get viewportBelowExpanded => '扩展断点之前';
	@override String get viewportAtExpanded => '扩展断点';
	@override String get viewportDesktop => '桌面';
	@override String get viewportNarrowDesktop => '窄幅桌面窗口';
	@override String get viewportTv720p => '电视 720p';
	@override String get viewportTv1080p => '电视 1080p';
	@override String get viewportTv4k => '电视 4K 等效';
	@override String get screenOnboarding => '新手引导';
	@override String get screenPaywall => '引导方案页';
	@override String get screenHome => '首页';
	@override String get screenLogin => '登录';
	@override String get screenRegister => '注册';
	@override String get screenForgotPassword => '忘记密码';
	@override String get screenOtpRegistration => '注册验证';
	@override String get screenOtpPasswordReset => '重置验证';
	@override String get screenResetPassword => '重置密码';
	@override String get screenProfile => '更新资料';
	@override String get screenPricing => '方案定价';
	@override String get screenSettings => '设置';
	@override String get screenConnectivity => '连接状态栏';
	@override String get screenForceUpdate => '强制更新';
	@override String get screenSoftUpdate => '建议更新';
	@override String get screenBusy => '忙碌指示器';
	@override String get screenSystem => '系统界面';
	@override String get screenOverlays => '浮层';
	@override String get screenSplash => '应用内启动页';
	@override String get screenStateViews => '状态视图';
	@override String get screenFormScaffolding => '表单脚手架';
	@override String get screenAnnouncements => '公告栏';
	@override String get caseSplashLoading => '启动中';
	@override String get caseSplashReady => '就绪';
	@override String get caseSplashError => '启动错误';
	@override String get caseStateEmpty => '空状态';
	@override String get caseStateError => '错误';
	@override String get caseStateLoading => '加载中';
	@override String get caseFormScaffoldDisabled => '提交已禁用';
	@override String get caseFormScaffoldEnabled => '提交已启用';
	@override String get caseFormScaffoldSubmitting => '提交中';
	@override String get caseAnnouncementsInfo => '信息';
	@override String get caseAnnouncementsSuccess => '成功';
	@override String get caseAnnouncementsWarning => '警告';
	@override String get caseAnnouncementsCritical => '严重';
	@override String get caseDefault => '默认';
	@override String get caseHardBlock => '强制阻止';
	@override String get caseSoftUpdate => '建议更新';
	@override String get caseBusyIndeterminate => '不确定进度';
	@override String get caseBusyDeterminate => '确定进度';
	@override String get caseBusyOverlay => '模态遮罩';
	@override String get caseExpandedCopy => '扩展文案';
	@override String get caseFirst => '第一步';
	@override String get caseMiddle => '中间';
	@override String get caseFinal => '最后一步';
	@override String get caseMonthly => '按月';
	@override String get caseAnnual => '按年';
	@override String get caseRecommended => '推荐';
	@override String get caseUnavailable => '不可用';
	@override String get caseEmpty => '空状态';
	@override String get caseFocused => '已聚焦';
	@override String get caseInvalid => '无效';
	@override String get caseSubmitting => '提交中';
	@override String get caseFieldError => '字段错误';
	@override String get caseGlobalError => '全局错误';
	@override String get caseSuccess => '成功';
	@override String get casePartial => '部分输入';
	@override String get casePastedComplete => '粘贴完成';
	@override String get caseExpired => '已过期';
	@override String get caseResending => '重新发送中';
	@override String get caseSaving => '保存中';
	@override String get caseSaved => '已保存';
	@override String get caseDirty => '未保存更改';
	@override String get caseDiscardPrompt => '放弃确认';
	@override String get caseStartupFailure => '启动失败';
	@override String get caseUnknownRoute => '未知路由';
	@override String get caseMalformedOtp => '无效验证码用途';
	@override String get caseDiagnostics => '诊断';
	@override String get caseDialog => '对话框';
	@override String get caseSheet => '底部面板';
	@override String get caseToast => '提示消息';
	@override String get casePopover => '弹出层';
	@override String get caseTooltip => '工具提示';
	@override String get caseKeyboardInset => '键盘遮挡表单';
	@override String get screenSession => '会话';
	@override String get caseSessionLoggedOut => '已退出登录';
	@override String get caseSessionLoggedIn => '已登录';
	@override String get screenAnalytics => '分析数据选项';
	@override String get screenBiometricLock => '生物识别锁';
	@override String get caseLocked => '已锁定';
	@override String get caseNotFound => '请求的图库用例未注册。';
	@override String get screenAccessibility => '辅助功能预设';
	@override String get caseAccessibilityComfortable => '舒适预设';
	@override String get caseAccessibilityLarge => '大号预设';
	@override String get caseAccessibilityDyslexia => '阅读障碍预设';
	@override String get screenPullRefresh => '下拉刷新';
	@override String get casePullRefreshList => '可刷新列表';
	@override String get casePullRefreshGrid => '自适应网格';
	@override String get screenHaptics => '触感反馈';
	@override String get caseHapticKinds => '全部类型';
	@override String get caseHapticSelection => '选择';
	@override String get caseHapticImpactLight => '轻度震动';
	@override String get caseHapticImpactMedium => '中度震动';
	@override String get caseHapticImpactHeavy => '重度震动';
	@override String get caseHapticSuccess => '成功';
	@override String get caseHapticWarning => '警告';
	@override String get caseHapticError => '错误';
	@override String get screenSkeleton => '骨架加载';
	@override String get caseSkeletonStatic => '静态（减少动态效果）';
	@override String get caseSkeletonShimmer => '微光';
	@override String get screenOtpMfa => 'MFA 验证';
	@override String get caseCountdown => '倒计时';
	@override String get screenNotifications => '通知';
	@override String get caseNotificationsNotRequested => '权限说明';
	@override String get caseNotificationsGranted => '已授予';
	@override String get caseNotificationsDenied => '已阻止';
	@override String get screenPermissions => '权限';
	@override String get casePermissionRationale => '说明';
	@override String get casePermissionDenied => '已拒绝';
	@override String get casePermissionPermanentlyDenied => '永久拒绝';
	@override String get screenLicense => '许可证';
	@override String get screenShare => '分享面板';
	@override String get screenAppUpdate => '应用内更新';
	@override String get screenSearchPagination => '搜索与分页';
	@override String get caseSearchField => '搜索框';
	@override String get caseSearchPaged => '分页列表';
	@override String get caseSearchPagedNoBackend => '分页列表（无后端）';
	@override String get screenToastDialogs => '提示与对话框';
	@override String get caseToastSuccess => '成功提示';
	@override String get caseToastInfo => '信息提示';
	@override String get caseToastWarning => '警告提示';
	@override String get caseToastError => '错误提示';
	@override String get caseDialogConfirm => '确认对话框';
	@override String get caseDialogDestroy => '删除对话框';
	@override String get screenPasscodeEntry => '密码输入';
	@override String get screenPasscodeSetup => '密码设置';
	@override String get casePasscodeIdle => '空闲';
	@override String get casePasscodeError => '错误';
	@override String get casePasscodeLockedOut => '已锁定';
	@override String get casePasscodeSetupMismatch => '确认不匹配';
	@override String get screenFeedback => '反馈';
	@override String get caseFeedbackDrafting => '编写中';
	@override String get caseFeedbackSubmitting => '提交中';
	@override String get caseFeedbackFailed => '失败';
	@override String get caseFeedbackSuccess => '成功';
}

// Path: notifications
class _Translations$notifications$zh_Hans extends Translations$notifications$en {
	_Translations$notifications$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get enableTitle => '开启通知';
	@override String get enableBody => '及时获取账户和活动的更新。你可以随时更改此设置。';
	@override String get deny => '暂不';
	@override String get allow => '允许';
	@override String get enableBlockedTitle => '通知已被阻止';
	@override String get enableBlockedBody => '打开系统设置以允许此应用接收通知。';
	@override String get disabled => '此模板中通知未连接。';
}

// Path: permission
class _Translations$permission$zh_Hans extends Translations$permission$en {
	_Translations$permission$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$permission$camera$zh_Hans camera = _Translations$permission$camera$zh_Hans._(_root);
	@override late final _Translations$permission$photos$zh_Hans photos = _Translations$permission$photos$zh_Hans._(_root);
	@override late final _Translations$permission$location$zh_Hans location = _Translations$permission$location$zh_Hans._(_root);
	@override String get continueRequest => '继续';
	@override String get notNow => '暂不';
	@override String get openSettings => '打开设置';
	@override String get denied => '权限已被拒绝。您可以随时重试。';
	@override String get permanentlyDenied => '权限已被阻止。请在系统设置中开启以继续。';
}

// Path: share
class _Translations$share$zh_Hans extends Translations$share$en {
	_Translations$share$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get success => '已分享';
	@override String get unavailable => '此设备不支持分享。';
	@override String get cancelled => '已取消分享。';
}

// Path: update
class _Translations$update$zh_Hans extends Translations$update$en {
	_Translations$update$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get checkForUpdates => '检查更新';
	@override String get available => '有可用更新。';
	@override String get notAvailable => '已是最新版本。';
	@override String get required => '需要更新才能继续。';
}

// Path: search
class _Translations$search$zh_Hans extends Translations$search$en {
	_Translations$search$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '搜索';
	@override String get placeholder => '搜索…';
	@override String get emptyTitle => '暂无结果';
	@override String get emptyBody => '请尝试其他搜索词。';
	@override String get errorTitle => '搜索暂不可用';
}

// Path: feedback
class _Translations$feedback$zh_Hans extends Translations$feedback$en {
	_Translations$feedback$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '发送反馈';
	@override String get messageLabel => '内容';
	@override String get messageHint => '发生了什么，或有什么可以改进？';
	@override String get includeScreenshot => '附上截图';
	@override String get emailOptional => '回复邮箱';
	@override String get submit => '发送';
	@override String get cancel => '取消';
	@override String get successTitle => '谢谢！';
	@override String get successBody => '您的反馈已发送。';
	@override String get failedTitle => '暂时无法发送您的反馈。';
	@override String get shakeEnabled => '摇动以打开反馈';
}

// Path: pricing.plans
class _Translations$pricing$plans$zh_Hans extends Translations$pricing$plans$en {
	_Translations$pricing$plans$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get basicName => '基础版';
	@override String get basicDescription => '适合个人项目的专注基础。';
	@override String get basicBenefitOne => '核心模板页面';
	@override String get basicBenefitTwo => '主题和语言设置';
	@override String get basicBenefitThree => '社区工作流';
	@override String get proName => '专业版';
	@override String get proDescription => '为持续成长的产品和团队提供更多结构。';
	@override String get proBenefitOne => '包含基础版全部内容';
	@override String get proBenefitTwo => '完整静态流程图库';
	@override String get proBenefitThree => '扩展质量检查';
	@override String get teamName => '团队版';
	@override String get teamDescription => '用于协同交付的共享起点。';
	@override String get teamBenefitOne => '包含专业版全部内容';
	@override String get teamBenefitTwo => '面向团队的约定';
	@override String get teamBenefitThree => '多平台发布工作流';
}

// Path: settings.analytics
class _Translations$settings$analytics$zh_Hans extends Translations$settings$analytics$en {
	_Translations$settings$analytics$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get optInTitle => '分析';
	@override String get optInBody => '通过发送匿名使用数据帮助改进应用。您可以随时关闭。';
	@override String get statusOn => '已开启';
	@override String get statusOff => '已关闭';
}

// Path: settings.accessibility
class _Translations$settings$accessibility$zh_Hans extends Translations$settings$accessibility$en {
	_Translations$settings$accessibility$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '辅助功能';
	@override late final _Translations$settings$accessibility$preset$zh_Hans preset = _Translations$settings$accessibility$preset$zh_Hans._(_root);
}

// Path: settings.haptics
class _Translations$settings$haptics$zh_Hans extends Translations$settings$haptics$en {
	_Translations$settings$haptics$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '触感反馈';
	@override String get enable => '对关键操作启用触感反馈';
}

// Path: settings.about
class _Translations$settings$about$zh_Hans extends Translations$settings$about$en {
	_Translations$settings$about$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get license => '许可证';
}

// Path: auth.common
class _Translations$auth$common$zh_Hans extends Translations$auth$common$en {
	_Translations$auth$common$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get email => '电子邮箱';
	@override String get password => '密码';
	@override String get confirmPassword => '确认密码';
	@override String get displayName => '显示名称';
	@override String get showPassword => '显示密码';
	@override String get hidePassword => '隐藏密码';
	@override String get passwordRequirements => '至少使用 8 个字符，并包含一个大写字母和一个数字。';
	@override String get returnToLogin => '返回登录';
}

// Path: auth.login
class _Translations$auth$login$zh_Hans extends Translations$auth$login$en {
	_Translations$auth$login$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '欢迎回来';
	@override String get body => '使用静态表单检查验证、焦点和导航行为。';
	@override String get rememberMe => '在此设备上记住我的邮箱';
	@override String get forgotPassword => '忘记密码？';
	@override String get register => '创建账户';
	@override String get submit => '登录';
	@override String get submitting => '正在登录';
	@override String get globalError => '无法完成静态登录，已保留输入内容。';
	@override String get success => '静态登录已完成。';
	@override String get lockedTitle => '尝试次数过多';
	@override String get tooManyAttempts => '失败尝试过多，请稍候。';
	@override String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '剩余 ${count} 次尝试',
	);
	@override String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		zero: '现在可以重试。',
		other: '请在 ${seconds} 秒后重试。',
	);
}

// Path: auth.register
class _Translations$auth$register$zh_Hans extends Translations$auth$register$en {
	_Translations$auth$register$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '创建账户';
	@override String get body => '输入用于演示注册和确认行为的信息。';
	@override String get acceptTerms => '我同意条款与隐私预览。';
	@override String get terms => '查看条款';
	@override String get privacy => '查看隐私';
	@override String get submit => '创建账户';
	@override String get submitting => '正在创建账户';
	@override String get globalError => '无法完成注册。请检查标记的字段并重试。';
	@override String get success => '注册信息已接受。';
	@override String get discardTitle => '放弃注册信息？';
	@override String get discardBody => '未保存的注册内容将被清除。';
	@override String get stay => '继续编辑';
	@override String get discard => '放弃信息';
}

// Path: auth.forgotPassword
class _Translations$auth$forgotPassword$zh_Hans extends Translations$auth$forgotPassword$en {
	_Translations$auth$forgotPassword$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '重置密码';
	@override String get body => '输入电子邮箱。确认信息保持中立，不会透露账户是否存在。';
	@override String get submit => '发送验证码';
	@override String get submitting => '正在准备验证';
	@override String get success => '如果该地址可以接收重置请求，验证码将会可用。';
}

// Path: auth.otp
class _Translations$auth$otp$zh_Hans extends Translations$auth$otp$en {
	_Translations$auth$otp$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get registrationTitle => '验证注册';
	@override String get registrationBody => '输入六位验证码以完成静态注册流程。';
	@override String get passwordResetTitle => '验证重置请求';
	@override String get passwordResetBody => '输入六位验证码，然后设置新密码。';
	@override String get code => '验证码';
	@override String get submit => '验证代码';
	@override String get submitting => '正在验证代码';
	@override String get resend => '重新发送代码';
	@override String resendIn({required Object seconds}) => '${seconds} 秒后可重新发送';
	@override String get resending => '正在重新发送代码';
	@override String get invalid => '验证码无效。';
	@override String get expired => '验证码已过期，请申请新代码。';
	@override String get registrationSuccess => '注册已验证。';
	@override String get passwordResetSuccess => '重置请求已验证。';
	@override String get mfaSuccess => '登录已验证。';
	@override String get lockedTitle => '尝试次数过多';
	@override String get tooManyAttempts => '失败尝试过多，请稍候。';
	@override String attemptsRemaining({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '剩余 ${count} 次尝试',
	);
	@override String lockedBody({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		zero: '现在可以重试。',
		other: '请在 ${seconds} 秒后重试。',
	);
	@override String get mfaTitle => '验证登录';
	@override String get mfaBody => '输入我们发送的六位验证码以完成登录。';
	@override String expiresIn({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		other: '将在 ${seconds} 秒后过期',
	);
	@override String get expiredTitle => '验证码已过期';
	@override String get expiredBody => '您的验证码已过期，请重新获取以继续。';
}

// Path: auth.resetPassword
class _Translations$auth$resetPassword$zh_Hans extends Translations$auth$resetPassword$en {
	_Translations$auth$resetPassword$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '设置新密码';
	@override String get body => '使用高强度密码，并确保两次输入完全一致。';
	@override String get newPassword => '新密码';
	@override String get submit => '更新密码';
	@override String get submitting => '正在更新密码';
	@override String get globalError => '无法完成静态密码更新。';
	@override String get success => '密码更新预览已完成，请返回登录。';
}

// Path: profile.update
class _Translations$profile$update$zh_Hans extends Translations$profile$update$en {
	_Translations$profile$update$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '更新个人资料';
	@override String get body => '编辑非敏感账户信息。草稿只在此页面保持挂载时保留。';
	@override String get avatar => '个人头像占位图';
	@override String get changeAvatar => '更换个人头像';
	@override String get avatarUnavailable => '图片选择尚未连接，也没有请求任何权限。';
	@override String get displayName => '显示名称';
	@override String get username => '用户名';
	@override String get email => '电子邮箱';
	@override String get emailReadOnly => '静态阶段无法更改电子邮箱。';
	@override String get bio => '个人简介';
	@override String bioCounter({required Object count, required Object maximum}) => '已输入 ${count} 个字符，上限 ${maximum} 个';
	@override String get save => '保存个人资料';
	@override String get saving => '正在保存个人资料';
	@override String get saved => '个人资料更改已在本次会话中保存。';
	@override String get globalError => '无法完成静态保存，已保留输入内容。';
	@override String get discardTitle => '放弃个人资料更改？';
	@override String get discardBody => '未保存的个人资料更改将被清除。';
	@override String get stay => '继续编辑';
	@override String get discard => '放弃更改';
}

// Path: security.biometric
class _Translations$security$biometric$zh_Hans extends Translations$security$biometric$en {
	_Translations$security$biometric$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get lockTitle => '使用生物识别解锁';
	@override String get lockBody => '使用您的指纹或面容解锁应用。';
	@override String get authFailedTitle => '认证失败，请重试。';
	@override String get unlock => '解锁';
	@override String get unlocking => '正在解锁';
	@override String get unavailableTitle => '生物识别解锁不可用';
	@override String get unavailableBody => '此设备不支持生物识别解锁。请改用您的设备凭据。';
	@override String get useFallback => '使用设备凭据';
}

// Path: security.passcode
class _Translations$security$passcode$zh_Hans extends Translations$security$passcode$en {
	_Translations$security$passcode$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get enterTitle => '输入密码';
	@override String get enterBody => '输入您的密码以解锁应用。';
	@override String get setupTitle => '设置密码';
	@override String get setupBody => '选择一个在生物识别不可用时可以使用的数字密码。';
	@override String get confirmTitle => '确认密码';
	@override String get reenter => '再次输入密码';
	@override String get mismatch => '两次输入的密码不一致，请重试。';
	@override String incorrect({required num n, required Object attempts}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		one: '密码错误。还剩 1 次尝试机会。',
		other: '密码错误。还剩 ${attempts} 次尝试机会。',
	);
	@override String lockedOut({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n,
		zero: '尝试次数过多。请现在重试。',
		one: '尝试次数过多。请在 1 秒后重试。',
		other: '尝试次数过多。请在 ${seconds} 秒后重试。',
	);
	@override String get disable => '停用密码';
}

// Path: announcements.fixtures
class _Translations$announcements$fixtures$zh_Hans extends Translations$announcements$fixtures$en {
	_Translations$announcements$fixtures$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override late final _Translations$announcements$fixtures$welcome$zh_Hans welcome = _Translations$announcements$fixtures$welcome$zh_Hans._(_root);
	@override late final _Translations$announcements$fixtures$changelog$zh_Hans changelog = _Translations$announcements$fixtures$changelog$zh_Hans._(_root);
	@override late final _Translations$announcements$fixtures$deprecation$zh_Hans deprecation = _Translations$announcements$fixtures$deprecation$zh_Hans._(_root);
	@override late final _Translations$announcements$fixtures$outage$zh_Hans outage = _Translations$announcements$fixtures$outage$zh_Hans._(_root);
}

// Path: diagnostics.experiments
class _Translations$diagnostics$experiments$zh_Hans extends Translations$diagnostics$experiments$en {
	_Translations$diagnostics$experiments$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '实验';
	@override String get source => '来源';
}

// Path: permission.camera
class _Translations$permission$camera$zh_Hans extends Translations$permission$camera$en {
	_Translations$permission$camera$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '相机访问';
	@override String get rationale => '我们使用相机拍摄新的个人头像照片。您可以随时拒绝。';
}

// Path: permission.photos
class _Translations$permission$photos$zh_Hans extends Translations$permission$photos$en {
	_Translations$permission$photos$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '照片库访问';
	@override String get rationale => '我们读取您的照片库以便选择个人头像。您可以随时拒绝。';
}

// Path: permission.location
class _Translations$permission$location$zh_Hans extends Translations$permission$location$en {
	_Translations$permission$location$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '位置访问';
	@override String get rationale => '我们使用您的位置来个性化您的体验。您可以随时拒绝。';
}

// Path: settings.accessibility.preset
class _Translations$settings$accessibility$preset$zh_Hans extends Translations$settings$accessibility$preset$en {
	_Translations$settings$accessibility$preset$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get comfortable => '舒适';
	@override String get comfortableDescription => '适合日常阅读的默认文字大小。';
	@override String get large => '大号';
	@override String get largeDescription => '更大的文字，便于一眼阅读。';
	@override String get dyslexia => '阅读障碍友好';
	@override String get dyslexiaDescription => '略大的文字，并在可用时使用阅读障碍友好字体。';
}

// Path: announcements.fixtures.welcome
class _Translations$announcements$fixtures$welcome$zh_Hans extends Translations$announcements$fixtures$welcome$en {
	_Translations$announcements$fixtures$welcome$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '欢迎使用本起步模板';
	@override String get message => '为你的下一个产品提供坚实基础。关闭此公告即可开始浏览。';
}

// Path: announcements.fixtures.changelog
class _Translations$announcements$fixtures$changelog$zh_Hans extends Translations$announcements$fixtures$changelog$en {
	_Translations$announcements$fixtures$changelog$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '本版本的新内容';
	@override String get message => '公告让所有人无需应用更新即可获知最新动态。';
}

// Path: announcements.fixtures.deprecation
class _Translations$announcements$fixtures$deprecation$zh_Hans extends Translations$announcements$fixtures$deprecation$en {
	_Translations$announcements$fixtures$deprecation$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '有更新版本可用';
	@override String get message => '此版本即将停止维护，请尽快更新。';
}

// Path: announcements.fixtures.outage
class _Translations$announcements$fixtures$outage$zh_Hans extends Translations$announcements$fixtures$outage$en {
	_Translations$announcements$fixtures$outage$zh_Hans._(TranslationsZhHans root) : this._root = root, super.internal(root);

	final TranslationsZhHans _root; // ignore: unused_field

	// Translations
	@override String get title => '服务中断';
	@override String get message => '我们正在处理服务故障，部分操作可能失败。';
}

/// The flat map containing all translations for locale <zh-Hans>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZhHans {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => '起点',
			'common.back' => '返回',
			'common.home' => '主页',
			'common.retry' => '重试',
			'common.save' => '保存',
			'common.cancel' => '取消',
			'common.close' => '关闭',
			'common.continueAction' => '继续',
			'common.skip' => '跳过',
			'common.reset' => '重置',
			'common.done' => '完成',
			'common.previous' => '上一步',
			'common.next' => '下一步',
			'common.optional' => '可选',
			'common.loading' => '正在加载',
			'common.saving' => '正在保存…',
			'common.notConnected' => '此操作尚未连接。',
			'common.legalPlaceholderTitle' => '信息预览',
			'common.legalPlaceholderBody' => '在产品专属法律文本获批前，此模板会显示明确且可复现的占位内容。',
			'common.confirm' => '确认',
			'common.success' => '成功',
			'common.discard' => '放弃',
			'common.error' => '错误',
			'connectivity.online' => '已连接',
			'connectivity.offline' => '你已离线。部分操作可能不可用。',
			'connectivity.backOnline' => '网络已恢复。',
			'connectivity.limited' => '连接受限。部分操作可能缓慢或不可用。',
			'navigation.home' => '主页',
			'navigation.pricing' => '价格',
			'navigation.settings' => '设置',
			'onboarding.brand' => '经过思考的起点',
			'onboarding.progress' => ({required Object current, required Object total}) => '第 ${current} 步，共 ${total} 步',
			'onboarding.firstTitle' => '从可靠的基础开始',
			'onboarding.firstBody' => '从明确配置、严格质量检查和可持续扩展的界面开始构建。',
			'onboarding.middleTitle' => '为每一种屏幕而设计',
			'onboarding.middleBody' => '同一套生产页面可从紧凑触控布局适配到精确的桌面工作流。',
			'onboarding.finalTitle' => '偏好始终由你掌控',
			'onboarding.finalBody' => '自由选择外观、语言和文字大小，同时保留系统无障碍设置。',
			'onboarding.openPaywall' => '查看方案',
			'pricing.title' => '适合不同工作方式的方案',
			'pricing.body' => '比较一组精简、透明的静态方案。此模板不会连接真实购买流程。',
			'pricing.monthly' => '按月',
			'pricing.annual' => '按年',
			'pricing.billedMonthly' => '每月结算',
			'pricing.billedAnnually' => '每年结算一次',
			'pricing.periodMonth' => '每月',
			'pricing.periodYear' => '每年',
			'pricing.recommended' => '推荐',
			'pricing.current' => '当前方案',
			'pricing.choosePlan' => ({required Object plan}) => '预览${plan}',
			'pricing.unavailable' => '不可用',
			'pricing.unavailableReason' => '此预览中的方案选择不可用。你仍可查看所有方案。',
			'pricing.comparisonTitle' => '方案对比',
			'pricing.faqTitle' => '常见问题',
			'pricing.faqQuestion' => '以后可以更换方案吗？',
			'pricing.faqAnswer' => '可以。此静态体验仅演示布局，不会创建任何订阅。',
			'pricing.restore' => '恢复购买',
			'pricing.restoreUnavailable' => '此模板未连接购买恢复功能。',
			'pricing.terms' => '条款',
			'pricing.privacy' => '隐私',
			'pricing.staticPurchaseNotice' => '不会产生付款或购买。',
			'pricing.staticSuccess' => '方案选择预览已完成，未产生购买。',
			'pricing.paywallTitle' => '用更多空间继续构建',
			'pricing.paywallBody' => '查看权益并选择结算周期，也可以跳过后继续探索模板。',
			'pricing.paywallContinue' => '预览所选方案并继续',
			'pricing.benefitAdaptive' => '适配手机和桌面的布局',
			'pricing.benefitLocalized' => '支持英语、阿拉伯语和简体中文',
			'pricing.benefitAccessible' => '兼顾无障碍的缩放和输入策略',
			'pricing.plans.basicName' => '基础版',
			'pricing.plans.basicDescription' => '适合个人项目的专注基础。',
			'pricing.plans.basicBenefitOne' => '核心模板页面',
			'pricing.plans.basicBenefitTwo' => '主题和语言设置',
			'pricing.plans.basicBenefitThree' => '社区工作流',
			'pricing.plans.proName' => '专业版',
			'pricing.plans.proDescription' => '为持续成长的产品和团队提供更多结构。',
			'pricing.plans.proBenefitOne' => '包含基础版全部内容',
			'pricing.plans.proBenefitTwo' => '完整静态流程图库',
			'pricing.plans.proBenefitThree' => '扩展质量检查',
			'pricing.plans.teamName' => '团队版',
			'pricing.plans.teamDescription' => '用于协同交付的共享起点。',
			'pricing.plans.teamBenefitOne' => '包含专业版全部内容',
			'pricing.plans.teamBenefitTwo' => '面向团队的约定',
			'pricing.plans.teamBenefitThree' => '多平台发布工作流',
			'home.title' => '从可靠的基础开始',
			'home.body' => '应用外壳已使用显式配置、自适应导航和本地化控件运行。',
			'home.greeting' => ({required Object name}) => '欢迎，${name}',
			'home.summary' => '模板已配置完成，可以开始添加下一个真实产品能力。',
			'home.quickActions' => '快捷操作',
			'home.editProfile' => '更新个人资料',
			'home.openSettings' => '打开设置',
			'home.openPricing' => '查看价格',
			'home.openLogin' => '体验登录流程',
			'home.statusTitle' => '基础状态',
			'home.statusReadyTitle' => '可继续扩展',
			'home.statusReadyBody' => '配置、路由、本地化和自适应布局已连接。',
			'home.statusAdaptiveTitle' => '默认自适应',
			'home.statusAdaptiveBody' => '调整窗口大小时不会重置当前路由或功能状态。',
			'home.statusLocalizedTitle' => '从应用根节点本地化',
			'home.statusLocalizedBody' => '应用文案与 ForUI 文案共同使用所选语言和方向。',
			'home.recentTitle' => '最近活动',
			'home.recentEmptyTitle' => '暂无活动',
			'home.recentEmptyBody' => '确定产品领域后，真实活动可以替换这一明确的空状态。',
			'settings.title' => '设置',
			'settings.appearance' => '外观',
			'settings.language' => '语言',
			'settings.account' => '账户',
			'settings.subscription' => '订阅',
			'settings.privacyAbout' => '隐私与关于',
			'settings.themeMode' => '主题模式',
			'settings.system' => '跟随系统',
			'settings.light' => '浅色',
			'settings.dark' => '深色',
			'settings.accent' => '强调色',
			'settings.accentNeutral' => '中性',
			'settings.accentGreen' => '绿色',
			'settings.accentBlue' => '蓝色',
			'settings.accentAmber' => '琥珀色',
			'settings.accentRose' => '玫瑰色',
			'settings.accentViolet' => '紫色',
			'settings.fontScale' => '文字大小',
			'settings.motionPreview' => '动画预览',
			'settings.locale' => '应用语言',
			'settings.languageSystem' => '使用设备语言',
			'settings.languageEnglish' => '英语',
			'settings.languageArabic' => '阿拉伯语',
			'settings.languageChinese' => '简体中文',
			'settings.saved' => '设置已保存',
			'settings.accountBody' => '查看静态个人资料和身份验证流程。',
			'settings.openProfile' => '更新个人资料',
			'settings.openLogin' => '打开登录',
			'settings.subscriptionBody' => '比较方案，不会启动购买流程。',
			'settings.openPricing' => '查看价格',
			'settings.privacyBody' => '静态阶段仅保存外观和语言偏好。',
			'settings.aboutBuild' => '构建信息',
			'settings.terms' => '条款预览',
			'settings.privacy' => '隐私预览',
			'settings.enableBiometric' => '使用生物识别解锁',
			'settings.passcode' => '密码',
			'settings.autoLockDelay' => '自动锁定延迟',
			'settings.lockOnBackground' => '切到后台时锁定',
			'settings.analytics.optInTitle' => '分析',
			'settings.analytics.optInBody' => '通过发送匿名使用数据帮助改进应用。您可以随时关闭。',
			'settings.analytics.statusOn' => '已开启',
			'settings.analytics.statusOff' => '已关闭',
			'settings.accessibility.title' => '辅助功能',
			'settings.accessibility.preset.comfortable' => '舒适',
			'settings.accessibility.preset.comfortableDescription' => '适合日常阅读的默认文字大小。',
			'settings.accessibility.preset.large' => '大号',
			'settings.accessibility.preset.largeDescription' => '更大的文字，便于一眼阅读。',
			'settings.accessibility.preset.dyslexia' => '阅读障碍友好',
			'settings.accessibility.preset.dyslexiaDescription' => '略大的文字，并在可用时使用阅读障碍友好字体。',
			'settings.haptics.title' => '触感反馈',
			'settings.haptics.enable' => '对关键操作启用触感反馈',
			'settings.about.license' => '许可证',
			'auth.common.email' => '电子邮箱',
			'auth.common.password' => '密码',
			'auth.common.confirmPassword' => '确认密码',
			'auth.common.displayName' => '显示名称',
			'auth.common.showPassword' => '显示密码',
			'auth.common.hidePassword' => '隐藏密码',
			'auth.common.passwordRequirements' => '至少使用 8 个字符，并包含一个大写字母和一个数字。',
			'auth.common.returnToLogin' => '返回登录',
			'auth.login.title' => '欢迎回来',
			'auth.login.body' => '使用静态表单检查验证、焦点和导航行为。',
			'auth.login.rememberMe' => '在此设备上记住我的邮箱',
			'auth.login.forgotPassword' => '忘记密码？',
			'auth.login.register' => '创建账户',
			'auth.login.submit' => '登录',
			'auth.login.submitting' => '正在登录',
			'auth.login.globalError' => '无法完成静态登录，已保留输入内容。',
			'auth.login.success' => '静态登录已完成。',
			'auth.login.lockedTitle' => '尝试次数过多',
			'auth.login.tooManyAttempts' => '失败尝试过多，请稍候。',
			'auth.login.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '剩余 ${count} 次尝试', ), 
			'auth.login.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, zero: '现在可以重试。', other: '请在 ${seconds} 秒后重试。', ), 
			'auth.register.title' => '创建账户',
			'auth.register.body' => '输入用于演示注册和确认行为的信息。',
			'auth.register.acceptTerms' => '我同意条款与隐私预览。',
			'auth.register.terms' => '查看条款',
			'auth.register.privacy' => '查看隐私',
			'auth.register.submit' => '创建账户',
			'auth.register.submitting' => '正在创建账户',
			'auth.register.globalError' => '无法完成注册。请检查标记的字段并重试。',
			'auth.register.success' => '注册信息已接受。',
			'auth.register.discardTitle' => '放弃注册信息？',
			'auth.register.discardBody' => '未保存的注册内容将被清除。',
			'auth.register.stay' => '继续编辑',
			'auth.register.discard' => '放弃信息',
			'auth.forgotPassword.title' => '重置密码',
			'auth.forgotPassword.body' => '输入电子邮箱。确认信息保持中立，不会透露账户是否存在。',
			'auth.forgotPassword.submit' => '发送验证码',
			'auth.forgotPassword.submitting' => '正在准备验证',
			'auth.forgotPassword.success' => '如果该地址可以接收重置请求，验证码将会可用。',
			'auth.otp.registrationTitle' => '验证注册',
			'auth.otp.registrationBody' => '输入六位验证码以完成静态注册流程。',
			'auth.otp.passwordResetTitle' => '验证重置请求',
			'auth.otp.passwordResetBody' => '输入六位验证码，然后设置新密码。',
			'auth.otp.code' => '验证码',
			'auth.otp.submit' => '验证代码',
			'auth.otp.submitting' => '正在验证代码',
			'auth.otp.resend' => '重新发送代码',
			'auth.otp.resendIn' => ({required Object seconds}) => '${seconds} 秒后可重新发送',
			'auth.otp.resending' => '正在重新发送代码',
			'auth.otp.invalid' => '验证码无效。',
			'auth.otp.expired' => '验证码已过期，请申请新代码。',
			'auth.otp.registrationSuccess' => '注册已验证。',
			'auth.otp.passwordResetSuccess' => '重置请求已验证。',
			'auth.otp.mfaSuccess' => '登录已验证。',
			'auth.otp.lockedTitle' => '尝试次数过多',
			'auth.otp.tooManyAttempts' => '失败尝试过多，请稍候。',
			'auth.otp.attemptsRemaining' => ({required num n, required Object count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '剩余 ${count} 次尝试', ), 
			'auth.otp.lockedBody' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, zero: '现在可以重试。', other: '请在 ${seconds} 秒后重试。', ), 
			'auth.otp.mfaTitle' => '验证登录',
			'auth.otp.mfaBody' => '输入我们发送的六位验证码以完成登录。',
			'auth.otp.expiresIn' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, other: '将在 ${seconds} 秒后过期', ), 
			'auth.otp.expiredTitle' => '验证码已过期',
			'auth.otp.expiredBody' => '您的验证码已过期，请重新获取以继续。',
			'auth.resetPassword.title' => '设置新密码',
			'auth.resetPassword.body' => '使用高强度密码，并确保两次输入完全一致。',
			'auth.resetPassword.newPassword' => '新密码',
			'auth.resetPassword.submit' => '更新密码',
			'auth.resetPassword.submitting' => '正在更新密码',
			'auth.resetPassword.globalError' => '无法完成静态密码更新。',
			'auth.resetPassword.success' => '密码更新预览已完成，请返回登录。',
			'profile.update.title' => '更新个人资料',
			'profile.update.body' => '编辑非敏感账户信息。草稿只在此页面保持挂载时保留。',
			'profile.update.avatar' => '个人头像占位图',
			'profile.update.changeAvatar' => '更换个人头像',
			'profile.update.avatarUnavailable' => '图片选择尚未连接，也没有请求任何权限。',
			'profile.update.displayName' => '显示名称',
			'profile.update.username' => '用户名',
			'profile.update.email' => '电子邮箱',
			'profile.update.emailReadOnly' => '静态阶段无法更改电子邮箱。',
			'profile.update.bio' => '个人简介',
			'profile.update.bioCounter' => ({required Object count, required Object maximum}) => '已输入 ${count} 个字符，上限 ${maximum} 个',
			'profile.update.save' => '保存个人资料',
			'profile.update.saving' => '正在保存个人资料',
			'profile.update.saved' => '个人资料更改已在本次会话中保存。',
			'profile.update.globalError' => '无法完成静态保存，已保留输入内容。',
			'profile.update.discardTitle' => '放弃个人资料更改？',
			'profile.update.discardBody' => '未保存的个人资料更改将被清除。',
			'profile.update.stay' => '继续编辑',
			'profile.update.discard' => '放弃更改',
			'security.biometric.lockTitle' => '使用生物识别解锁',
			'security.biometric.lockBody' => '使用您的指纹或面容解锁应用。',
			'security.biometric.authFailedTitle' => '认证失败，请重试。',
			'security.biometric.unlock' => '解锁',
			'security.biometric.unlocking' => '正在解锁',
			'security.biometric.unavailableTitle' => '生物识别解锁不可用',
			'security.biometric.unavailableBody' => '此设备不支持生物识别解锁。请改用您的设备凭据。',
			'security.biometric.useFallback' => '使用设备凭据',
			'security.passcode.enterTitle' => '输入密码',
			'security.passcode.enterBody' => '输入您的密码以解锁应用。',
			'security.passcode.setupTitle' => '设置密码',
			'security.passcode.setupBody' => '选择一个在生物识别不可用时可以使用的数字密码。',
			'security.passcode.confirmTitle' => '确认密码',
			'security.passcode.reenter' => '再次输入密码',
			'security.passcode.mismatch' => '两次输入的密码不一致，请重试。',
			'security.passcode.incorrect' => ({required num n, required Object attempts}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, one: '密码错误。还剩 1 次尝试机会。', other: '密码错误。还剩 ${attempts} 次尝试机会。', ), 
			'security.passcode.lockedOut' => ({required num n, required Object seconds}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('zh'))(n, zero: '尝试次数过多。请现在重试。', one: '尝试次数过多。请在 1 秒后重试。', other: '尝试次数过多。请在 ${seconds} 秒后重试。', ), 
			'security.passcode.disable' => '停用密码',
			'forceUpdate.title' => '需要更新',
			'forceUpdate.body' => '此版本已不再受支持。请更新至最新版本以继续。',
			'forceUpdate.updateNow' => '立即更新',
			'softUpdate.title' => '有新版本可用',
			'softUpdate.body' => '更新至最新版本以获取最新改进和修复。',
			'softUpdate.update' => '更新',
			'softUpdate.later' => '稍后',
			'session.expired' => '您的会话已过期，请重新登录。',
			'session.signedOut' => '您已退出登录。',
			'session.signedInPreview' => ({required Object userId}) => '已以 ${userId} 身份登录',
			'session.unavailable' => '登录功能尚未连接。',
			'splash.loading' => '正在启动',
			'splash.tagline' => '精心打造的起点',
			'splash.error' => '无法完成启动。',
			'states.emptyTitle' => '暂时没有内容',
			'states.emptyBody' => '内容可用后将显示在这里。',
			'states.errorTitle' => '无法加载',
			'states.errorBody' => '加载时出现问题。请重试。',
			'states.loadingTitle' => '加载中…',
			'announcements.dismiss' => '关闭',
			'announcements.actionLearnMore' => '了解更多',
			'announcements.dismissFailed' => '无法关闭此公告。',
			'announcements.severityInfo' => '信息',
			'announcements.severitySuccess' => '成功',
			'announcements.severityWarning' => '警告',
			'announcements.severityCritical' => '严重',
			'announcements.fixtures.welcome.title' => '欢迎使用本起步模板',
			'announcements.fixtures.welcome.message' => '为你的下一个产品提供坚实基础。关闭此公告即可开始浏览。',
			'announcements.fixtures.changelog.title' => '本版本的新内容',
			'announcements.fixtures.changelog.message' => '公告让所有人无需应用更新即可获知最新动态。',
			'announcements.fixtures.deprecation.title' => '有更新版本可用',
			'announcements.fixtures.deprecation.message' => '此版本即将停止维护，请尽快更新。',
			'announcements.fixtures.outage.title' => '服务中断',
			'announcements.fixtures.outage.message' => '我们正在处理服务故障，部分操作可能失败。',
			'validation.required' => ({required Object field}) => '${field} 为必填项。',
			'validation.email' => '请输入有效的电子邮箱。',
			'validation.passwordWeak' => '至少使用 8 个字符，并包含一个大写字母和一个数字。',
			'validation.passwordMismatch' => '两次输入的密码不一致。',
			'validation.acceptTerms' => '同意条款与隐私预览后才能继续。',
			'validation.otpDigits' => '请输入完整的六位数字。',
			'validation.username' => '使用 3–24 个字母、数字、句点或下划线。',
			'validation.bioTooLong' => ({required Object maximum}) => '个人简介不能超过 ${maximum} 个字符。',
			'routeError.title' => '无法打开该页面',
			'routeError.body' => '地址未知或不完整。你可以返回安全页面。',
			'routeError.path' => ({required Object path}) => '请求的地址：${path}',
			'routeError.invalidOtpPurpose' => '验证地址必须包含有效的注册或密码重置用途。',
			'startupFailure.title' => '应用无法启动',
			'startupFailure.body' => '请关闭并重新启动应用。如果问题仍然存在，请向支持人员提供诊断 ID。',
			'startupFailure.diagnosticId' => ({required Object id}) => '诊断 ID：${id}',
			'diagnostics.title' => '开发诊断',
			'diagnostics.environment' => '环境',
			'diagnostics.build' => '构建版本',
			'diagnostics.layout' => '布局类别',
			'diagnostics.interaction' => '交互策略',
			'diagnostics.lifecycle' => '应用生命周期',
			'diagnostics.viewingEnvironment' => '观看环境',
			'diagnostics.locale' => '语言区域',
			'diagnostics.capabilities' => '平台能力',
			'diagnostics.secureStorage' => '安全存储',
			'diagnostics.crashReporting' => '崩溃报告',
			'diagnostics.crashReportingNone' => '未配置',
			'diagnostics.analytics' => '分析',
			'diagnostics.analyticsNone' => '未配置',
			'diagnostics.featureFlags' => '功能开关',
			'diagnostics.redactedNotice' => '诊断信息不包含凭据或用户内容。',
			'diagnostics.experiments.title' => '实验',
			'diagnostics.experiments.source' => '来源',
			'devGallery.title' => '生产页面图库',
			'devGallery.search' => '搜索用例',
			'devGallery.screen' => '页面',
			'devGallery.galleryCase' => '图库状态',
			'devGallery.preview' => '预览',
			'devGallery.viewport' => '视口',
			'devGallery.locale' => '语言区域',
			'devGallery.theme' => '主题',
			'devGallery.accent' => '强调色',
			'devGallery.textScale' => '文字缩放',
			'devGallery.systemTextScale' => '系统文字缩放',
			'devGallery.interaction' => '交互策略',
			'devGallery.viewingEnvironment' => '观看环境',
			'devGallery.tvPlatform' => '电视平台',
			'devGallery.motion' => '动画',
			'devGallery.highContrast' => '高对比度',
			'devGallery.boldText' => '粗体文字',
			'devGallery.safeArea' => '安全区域内边距',
			'devGallery.keyboardInsets' => '键盘遮挡',
			'devGallery.displayFeature' => '显示特征',
			'devGallery.light' => '浅色',
			'devGallery.dark' => '深色',
			'devGallery.enabled' => '启用',
			'devGallery.disabled' => '禁用',
			'devGallery.normal' => '正常',
			'devGallery.maximum' => '最大非线性缩放',
			'devGallery.touch' => '触控',
			'devGallery.precision' => '精确指针',
			'devGallery.hybrid' => '混合输入',
			'devGallery.remote' => '遥控器',
			'devGallery.hybridRemote' => '遥控器和指针',
			'devGallery.nearField' => '近距离',
			'devGallery.tenFoot' => '十英尺界面',
			'devGallery.androidTv' => 'Android TV',
			'devGallery.tvOS' => 'tvOS',
			'devGallery.none' => '无',
			'devGallery.fold' => '垂直折叠',
			'devGallery.resetControls' => '重置预览控制项',
			'devGallery.viewportCompactPhone' => '紧凑手机',
			'devGallery.viewportShortPhone' => '横屏短手机',
			'devGallery.viewportBelowMedium' => '中等断点之前',
			'devGallery.viewportAtMedium' => '中等断点',
			'devGallery.viewportMedium' => '中等窗口',
			'devGallery.viewportBelowExpanded' => '扩展断点之前',
			'devGallery.viewportAtExpanded' => '扩展断点',
			'devGallery.viewportDesktop' => '桌面',
			'devGallery.viewportNarrowDesktop' => '窄幅桌面窗口',
			'devGallery.viewportTv720p' => '电视 720p',
			'devGallery.viewportTv1080p' => '电视 1080p',
			'devGallery.viewportTv4k' => '电视 4K 等效',
			'devGallery.screenOnboarding' => '新手引导',
			'devGallery.screenPaywall' => '引导方案页',
			'devGallery.screenHome' => '首页',
			'devGallery.screenLogin' => '登录',
			'devGallery.screenRegister' => '注册',
			'devGallery.screenForgotPassword' => '忘记密码',
			'devGallery.screenOtpRegistration' => '注册验证',
			'devGallery.screenOtpPasswordReset' => '重置验证',
			'devGallery.screenResetPassword' => '重置密码',
			'devGallery.screenProfile' => '更新资料',
			'devGallery.screenPricing' => '方案定价',
			'devGallery.screenSettings' => '设置',
			'devGallery.screenConnectivity' => '连接状态栏',
			'devGallery.screenForceUpdate' => '强制更新',
			'devGallery.screenSoftUpdate' => '建议更新',
			'devGallery.screenBusy' => '忙碌指示器',
			'devGallery.screenSystem' => '系统界面',
			'devGallery.screenOverlays' => '浮层',
			'devGallery.screenSplash' => '应用内启动页',
			'devGallery.screenStateViews' => '状态视图',
			'devGallery.screenFormScaffolding' => '表单脚手架',
			'devGallery.screenAnnouncements' => '公告栏',
			'devGallery.caseSplashLoading' => '启动中',
			'devGallery.caseSplashReady' => '就绪',
			'devGallery.caseSplashError' => '启动错误',
			'devGallery.caseStateEmpty' => '空状态',
			'devGallery.caseStateError' => '错误',
			'devGallery.caseStateLoading' => '加载中',
			'devGallery.caseFormScaffoldDisabled' => '提交已禁用',
			'devGallery.caseFormScaffoldEnabled' => '提交已启用',
			'devGallery.caseFormScaffoldSubmitting' => '提交中',
			'devGallery.caseAnnouncementsInfo' => '信息',
			'devGallery.caseAnnouncementsSuccess' => '成功',
			'devGallery.caseAnnouncementsWarning' => '警告',
			'devGallery.caseAnnouncementsCritical' => '严重',
			'devGallery.caseDefault' => '默认',
			'devGallery.caseHardBlock' => '强制阻止',
			'devGallery.caseSoftUpdate' => '建议更新',
			'devGallery.caseBusyIndeterminate' => '不确定进度',
			'devGallery.caseBusyDeterminate' => '确定进度',
			'devGallery.caseBusyOverlay' => '模态遮罩',
			'devGallery.caseExpandedCopy' => '扩展文案',
			'devGallery.caseFirst' => '第一步',
			'devGallery.caseMiddle' => '中间',
			'devGallery.caseFinal' => '最后一步',
			'devGallery.caseMonthly' => '按月',
			'devGallery.caseAnnual' => '按年',
			'devGallery.caseRecommended' => '推荐',
			'devGallery.caseUnavailable' => '不可用',
			'devGallery.caseEmpty' => '空状态',
			'devGallery.caseFocused' => '已聚焦',
			'devGallery.caseInvalid' => '无效',
			'devGallery.caseSubmitting' => '提交中',
			'devGallery.caseFieldError' => '字段错误',
			'devGallery.caseGlobalError' => '全局错误',
			'devGallery.caseSuccess' => '成功',
			'devGallery.casePartial' => '部分输入',
			'devGallery.casePastedComplete' => '粘贴完成',
			'devGallery.caseExpired' => '已过期',
			'devGallery.caseResending' => '重新发送中',
			'devGallery.caseSaving' => '保存中',
			'devGallery.caseSaved' => '已保存',
			'devGallery.caseDirty' => '未保存更改',
			'devGallery.caseDiscardPrompt' => '放弃确认',
			'devGallery.caseStartupFailure' => '启动失败',
			'devGallery.caseUnknownRoute' => '未知路由',
			'devGallery.caseMalformedOtp' => '无效验证码用途',
			'devGallery.caseDiagnostics' => '诊断',
			'devGallery.caseDialog' => '对话框',
			'devGallery.caseSheet' => '底部面板',
			'devGallery.caseToast' => '提示消息',
			'devGallery.casePopover' => '弹出层',
			'devGallery.caseTooltip' => '工具提示',
			'devGallery.caseKeyboardInset' => '键盘遮挡表单',
			'devGallery.screenSession' => '会话',
			'devGallery.caseSessionLoggedOut' => '已退出登录',
			'devGallery.caseSessionLoggedIn' => '已登录',
			'devGallery.screenAnalytics' => '分析数据选项',
			'devGallery.screenBiometricLock' => '生物识别锁',
			'devGallery.caseLocked' => '已锁定',
			'devGallery.caseNotFound' => '请求的图库用例未注册。',
			'devGallery.screenAccessibility' => '辅助功能预设',
			'devGallery.caseAccessibilityComfortable' => '舒适预设',
			'devGallery.caseAccessibilityLarge' => '大号预设',
			'devGallery.caseAccessibilityDyslexia' => '阅读障碍预设',
			'devGallery.screenPullRefresh' => '下拉刷新',
			'devGallery.casePullRefreshList' => '可刷新列表',
			'devGallery.casePullRefreshGrid' => '自适应网格',
			'devGallery.screenHaptics' => '触感反馈',
			'devGallery.caseHapticKinds' => '全部类型',
			'devGallery.caseHapticSelection' => '选择',
			'devGallery.caseHapticImpactLight' => '轻度震动',
			'devGallery.caseHapticImpactMedium' => '中度震动',
			'devGallery.caseHapticImpactHeavy' => '重度震动',
			'devGallery.caseHapticSuccess' => '成功',
			'devGallery.caseHapticWarning' => '警告',
			'devGallery.caseHapticError' => '错误',
			'devGallery.screenSkeleton' => '骨架加载',
			'devGallery.caseSkeletonStatic' => '静态（减少动态效果）',
			'devGallery.caseSkeletonShimmer' => '微光',
			'devGallery.screenOtpMfa' => 'MFA 验证',
			'devGallery.caseCountdown' => '倒计时',
			'devGallery.screenNotifications' => '通知',
			'devGallery.caseNotificationsNotRequested' => '权限说明',
			'devGallery.caseNotificationsGranted' => '已授予',
			'devGallery.caseNotificationsDenied' => '已阻止',
			'devGallery.screenPermissions' => '权限',
			'devGallery.casePermissionRationale' => '说明',
			'devGallery.casePermissionDenied' => '已拒绝',
			'devGallery.casePermissionPermanentlyDenied' => '永久拒绝',
			'devGallery.screenLicense' => '许可证',
			'devGallery.screenShare' => '分享面板',
			'devGallery.screenAppUpdate' => '应用内更新',
			'devGallery.screenSearchPagination' => '搜索与分页',
			'devGallery.caseSearchField' => '搜索框',
			'devGallery.caseSearchPaged' => '分页列表',
			'devGallery.caseSearchPagedNoBackend' => '分页列表（无后端）',
			'devGallery.screenToastDialogs' => '提示与对话框',
			'devGallery.caseToastSuccess' => '成功提示',
			'devGallery.caseToastInfo' => '信息提示',
			'devGallery.caseToastWarning' => '警告提示',
			'devGallery.caseToastError' => '错误提示',
			'devGallery.caseDialogConfirm' => '确认对话框',
			'devGallery.caseDialogDestroy' => '删除对话框',
			'devGallery.screenPasscodeEntry' => '密码输入',
			'devGallery.screenPasscodeSetup' => '密码设置',
			'devGallery.casePasscodeIdle' => '空闲',
			'devGallery.casePasscodeError' => '错误',
			'devGallery.casePasscodeLockedOut' => '已锁定',
			'devGallery.casePasscodeSetupMismatch' => '确认不匹配',
			'devGallery.screenFeedback' => '反馈',
			'devGallery.caseFeedbackDrafting' => '编写中',
			'devGallery.caseFeedbackSubmitting' => '提交中',
			'devGallery.caseFeedbackFailed' => '失败',
			_ => null,
		} ?? switch (path) {
			'devGallery.caseFeedbackSuccess' => '成功',
			'notifications.enableTitle' => '开启通知',
			'notifications.enableBody' => '及时获取账户和活动的更新。你可以随时更改此设置。',
			'notifications.deny' => '暂不',
			'notifications.allow' => '允许',
			'notifications.enableBlockedTitle' => '通知已被阻止',
			'notifications.enableBlockedBody' => '打开系统设置以允许此应用接收通知。',
			'notifications.disabled' => '此模板中通知未连接。',
			'permission.camera.title' => '相机访问',
			'permission.camera.rationale' => '我们使用相机拍摄新的个人头像照片。您可以随时拒绝。',
			'permission.photos.title' => '照片库访问',
			'permission.photos.rationale' => '我们读取您的照片库以便选择个人头像。您可以随时拒绝。',
			'permission.location.title' => '位置访问',
			'permission.location.rationale' => '我们使用您的位置来个性化您的体验。您可以随时拒绝。',
			'permission.continueRequest' => '继续',
			'permission.notNow' => '暂不',
			'permission.openSettings' => '打开设置',
			'permission.denied' => '权限已被拒绝。您可以随时重试。',
			'permission.permanentlyDenied' => '权限已被阻止。请在系统设置中开启以继续。',
			'share.success' => '已分享',
			'share.unavailable' => '此设备不支持分享。',
			'share.cancelled' => '已取消分享。',
			'update.checkForUpdates' => '检查更新',
			'update.available' => '有可用更新。',
			'update.notAvailable' => '已是最新版本。',
			'update.required' => '需要更新才能继续。',
			'search.title' => '搜索',
			'search.placeholder' => '搜索…',
			'search.emptyTitle' => '暂无结果',
			'search.emptyBody' => '请尝试其他搜索词。',
			'search.errorTitle' => '搜索暂不可用',
			'feedback.title' => '发送反馈',
			'feedback.messageLabel' => '内容',
			'feedback.messageHint' => '发生了什么，或有什么可以改进？',
			'feedback.includeScreenshot' => '附上截图',
			'feedback.emailOptional' => '回复邮箱',
			'feedback.submit' => '发送',
			'feedback.cancel' => '取消',
			'feedback.successTitle' => '谢谢！',
			'feedback.successBody' => '您的反馈已发送。',
			'feedback.failedTitle' => '暂时无法发送您的反馈。',
			'feedback.shakeEnabled' => '摇动以打开反馈',
			_ => null,
		};
	}
}
