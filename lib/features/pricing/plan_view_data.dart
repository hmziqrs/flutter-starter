import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:starter/i18n/translations.g.dart';

part 'plan_view_data.freezed.dart';

abstract final class PlanIds {
  static const basic = 'basic';
  static const pro = 'pro';
  static const team = 'team';
}

enum BillingPeriod { monthly, annual }

enum PricingAvailability { available, unavailable }

typedef PlanSelectionCallback = void Function(PlanViewData plan, BillingPeriod billingPeriod);

@freezed
class PlanViewData with _$PlanViewData {
  PlanViewData({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.currencyCode,
    required List<String> benefits,
    this.isRecommended = false,
    this.isCurrent = false,
    this.availability = PricingAvailability.available,
  }) : assert(id != '', 'A plan ID cannot be empty.'),
       assert(monthlyPrice >= 0, 'A monthly price cannot be negative.'),
       assert(annualPrice >= 0, 'An annual price cannot be negative.'),
       assert(currencyCode.length == 3, 'Use an ISO 4217 currency code.'),
       benefits = List.unmodifiable(benefits);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final num monthlyPrice;
  @override
  final num annualPrice;
  @override
  final String currencyCode;
  @override
  final List<String> benefits;
  @override
  final bool isRecommended;
  @override
  final bool isCurrent;
  @override
  final PricingAvailability availability;

  num priceFor(BillingPeriod period) => switch (period) {
    BillingPeriod.monthly => monthlyPrice,
    BillingPeriod.annual => annualPrice,
  };

  String formattedPrice(BillingPeriod period, {required String locale}) {
    return NumberFormat.simpleCurrency(name: currencyCode, locale: locale).format(priceFor(period));
  }
}

abstract final class PricingFixtures {
  static List<PlanViewData> standard(Translations translations) => [
    PlanViewData(
      id: PlanIds.basic,
      name: translations.pricing.plans.basicName,
      description: translations.pricing.plans.basicDescription,
      monthlyPrice: 8,
      annualPrice: 80,
      currencyCode: 'USD',
      benefits: [
        translations.pricing.plans.basicBenefitOne,
        translations.pricing.plans.basicBenefitTwo,
        translations.pricing.plans.basicBenefitThree,
      ],
      isCurrent: true,
    ),
    PlanViewData(
      id: PlanIds.pro,
      name: translations.pricing.plans.proName,
      description: translations.pricing.plans.proDescription,
      monthlyPrice: 18,
      annualPrice: 180,
      currencyCode: 'USD',
      benefits: [
        translations.pricing.plans.proBenefitOne,
        translations.pricing.plans.proBenefitTwo,
        translations.pricing.plans.proBenefitThree,
      ],
      isRecommended: true,
    ),
    PlanViewData(
      id: PlanIds.team,
      name: translations.pricing.plans.teamName,
      description: translations.pricing.plans.teamDescription,
      monthlyPrice: 32,
      annualPrice: 320,
      currencyCode: 'USD',
      benefits: [
        translations.pricing.plans.teamBenefitOne,
        translations.pricing.plans.teamBenefitTwo,
        translations.pricing.plans.teamBenefitThree,
      ],
    ),
  ];

  static List<PlanViewData> unavailable(Translations translations) {
    return [
      for (final plan in standard(translations))
        PlanViewData(
          id: plan.id,
          name: plan.name,
          description: plan.description,
          monthlyPrice: plan.monthlyPrice,
          annualPrice: plan.annualPrice,
          currencyCode: plan.currencyCode,
          benefits: plan.benefits,
          isRecommended: plan.isRecommended,
          isCurrent: plan.isCurrent,
          availability: PricingAvailability.unavailable,
        ),
    ];
  }
}

bool hasUniquePlanIds(List<PlanViewData> plans) =>
    plans.map((plan) => plan.id).toSet().length == plans.length;

PlanViewData preferredPlan(List<PlanViewData> plans) {
  final available = plans.where((plan) => plan.availability == PricingAvailability.available);
  return available.where((plan) => plan.isRecommended).firstOrNull ??
      available.firstOrNull ??
      plans.where((plan) => plan.isRecommended).firstOrNull ??
      plans.first;
}
