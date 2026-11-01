# سند جامع معماری و برنامه اجرایی بازی «جمعمون جمعه!»
**نسخه:** 1.0.0 (MVP کافه‌بازار)  
**معماری:** Feature-First + MVVM (Cubit / flutter_bloc)  
**پلتفرم:** Flutter (Android Mobile-First, Offline-First, RTL فارسی)

---

## ۱. معماری نهایی و ساختار پوشه‌ها

پروژه به صورت Feature-First ماژولار پیاده‌سازی می‌شود. به این معنا که هر قابلیت (Feature) تمام منطق داده، بیزینس، استیت و UI مربوط به خود را داراست. در عین حال قابلیت‌ها و مؤلفه‌های اشتراکی در پوشه `core` و پیکربندی‌های کلی برنامه در پوشه `app` قرار دارند.

### ساختار درختی پروژه:
```text
lib/
  main.dart                                # نقطه ورود برنامه، راه‌اندازی DI و سرویس‌ها
  app/
    app.dart                               # MaterialApp با پشتیبانی کامل فارسی و RTL
    router.dart                            # مدیریت مسیرها (Named Routes) بدون پیچیدگی اضافی
    di/
      service_locator.dart                 # رجیستر کردن وابستگی‌ها با get_it
    theme/
      app_colors.dart                      # پالت رنگ پرانرژی پارتی گیم (گرادیان‌ها، رنگ‌های تم هر ۵ بازی)
      app_typography.dart                  # استایل‌های فونت و خوانایی متن‌های فارسی
      app_decorations.dart                 # سایه‌ها، گوشه‌های گرد، کادرها و افکت‌های بصری
      app_theme.dart                       # ThemeData سفارشی و تنظیمات یکپارچه

  core/
    constants/
      app_constants.dart                   # ثابت‌های عمومی، زمان‌ها، تنظیمات پیش‌فرض
      assets_constants.dart                # آدرس فایل‌های صوتی و تصاویر
    models/
      team_model.dart                      # مدل تیم و رنگ و آیکون
      player_model.dart                    # مدل بازیکن و لقب‌ها
      game_mode.dart                       # حالت‌های بازی: سریع، تیمی، مسابقه پنجگانه
      power_up_model.dart                  # کارت‌های قدرت (امتیاز ۲ برابر، وقت اضافه و...)
    services/
      storage_service.dart                 # ذخیره‌سازی محلی (SharedPreferences) برای سوابق و تنظیمات
      audio_service.dart                   # پخش افکت‌های صوتی بازی (تیک‌تیک، بوق، انفجار، پیروزی)
      haptics_service.dart                 # بازخورد لرزشی گوشی در لحظات مهیج (انفجار بمب، پایان زمان)
      purchase_service.dart                # رابط استاندارد خرید کافه‌بازار + MockPurchaseService
    widgets/
      party_button.dart                    # دکمه‌های سه‌بعدی و پرانرژی پارتی گیم با انیمیشن لمس
      party_card.dart                      # کارت‌های خوش‌ساخت با گرادیان و سایه مدرن
      party_dialog.dart                    # مودال‌های تایید خروج، پایان دور و راهنما
      pass_phone_overlay.dart              # صفحه انتقال ایمن گوشی بین بازیکنان
      custom_timer_widget.dart             # تایمر دایره‌ای انیمیشنی روان و مستقل
      confetti_overlay.dart                # افکت ذره‌ای شادباش و پرتاب کاغذ رنگی اختصاصی
      animated_party_background.dart       # پس‌زمینه زنده با ذرات شناور و اشکال هندسی مدرن
      how_to_play_sheet.dart               # باتم‌شیت آموزش ساده و کوتاه «چطوری بازی کنیم؟»
    utils/
      sound_effects.dart                   # متدهای کمکی تولید و پخش افکت صدا
      game_rules_data.dart                 # متن راهنما و قوانین اختصاصی هر ۵ بازی

  features/
    splash/
      presentation/
        splash_page.dart                   # انیمیشن استارتاپ پرانرژی و لود داده‌ها
        cubit/splash_cubit.dart
    home/
      presentation/
        home_page.dart                     # منوی اصلی با دسترسی به ۵ بازی، تورنمنت و فروشگاه
        cubit/home_cubit.dart
    teams/
      presentation/
        cubit/teams_cubit.dart             # تعریف تیم‌ها، افزودن بازیکنان و رنگ‌بندی
        pages/teams_setup_page.dart
    taboo/                                 # بازی ۱: حرف نزن، بفهمون!
      data/
        taboo_card_model.dart
        taboo_repository.dart
      presentation/
        cubit/taboo_cubit.dart
        cubit/taboo_state.dart
        pages/taboo_game_page.dart
        widgets/taboo_card_view.dart
    hot_potato/                            # بازی ۲: بمب دست کیه؟
      data/
        hot_potato_topic_model.dart
        hot_potato_repository.dart
      presentation/
        cubit/hot_potato_cubit.dart
        cubit/hot_potato_state.dart
        pages/hot_potato_game_page.dart
        widgets/bomb_animation_view.dart
    charades/                              # بازی ۳: پانتومیم انفجاری
      data/
        charades_word_model.dart
        charades_repository.dart
      presentation/
        cubit/charades_cubit.dart
        cubit/charades_state.dart
        pages/charades_game_page.dart
    five_seconds/                          # بازی ۴: سه‌تا بگو!
      data/
        five_seconds_model.dart
        five_seconds_repository.dart
      presentation/
        cubit/five_seconds_cubit.dart
        cubit/five_seconds_state.dart
        pages/five_seconds_game_page.dart
    drawing/                               # بازی ۵: نقاشی افتضاح!
      data/
        drawing_word_model.dart
        drawing_repository.dart
      presentation/
        cubit/drawing_cubit.dart
        cubit/drawing_state.dart
        pages/drawing_game_page.dart
        widgets/drawing_canvas_view.dart
        widgets/palette_toolbar.dart
    tournament/                            # مسابقه پنجگانه
      data/
        tournament_session_model.dart
      presentation/
        cubit/tournament_cubit.dart
        cubit/tournament_state.dart
        pages/tournament_lobby_page.dart
        pages/tournament_scoreboard_page.dart
        pages/tournament_podium_page.dart
    extras/                                # امکانات تکمیلی جذاب
      lucky_wheel/                         # گردونه شانس
        pages/lucky_wheel_page.dart
      random_picker/                       # انتخاب تصادفی بازیکن
        pages/random_picker_page.dart
      custom_cards/                        # ساخت کارت اختصاصی توسط بازیکن
        pages/custom_cards_page.dart
    shop/                                  # فروشگاه بسته‌های محتوا (Cafe Bazaar Ready)
      data/
        content_pack_model.dart
      presentation/
        cubit/shop_cubit.dart
        cubit/shop_state.dart
        pages/shop_page.dart
    settings/                              # تنظیمات صدا، لرزش و اطلاعات بازی
      presentation/
        cubit/settings_cubit.dart
        pages/settings_page.dart

assets/
  data/
    taboo/pack_free.json                   # کلمات بازی تابو
    hot_potato/pack_free.json              # موضوعات بمب
    charades/pack_free.json                # کلمات پانتومیم
    five_seconds/pack_free.json            # سوالات سه‌تا بگو
    drawing/pack_free.json                 # کلمات نقاشی
  sounds/                                  # فایل‌های صوتی کم‌حجم
```

