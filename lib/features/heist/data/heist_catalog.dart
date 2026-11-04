import '../domain/heist_models.dart';

class HeistCatalog {
  static const roles = [
    HeistRole(
      id: 'mastermind',
      title: 'مغز متفکر',
      ability: 'دو امتیاز فوری به قدرت عملیات اضافه می‌کند.',
      strength: 'برنامه‌ریزی و کنترل بحران',
      weakness: 'در برداشت مخفیانه سریع‌تر مشکوک می‌شود.',
      objective: 'در یک عملیات کاملاً با گروه همکاری کن.',
      objectiveAction: HeistSecretAction.cooperate,
      specialty: HeistApproach.stealth,
      atlasIndex: 0,
    ),
    HeistRole(
      id: 'hacker',
      title: 'هکر',
      ability: 'یک درجه از سطح هشدار امنیتی کم می‌کند.',
      strength: 'دوربین و شبکه امنیتی',
      weakness: 'در ورود فنی مزیتی ندارد.',
      objective: 'توانایی هک اختصاصی را در لحظه مناسب فعال کن.',
      objectiveAction: HeistSecretAction.ability,
      specialty: HeistApproach.technology,
      atlasIndex: 1,
    ),
    HeistRole(
      id: 'driver',
      title: 'راننده فرار',
      ability: 'دو درجه از آژیر عملیات کم می‌کند.',
      strength: 'مسیر فرار و واکنش سریع',
      weakness: 'سهم پنهانی او آسان‌تر ردیابی می‌شود.',
      objective: 'از غنیمت گروه محافظت کن تا فرار امن بماند.',
      objectiveAction: HeistSecretAction.protect,
      specialty: HeistApproach.force,
      atlasIndex: 2,
    ),
    HeistRole(
      id: 'safecracker',
      title: 'متخصص گاوصندوق',
      ability: '10٪ غنیمت اضافه از خزانه آزاد می‌کند.',
      strength: 'قفل و ورود فنی',
      weakness: 'مذاکره‌کننده ضعیفی است.',
      objective: 'توانایی گاوصندوق را برای غنیمت اضافه مصرف کن.',
      objectiveAction: HeistSecretAction.ability,
      specialty: HeistApproach.force,
      atlasIndex: 3,
    ),
    HeistRole(
      id: 'forger',
      title: 'جاعل',
      ability: 'یک رد امنیتی را پاک و ظن خودش را صفر می‌کند.',
      strength: 'هویت جعلی و عبور اجتماعی',
      weakness: 'ابزار الکترونیکی برایش پرریسک است.',
      objective: 'یک عملیات را بدون خیانت به پایان برسان.',
      objectiveAction: HeistSecretAction.cooperate,
      specialty: HeistApproach.social,
      atlasIndex: 4,
    ),
    HeistRole(
      id: 'infiltrator',
      title: 'نفوذی',
      ability: 'یک برداشت حرفه‌ای کوچک با ظن کمتر انجام می‌دهد.',
      strength: 'نفوذ و بلوف',
      weakness: 'اگر لو برود جریمه بیشتری می‌پردازد.',
      objective: 'یک سهم مخفی بردار و بدون شناسایی خارج شو.',
      objectiveAction: HeistSecretAction.steal,
      specialty: HeistApproach.stealth,
      atlasIndex: 5,
    ),
    HeistRole(
      id: 'security',
      title: 'متخصص امنیت',
      ability: 'یک درجه از هشدار بانک را با دسترسی امنیتی پاک می‌کند.',
      strength: 'کشف خرابکاری و محافظت',
      weakness: 'سهم مخفی او تقریباً همیشه کشف می‌شود.',
      objective: 'یک بار از غنیمت گروه محافظت کن.',
      objectiveAction: HeistSecretAction.protect,
      specialty: HeistApproach.technology,
      atlasIndex: 6,
    ),
    HeistRole(
      id: 'negotiator',
      title: 'مذاکره‌کننده',
      ability: '300 پول شخصی می‌گیرد؛ رأی موافق او تساوی را هم می‌شکند.',
      strength: 'تقسیم غنیمت و مهندسی اجتماعی',
      weakness: 'توان فنی محدودی دارد.',
      objective: 'توانایی مذاکره را پیش از تقسیم فعال کن.',
      objectiveAction: HeistSecretAction.ability,
      specialty: HeistApproach.social,
      atlasIndex: 7,
    ),
  ];

