import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/models/subscription_model.dart';

void main() {
  group('SubscriptionPlanModel.plans', () {
    test('defines exactly one model per SubscriptionPlan value, in enum order', () {
      expect(SubscriptionPlanModel.plans.map((p) => p.plan).toList(), [
        SubscriptionPlan.free,
        SubscriptionPlan.pro,
        SubscriptionPlan.ultra,
        SubscriptionPlan.vip,
      ]);
    });

    test('the free plan has no price and no AI request limit beyond its quota', () {
      final free = SubscriptionPlanModel.plans.firstWhere((p) => p.plan == SubscriptionPlan.free);

      expect(free.price, '0');
      expect(free.aiCallsPerDay, greaterThan(0));
      expect(free.hasCallCenter, isFalse);
      expect(free.hasBookkeeping, isFalse);
    });

    test('paid plans have non-zero prices and unlock premium features progressively', () {
      final paidPlans = SubscriptionPlanModel.plans.where((p) => p.plan != SubscriptionPlan.free);

      for (final plan in paidPlans) {
        expect(plan.price, isNot('0'), reason: '${plan.name} should not be free');
        expect(plan.features, isNotEmpty);
      }

      final vip = SubscriptionPlanModel.plans.firstWhere((p) => p.plan == SubscriptionPlan.vip);
      expect(vip.hasCallCenter, isTrue);
      expect(vip.hasBookkeeping, isTrue);
      expect(vip.hasOfflineMode, isTrue);
      expect(vip.lockedFeatures, isEmpty, reason: 'the top plan should not lock any feature');
    });

    test('aiCallsPerDay is non-decreasing as plans get more expensive (or unlimited)', () {
      int? previous;
      for (final plan in SubscriptionPlanModel.plans) {
        final calls = plan.aiCallsPerDay;
        if (previous != null && previous != -1 && calls != -1) {
          expect(calls, greaterThanOrEqualTo(previous),
              reason: '${plan.name} should not offer fewer daily AI calls than the previous plan');
        }
        previous = calls;
      }
    });
  });
}
