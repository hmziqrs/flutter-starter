import 'package:starter/app/routing/otp_purpose.dart';

abstract final class AppRoutes {
  static const onboarding = 'onboarding';
  static const onboardingPath = '/onboarding';
  static const onboardingPaywall = 'onboarding-paywall';
  static const onboardingPaywallPath = '/onboarding/paywall';

  static const splash = 'splash';
  static const splashPath = '/splash';

  static const home = 'home';
  static const homePath = '/';
  static const settings = 'settings';
  static const settingsPath = '/settings';
  static const appearanceSettings = 'appearance-settings';
  static const appearanceSettingsPath = '/settings/appearance';
  static const languageSettings = 'language-settings';
  static const languageSettingsPath = '/settings/language';
  static const accessibilitySettings = 'accessibility-settings';
  static const accessibilitySettingsPath = '/settings/accessibility';
  static const aboutLicense = 'about-license';
  static const aboutLicensePath = '/settings/about/license';

  static const login = 'login';
  static const loginPath = '/auth/login';
  static const register = 'register';
  static const registerPath = '/auth/register';
  static const forgotPassword = 'forgot-password';
  static const forgotPasswordPath = '/auth/forgot-password';
  static const otp = 'otp';
  static const otpPath = '/auth/otp/:purpose';

  static String otpLocation(OtpPurpose purpose) => '/auth/otp/${purpose.pathSegment}';

  static const resetPassword = 'reset-password';
  static const resetPasswordPath = '/auth/reset-password';

  static const forceUpdate = 'force-update';
  static const forceUpdatePath = '/force-update';

  static const biometricLock = 'biometric-lock';
  static const biometricLockPath = '/lock';

  static const updateProfile = 'update-profile';
  static const updateProfilePath = '/profile/edit';
  static const pricing = 'pricing';
  static const pricingPath = '/pricing';

  static const developmentScreens = 'development-screens';
  static const developmentScreensPath = '/dev/screens';
  static const diagnostics = 'diagnostics';
  static const diagnosticsPath = '/dev/diagnostics';
}
