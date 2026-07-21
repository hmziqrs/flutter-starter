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
	@override late final _Translations$navigation$zh_Hans navigation = _Translations$navigation$zh_Hans._(_root);
	@override late final _Translations$onboarding$zh_Hans onboarding = _Translations$onboarding$zh_Hans._(_root);
	@override late final _Translations$pricing$zh_Hans pricing = _Translations$pricing$zh_Hans._(_root);
	@override late final _Translations$home$zh_Hans home = _Translations$home$zh_Hans._(_root);
	@override late final _Translations$settings$zh_Hans settings = _Translations$settings$zh_Hans._(_root);
	@override late final _Translations$auth$zh_Hans auth = _Translations$auth$zh_Hans._(_root);
	@override late final _Translations$profile$zh_Hans profile = _Translations$profile$zh_Hans._(_root);
	@override late final _Translations$validation$zh_Hans validation = _Translations$validation$zh_Hans._(_root);
	@override late final _Translations$routeError$zh_Hans routeError = _Translations$routeError$zh_Hans._(_root);
	@override late final _Translations$startupFailure$zh_Hans startupFailure = _Translations$startupFailure$zh_Hans._(_root);
	@override late final _Translations$diagnostics$zh_Hans diagnostics = _Translations$diagnostics$zh_Hans._(_root);
	@override late final _Translations$devGallery$zh_Hans devGallery = _Translations$devGallery$zh_Hans._(_root);
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
	@override String get notConnected => '此操作尚未连接。';
	@override String get legalPlaceholderTitle => '信息预览';
	@override String get legalPlaceholderBody => '在产品专属法律文本获批前，此模板会显示明确且可复现的占位内容。';
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
	@override String get locale => '语言区域';
	@override String get capabilities => '平台能力';
	@override String get redactedNotice => '诊断信息不包含凭据或用户内容。';
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
	@override String get screenSystem => '系统界面';
	@override String get screenOverlays => '浮层';
	@override String get caseDefault => '默认';
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
	@override String get caseNotFound => '请求的图库用例未注册。';
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
			'common.notConnected' => '此操作尚未连接。',
			'common.legalPlaceholderTitle' => '信息预览',
			'common.legalPlaceholderBody' => '在产品专属法律文本获批前，此模板会显示明确且可复现的占位内容。',
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
			'diagnostics.locale' => '语言区域',
			'diagnostics.capabilities' => '平台能力',
			'diagnostics.redactedNotice' => '诊断信息不包含凭据或用户内容。',
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
			'devGallery.screenSystem' => '系统界面',
			'devGallery.screenOverlays' => '浮层',
			'devGallery.caseDefault' => '默认',
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
			'devGallery.caseNotFound' => '请求的图库用例未注册。',
			_ => null,
		};
	}
}