---

## ۲. فازهای توسعه به ترتیب وابستگی

| فاز | عنوان | وابستگی | وضعیت |
|---|---|---|---|
| **فاز ۰** | بررسی، آماده‌سازی و سند معماری | ندارد | در حال انجام |
| **فاز ۱** | زیرساخت، Design System، تم و هسته سرویس‌ها | فاز ۰ | در انتظار |
| **فاز ۲** | ناوبری، صفحه اصلی، راه‌اندازی تیم و آموزش | فاز ۱ | در انتظار |
| **فاز ۳** | موتور اشتراکی بازی‌ها و سیستم داده محتوا | فاز ۱ و ۲ | در انتظار |
| **فاز ۴** | پیاده‌سازی کامل هر ۵ بازی با UI اختصاصی | فاز ۳ | در انتظار |
| **فاز ۵** | مسابقه پنجگانه (تورنمنت چندمرحله‌ای) | فاز ۴ | در انتظار |
| **فاز ۶** | قابلیت‌های مهیج تکمیلی (گردونه، القاب، کارت سفارشی) | فاز ۴ | در انتظار |
| **فاز ۷** | فروشگاه و سرویس خرید درون‌برنامه‌ای کافه‌بازار | فاز ۱ و ۳ | در انتظار |
| **فاز ۸** | پولیش انیمیشن‌ها، افکت‌های صوتی و گرافیک | فاز ۴، ۵، ۶ | در انتظار |
| **فاز ۹** | تست‌های جامع، بهینه‌سازی، آنالایزر و چک‌لیست انتشار | همه فازها | در انتظار |

---

## ۳. قابلیت‌های دقیق هر فاز

