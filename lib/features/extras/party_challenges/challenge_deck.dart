import 'dart:math';

enum ChallengeKind {
  acting('اجرای بامزه'),
  imagination('خیال‌پردازی'),
  together('همه با هم');

  const ChallengeKind(this.label);
  final String label;
}

class PartyChallenge {
  const PartyChallenge(
    this.id,
    this.kind,
    this.title,
    this.instruction, {
    this.seconds = 30,
  });
  final String id, title, instruction;
  final ChallengeKind kind;
  final int seconds;
}

/// No repeats in the selected pool until that pool is exhausted. Switching a
/// filter retains seen cards; a reshuffle avoids an immediate repeat.
class ChallengeDeck {
  ChallengeDeck({Random? random}) : _random = random ?? Random();
  final Random _random;
  final Set<String> _seen = {};
  String? _previous;
  bool reshuffled = false;

  PartyChallenge draw([ChallengeKind? kind]) {
    final pool = challenges
        .where((c) => kind == null || c.kind == kind)
        .toList();
    var available = pool.where((c) => !_seen.contains(c.id)).toList();
    reshuffled = available.isEmpty;
    if (reshuffled) {
      _seen.removeAll(pool.map((c) => c.id));
      available = List.of(pool);
    }
    if (available.length > 1) available.removeWhere((c) => c.id == _previous);
    final card = available[_random.nextInt(available.length)];
    _seen.add(card.id);
    _previous = card.id;
    return card;
  }
}

const challenges = [
  PartyChallenge(
    'a1',
    ChallengeKind.acting,
    'گزارشگرِ اتفاق معمولی',
    'یک نفر آب خوردن را مثل گزارشگرِ فینال جام جهانی گزارش کند!',
  ),
  PartyChallenge(
    'a2',
    ChallengeKind.acting,
    'رباتِ مهمان',
    'مثل یک ربات تازه‌کار خودت را به جمع معرفی کن؛ بقیه اسم ربات را انتخاب کنند.',
  ),
  PartyChallenge(
    'a3',
    ChallengeKind.acting,
    'تبلیغِ جوراب',
    'برای یک جوراب خیالی، پرهیجان‌ترین تبلیغ دنیا را اجرا کن.',
  ),
  PartyChallenge(
    'a4',
    ChallengeKind.acting,
    'آشپزِ بی‌کلام',
    'بدون حرف زدن یک غذای خیالی بپز؛ جمع حدس بزند چه غذایی بود.',
  ),
  PartyChallenge(
    'a5',
    ChallengeKind.acting,
    'هواشناسیِ عجیب',
    'هواشناس شو و بارش پاستا و وزش بادِ شکلاتی را گزارش کن.',
  ),
  PartyChallenge(
    'a6',
    ChallengeKind.acting,
    'سه مدل سلام',
    'سه بار به جمع سلام کن: مثل فضانورد، پادشاه و یک گربهٔ خیلی جدی!',
  ),
  PartyChallenge(
    'a7',
    ChallengeKind.acting,
    'فیلمِ حرکت آهسته',
    'پیدا کردن کنترل تلویزیون را در حرکت آهسته و با پایان قهرمانانه اجرا کن.',
  ),
  PartyChallenge(
    'a8',
    ChallengeKind.acting,
    'گفت‌وگو با بالش',
    'یک نفر خبرنگار شود و با یک بالشِ خیالی دربارهٔ شغلش گفت‌وگو کند.',
  ),
  PartyChallenge(
    'i1',
    ChallengeKind.imagination,
    'اختراعِ بی‌مصرف',
    'وسیله‌ای اختراع کن که یک مشکل خیلی کوچک را به عجیب‌ترین شکل حل کند.',
  ),
  PartyChallenge(
    'i2',
    ChallengeKind.imagination,
    'اسمِ گروه ما',
    'برای این جمع یک اسم و یک شعار بامزه پیشنهاد بده؛ با رأی جمع انتخابش کنید.',
  ),
  PartyChallenge(
    'i3',
    ChallengeKind.imagination,
    'اگر یخچال حرف می‌زد',
    'از زبان یک یخچال بگو بزرگ‌ترین آرزویت چیست.',
  ),
  PartyChallenge(
    'i4',
    ChallengeKind.imagination,
    'ابرقدرتِ کوچولو',
    'یک ابرقدرت خیلی معمولی برای خودت انتخاب کن و کاربردش را توضیح بده.',
  ),
  PartyChallenge(
    'i5',
    ChallengeKind.imagination,
    'سیارهٔ پیتزا',
    'سه قانون برای زندگی در سیاره‌ای بگو که همه‌چیزش از پیتزاست.',
  ),
  PartyChallenge(
    'i6',
    ChallengeKind.imagination,
    'پوسترِ فیلمِ امشب',
    'اگر این دورهمی یک فیلم سینمایی بود، عنوانش و جملهٔ روی پوسترش چه بود؟',
  ),
  PartyChallenge(
    'i7',
    ChallengeKind.imagination,
    'مدرسهٔ اژدهاها',
    'معلم اژدهاها شده‌ای! اولین درس امروز را برای جمع توضیح بده.',
  ),
  PartyChallenge(
    'i8',
    ChallengeKind.imagination,
    'فروشگاهِ ابرها',
    'سه نوع ابر برای فروش معرفی کن و برای هر کدام یک کاربرد بامزه بگو.',
  ),
  PartyChallenge(
    't1',
    ChallengeKind.together,
    'داستان زنجیره‌ای',
    'یک داستان بسازید؛ هر نفر فقط یک کلمه اضافه کند. شروع داستان: «امشب...»',
  ),
  PartyChallenge(
    't2',
    ChallengeKind.together,
    'ارکسترِ دورهمی',
    'هر نفر یک صدای کوتاه انتخاب کند؛ یک نفر رهبر شود و ارکستر را هدایت کند.',
  ),
  PartyChallenge(
    't3',
    ChallengeKind.together,
    'مصاحبهٔ دونفره',
    'دو نفر یک شخصیت باشند: یکی فقط حرکت کند و دیگری به جایش حرف بزند.',
  ),
  PartyChallenge(
    't4',
    ChallengeKind.together,
    'مجسمه‌های خندان',
    'هر کس یک ژست بامزه و راحت بگیرد؛ با شمارش سه، همه مجسمه شوند!',
  ),
  PartyChallenge(
    't5',
    ChallengeKind.together,
    'سفرِ خیالی',
    'هر نفر یک چیز عجیب به چمدان سفر جمع اضافه کند و دلیلش را بگوید.',
  ),
  PartyChallenge(
    't6',
    ChallengeKind.together,
    'شعارِ قهرمانی',
    'با کمک همه، یک شعار کوتاه برای تیم خیالی جمع بسازید و با هم بخوانید.',
  ),
  PartyChallenge(
    't7',
    ChallengeKind.together,
    'ماشینِ صداها',
    'نفر اول یک ریتم یا صدای جالب بسازد؛ نفر بعد آن را تکرار کند و یک نوای تازه اضافه کند.',
  ),
  PartyChallenge(
    't8',
    ChallengeKind.together,
    'قصه در سه جمله',
    'سه نفر به‌ترتیب شروع، دردسر و پایان یک ماجرای خنده‌دار را هر کدام در یک جمله بگویند.',
  ),
];
