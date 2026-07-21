import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/pricing/plan_view_data.dart';
import 'package:starter/i18n/translations.g.dart';

void main() {
  test('plan identifiers are stable and distinct', () {
    expect(PlanIds.basic, 'basic');
    expect(PlanIds.pro, 'pro');
    expect(PlanIds.team, 'team');
    expect({PlanIds.basic, PlanIds.pro, PlanIds.team}, hasLength(3));
  });

  test('formats numeric monthly and annual prices with the requested currency', () {
    final plan = PlanViewData(
      id: PlanIds.pro,
      name: 'Pro',
      description: 'Description',
      monthlyPrice: 18,
      annualPrice: 180,
      currencyCode: 'USD',
      benefits: const ['One'],
    );

    expect(plan.priceFor(BillingPeriod.monthly), 18);
    expect(plan.priceFor(BillingPeriod.annual), 180);
    expect(plan.formattedPrice(BillingPeriod.monthly, locale: 'en'), contains(r'$'));
    expect(plan.formattedPrice(BillingPeriod.annual, locale: 'en'), contains('180'));
  });

  test('fixtures cover recommended and unavailable presentation states', () {
    final translations = AppLocale.en.buildSync();
    final standard = PricingFixtures.standard(translations);
    final unavailable = PricingFixtures.unavailable(translations);

    expect(standard.map((plan) => plan.id), [PlanIds.basic, PlanIds.pro, PlanIds.team]);
    expect(standard.singleWhere((plan) => plan.id == PlanIds.pro).isRecommended, isTrue);
    expect(
      unavailable.every((plan) => plan.availability == PricingAvailability.unavailable),
      isTrue,
    );
  });
}
