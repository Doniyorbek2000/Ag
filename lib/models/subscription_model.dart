enum SubscriptionPlan { free, pro, ultra, vip }

class PlanFeature {
  final String title;
  final bool available;

  const PlanFeature({required this.title, required this.available});
}

class SubscriptionPlanModel {
  final SubscriptionPlan plan;
  final String name;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final List<String> lockedFeatures;
  final int aiCallsPerDay;
  final int maxApps;
  final bool hasVoiceControl;
  final bool hasCallCenter;
  final bool hasBookkeeping;
  final bool hasPrioritySupport;
  final bool hasOfflineMode;
  final bool hasCustomVoice;
  final bool hasAdvancedAutomation;

  const SubscriptionPlanModel({
    required this.plan,
    required this.name,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.lockedFeatures,
    required this.aiCallsPerDay,
    required this.maxApps,
    required this.hasVoiceControl,
    required this.hasCallCenter,
    required this.hasBookkeeping,
    required this.hasPrioritySupport,
    required this.hasOfflineMode,
    required this.hasCustomVoice,
    required this.hasAdvancedAutomation,
  });

  static const List<SubscriptionPlanModel> plans = [
    SubscriptionPlanModel(
      plan: SubscriptionPlan.free,
      name: 'Bepul',
      price: '0',
      period: 'Doimo',
      description: 'Asosiy AI yordamchi funksiyalari',
      features: [
        'Kunlik 20 ta AI so\'rov',
        'Ovozli boshqarish (asosiy)',
        '5 ta ilova integratsiyasi',
        'Matn chat',
        'Asosiy eslatmalar',
      ],
      lockedFeatures: [
        'Cheksiz AI so\'rovlar',
        'Call Center',
        'Buxgalteriya',
        'Offline rejim',
        'Maxsus ovoz',
        'Kengaytirilgan avtomatlashtirish',
      ],
      aiCallsPerDay: 20,
      maxApps: 5,
      hasVoiceControl: true,
      hasCallCenter: false,
      hasBookkeeping: false,
      hasPrioritySupport: false,
      hasOfflineMode: false,
      hasCustomVoice: false,
      hasAdvancedAutomation: false,
    ),
    SubscriptionPlanModel(
      plan: SubscriptionPlan.pro,
      name: 'Pro',
      price: '29 900',
      period: 'oyiga',
      description: 'Professional foydalanuvchilar uchun',
      features: [
        'Kunlik 200 ta AI so\'rov',
        'Kengaytirilgan ovozli boshqarish',
        '15 ta ilova integratsiyasi',
        'Call Center (asosiy)',
        'Buxgalteriya moduli',
        'Ustuvor qo\'llab-quvvatlash',
        'Tarix eksporti',
      ],
      lockedFeatures: [
        'Cheksiz AI so\'rovlar',
        'Offline rejim',
        'Maxsus ovoz klonlash',
        'API kirish',
      ],
      aiCallsPerDay: 200,
      maxApps: 15,
      hasVoiceControl: true,
      hasCallCenter: true,
      hasBookkeeping: true,
      hasPrioritySupport: true,
      hasOfflineMode: false,
      hasCustomVoice: false,
      hasAdvancedAutomation: false,
    ),
    SubscriptionPlanModel(
      plan: SubscriptionPlan.ultra,
      name: 'Ultra',
      price: '59 900',
      period: 'oyiga',
      description: 'Biznes va kuch foydalanuvchilar uchun',
      features: [
        'Cheksiz AI so\'rovlar',
        'To\'liq ovozli boshqarish',
        'Barcha ilovalar integratsiyasi',
        'To\'liq Call Center',
        'Kengaytirilgan buxgalteriya',
        'Offline rejim',
        'Maxsus ovoz',
        'Avtomatlashtirish skriptlari',
        'API kirish',
        '24/7 qo\'llab-quvvatlash',
      ],
      lockedFeatures: [
        'Shaxsiy AI modeli',
        'Korporativ panel',
      ],
      aiCallsPerDay: -1,
      maxApps: -1,
      hasVoiceControl: true,
      hasCallCenter: true,
      hasBookkeeping: true,
      hasPrioritySupport: true,
      hasOfflineMode: true,
      hasCustomVoice: true,
      hasAdvancedAutomation: true,
    ),
    SubscriptionPlanModel(
      plan: SubscriptionPlan.vip,
      name: 'VIP',
      price: '149 900',
      period: 'oyiga',
      description: 'Cheksiz imkoniyatlar va shaxsiy xizmat',
      features: [
        'Hamma Ultra imkoniyatlar',
        'Shaxsiy AI modeli (fine-tuned)',
        'Korporativ boshqaruv paneli',
        'Bir nechta qurilma sinxronizatsiyasi',
        'White-label variant',
        'Maxsus integratsiyalar',
        'Shaxsiy menejer',
        'SLA kafolati',
        'Beta funksiyalarga erta kirish',
      ],
      lockedFeatures: [],
      aiCallsPerDay: -1,
      maxApps: -1,
      hasVoiceControl: true,
      hasCallCenter: true,
      hasBookkeeping: true,
      hasPrioritySupport: true,
      hasOfflineMode: true,
      hasCustomVoice: true,
      hasAdvancedAutomation: true,
    ),
  ];
}