  static const banks = [
    HeistBank(
      id: 'central',
      title: 'بانک مرکزی',
      security: 3,
      baseLoot: 16000,
      description: 'لابی عظیم، دوربین‌های متراکم و نگهبان‌های منظم.',
      atlasIndex: 0,
    ),
    HeistBank(
      id: 'golden',
      title: 'خزانه طلایی',
      security: 4,
      baseLoot: 24000,
      description: 'بیشترین طلا؛ قفل مکانیکی چندلایه و حسگر وزن.',
      atlasIndex: 1,
    ),
    HeistBank(
      id: 'private',
      title: 'بانک خصوصی',
      security: 2,
      baseLoot: 13000,
      description: 'کارمندهای کم، مشتری‌های مهم و هویت‌سنجی سخت.',
      atlasIndex: 2,
    ),
    HeistBank(
      id: 'underground',
      title: 'خزانه زیرزمینی',
      security: 5,
      baseLoot: 30000,
      description: 'تونل‌های بتنی، درهای فولادی و تنها یک مسیر خروج.',
      atlasIndex: 3,
    ),
    HeistBank(
      id: 'tower',
      title: 'برج مالی',
      security: 4,
      baseLoot: 26000,
      description: 'شبکه هوشمند، آسانسورهای قفل‌شونده و فرار در ارتفاع.',
      atlasIndex: 4,
    ),
  ];

  static const equipment = <String, String>{
    'signal': 'مختل‌کننده سیگنال؛ مناسب دوربین و آژیر',
    'thermal': 'دریل حرارتی؛ مناسب قفل و در فولادی',
    'uniform': 'لباس خدمات؛ مناسب نفوذ اجتماعی',
    'drone': 'پهپاد شناسایی؛ کاهش خطر مسیر فرار',
    'decoy': 'کیف طعمه؛ محافظت از بخشی از غنیمت',
    'emp': 'پالس محدود؛ نجات اضطراری تجهیزات',
  };

  static const _eventSeeds = [
    (
      'camera',
      'چشم قرمز',
      'دوربین امنیتی مسیر اصلی را اسکن می‌کند.',
      HeistApproach.technology,
      0,
    ),
    (
      'lock',
      'قفل لجوج',
      'چرخ‌دنده گاوصندوق در آخرین مرحله گیر کرده است.',
      HeistApproach.force,
      1,
    ),
    (
      'alarm',
      'آژیر خاموش',
      'شمارش معکوس بی‌صدا در اتاق کنترل آغاز شده است.',
      HeistApproach.stealth,
      2,
    ),
    (
      'gear',
      'ابزار سوخته',
      'تجهیز اصلی داغ کرده و از مدار خارج شده است.',
      HeistApproach.technology,
      3,
    ),
    (
      'exit',
      'خروجی بسته',
      'در ضدحریق مسیر فرار را مسدود کرده است.',
      HeistApproach.social,
      4,
    ),
    (
      'bonus',
      'جعبه بی‌نام',
      'یک محموله طلای ثبت‌نشده کنار مسیر دیده می‌شود.',
      HeistApproach.stealth,
      5,
    ),
    (
      'guard',
      'تعویض شیفت',
      'نگهبان زودتر از برنامه وارد راهرو شده است.',
      HeistApproach.social,
      0,
    ),
    (
      'sensor',
      'حسگر وزن',
      'برداشتن شمش‌ها کف خزانه را فعال می‌کند.',
      HeistApproach.force,
      1,
    ),
    (
      'trace',
      'رد دیجیتال',
      'شبکه در حال ثبت شناسه دستگاه هکر است.',
      HeistApproach.technology,
      2,
    ),
    (
      'hostage',
      'مدیر شب',
      'مدیر بانک پشت در امن منتظر تأیید هویت است.',
      HeistApproach.social,
      3,
    ),
  ];

  /// Thirty distinct cards; all are drawn by the engine without replacement.
  static final List<HeistEvent> events = [
    for (var round = 0; round < 3; round++)
      for (var index = 0; index < _eventSeeds.length; index++)
        HeistEvent(
          id: '${_eventSeeds[index].$1}_${round + 1}',
          title: '${_eventSeeds[index].$2} ${['اول', 'دوم', 'نهایی'][round]}',
          description: _eventSeeds[index].$3,
          bestApproach: _eventSeeds[index].$4,
          danger: 1 + ((index + round) % 3),
          reward: 800 + (index % 4) * 350 + round * 250,
          artIndex: _eventSeeds[index].$5,
        ),
  ];

  static HeistRole role(String id) => roles.firstWhere((role) => role.id == id);
  static HeistBank bank(String id) => banks.firstWhere((bank) => bank.id == id);
  static HeistEvent event(String id) =>
      events.firstWhere((event) => event.id == id);
}