### فاز ۰: بررسی و ساختاربندی اولیه
- تحلیل نیازمندی‌ها و تضمین رعایت تمام قوانین سخت‌گیرانه (عدم استفاده از setState، استقلال ماژول‌ها، معماری بدون سربار)
- راه‌اندازی Git، فایل‌های پیکربندی و ساختار فولدرها
- افزودن نیازمندی‌های pubspec و تایید نصب

### فاز ۱: سیستم طراحی (Design System)، تم و سرویس‌های بنیادین
- پالت رنگی جذاب پارتی گیم با گرادیان‌های اختصاصی ۵ بازی:
  - تابو: سرخ آتشین / نارنجی شاد
  - بمب دست کیه: ذغالی و نئون قرمز / فسفری
  - پانتومیم: بنفش سلطنتی / سرخابی
  - سه‌تا بگو: فیروزه‌ای تند / زرد الکتریک
  - نقاشی افتضاح: سبز لیمویی / آبی آسمانی
- تایپوگرافی تمیز فارسی و چیدمان استاندارد RTL
- کامپوننت دکمه شاداب ۳بعدی (`PartyButton`)، کارت‌های با عمق (`PartyCard`) و پس‌زمینه متحرک
- پیاده‌سازی `StorageService` بر بستر `SharedPreferences`
- پیاده‌سازی `AudioService` و `HapticsService` با کلیدهای روشن/خاموش در تنظیمات
- تزریق وابستگی‌ها با `get_it`

### فاز ۲: ناوبری، تجربه کاربری، ساخت تیم و قوانین
- صفحه اسپلش با لوگوی پرانرژی «جمعمون جمعه!»
- منوی اصلی با کارت‌های بزرگ ۵ مینی‌گیم، دسترسی به حالت سریع، تیمی، مسابقه پنجگانه و گردونه
- سیستم ساخت تیم و تخصیص بازیکنان (`TeamsCubit`)
- سیستم قوانین «چطوری بازی کنیم؟» با نمایش کارت‌های خلاصه و روان
- صفحه تنظیمات با گزینه‌های صدا، لرزش و ریست اطلاعات

### فاز ۳: موتور اشتراکی و مخزن محتوا
- طراحی مدل‌های مشترک `Team`، `Player`، `ScoreRecord` و `TurnManager`
- پیاده‌سازی ویجت تایمر دقیق انیمیشنی با قابلیت Pause/Resume
- سیستم مدیریت نوبت‌های عادلانه بین تیم‌ها
- فایل‌های JSON غنی و کاملاً فارسی در پوشه‌های `assets/data/` با ساختار معتبر
- تست‌های اعتبارسنجی JSON برای اطمینان از عدم وجود آی‌دی‌های تکراری و قالب معتبر

### فاز ۴: پیاده‌سازی کامل و بیزینس ۵ بازی
- **بازی ۱ (حرف نزن، بفهمون! - Taboo):** کلمه اصلی + ۵ کلمه ممنوع، دکمه‌های بزرگ درست / خطا / رد کردن، محاسبه امتیاز مثبت و منفی، تعویض نوبت تیم.
- **بازی ۲ (بمب دست کیه؟ - Hot Potato):** نمایش موضوع چالش، تیک‌تیک تصاعدی بمب با لرزش، زمان انفجار رندوم غیرقابل پیش‌بینی، افکت بوم و انفجار با انیمیشن و صدا، مشخص شدن بازنده دور.
- **بازی ۳ (پانتومیم انفجاری - Charades):** صفحه امن رویت کلمه توسط بازیگر، مخفی شدن کلمه، تایمر هیجان‌انگیز، سختی‌های آسان/متوسط/سخت، امتیازدهی تیمی.
- **بازی ۴ (سه‌تا بگو! - 5 Second Rule):** سوال چالشی، شمارش معکوس ۵ ثانیه‌ای با بوق هماهنگ، دکمه تایید سه پاسخ یا سوختن نوبت.
- **بازی ۵ (نقاشی افتضاح! - Drawing Canvas):** بوم روان رسم انگشتی با ابعاد متغیر خط، پالت رنگ، پاک‌کن، Undo و Clear، تایمر نقاشی و حدس زدن هم‌تیمی.

### فاز ۵: مسابقه پنجگانه (Tournament Mode)
- جریان مسابقه ۵ مرحله‌ای پشت سر هم با حضور تیم‌های ثبت‌شده
- جدول امتیازات پویا و تراز امتیازی عادلانه بعد از پایان هر بازی
- صفحه پرواز کنفتی، معرفی قهرمان و جشن اختتامیه تورنمنت

### فاز ۶: ویژگی‌های تکمیلی مهیج
- **گردونه شانس:** اسپینر دایره‌ای با قوانین ویژه (زمان اضافه، کسر امتیاز، چالش معکوس)
- **کارت‌های قدرت:** قابلیت استفاده از ۲x امتیاز یا شانس مجدد در حین مسابقه
- **انتخاب تصادفی بازیکن:** انیمیشن قرعه‌کشی سریع
- **القاب خنده‌دار پایان بازی:** تولید خودکار لقب بر اساس عملکرد (مثلاً «بمب‌گذار نمونه»، «سلطان سکوت»، «پیکاسو محله»)
- **کارت‌ساز سفارشی:** امکان افزودن کلمات خانوادگی و سوژه‌های دوستانه به مخزن آفلاین

### فاز ۷: فروشگاه و یکپارچه‌سازی پرداخت کافه‌بازار
- معماری `PurchaseService` با متدهای `buyProduct()`, `restorePurchases()`, `isPurchased()`
- `MockPurchaseService` برای محیط توسعه و ساختار آماده اتصال به In-App Billing بازار
- ۶ محصول مشخص: ۵ بسته الحاقی ویژه برای هر بازی + بسته طلایی فصل اول (شامل همه)
- ذخیره‌سازی محلی کلیدهای فعال‌شده برای بازی آفلاین

### فاز ۸: پولیش گرافیکی، صداگذاری و انیمیشن‌ها
- جلوه‌های ذره‌ای کنفتی هنگام برد
- افکت‌های لرزشی سفارشی در لحظات حساس
- صفحات انتقال ایمن گوشی («گوشی رو بده به ...»)
- انیمیشن‌های نرم ورود و خروج المان‌ها (Hero, FadeScale, Slide)

### فاز ۹: تست‌ها، تحلیل کیفیت و آماده‌سازی انتشار
- تست‌های واحد (Unit Tests) برای منطق امتیازدهی، تایمر، گردش نوبت و لودر کلمات
- تست صحت داده‌های JSON با اسکریپت خودکار
- اجرای `flutter analyze` بدون خطای مسدودکننده
- تنظیم نهایی آیکون، نام نمایشی «جمعمون جمعه!» و بررسی خروجی Android

---

## ۴. مدل‌های داده و قراردادهای مشترک

```dart
// Team Model
class Team {
  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final int score;
}

// Player Model
class Player {
  final String id;
  final String name;
  final String? teamId;
  final String? awardedTitle;
}

// Taboo Card
class TabooCard {
  final String id;
  final String word;
  final List<String> forbiddenWords;
  final String category;
  final int difficulty; // 1: Easy, 2: Medium, 3: Hard
}

// Hot Potato Topic
class HotPotatoTopic {
  final String id;
  final String topic;
  final String category;
}

// Charades Word
class CharadesWord {
  final String id;
  final String word;
  final String category;
  final int points;
}

// Five Seconds Question
class FiveSecondsQuestion {
  final String id;
  final String question;
  final String category;
}

// Drawing Word
class DrawingWord {
  final String id;
  final String word;
  final String category;
  final int difficulty;
}
```

---

## ۵. تست‌ها و معیارهای پذیرش (Definition of Done)

برای هر مرحله و در نهایت کل پروژه، معیارهای زیر برقرار خواهند بود:
1. **بدون `setState`:** تمام استیت‌ها از طریق `Cubit` و `BlocBuilder` / `BlocConsumer` مدیریت می‌شوند.
2. **Offline-First:** برنامه بدون نیاز به هیچ اتصال اینترنتی به طور کامل اجرا می‌شود.
3. **پایداری داده:** در صورت بستن و باز کردن مجدد، نام تیم‌ها، تنظیمات صدا و خریدهای قبلی حفظ می‌مانند.
4. **تست خودکار:** تست‌های واحد منطق نوبت، امتیاز و اعتبارسنجی دیتای فارسی با موفقیت پاس می‌شوند.
5. **تایمر مستقل و ضد لگ:** مکانیزم تایمر با استفاده از DateTime و زمان مطلق عمل می‌کند تا افت فریم باعث کندی شمارش نشود.
6. **پوشش کامل ۵ بازی:** هیچ کدام از بازی‌ها ماک نیست و همگی دارای چرخه کامل از انتخاب تا نتیجه و ثبت امتیاز هستند.
7. **طراحی بصری سطح بالا:** تمام صفحات دارای هویت بصری جذاب پارتی گیم و تایپوگرافی خوانای فارسی هستند.
