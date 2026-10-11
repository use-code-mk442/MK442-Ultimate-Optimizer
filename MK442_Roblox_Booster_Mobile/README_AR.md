# MK442 RBLX Booster Mobile

نسخة أندرويد مستوحاة من لوحة Roblox الموجودة في سكربت `MK442_Ultimate_Optimizer.ahk`، بواجهة عربية داكنة ولمسات نيون.

## ما الموجود في النسخة الحالية؟
- قراءة تردد شاشة الهاتف الحالي وأعلى تردد تعرضه أوضاع الشاشة المتاحة للنظام.
- حفظ هدف FPS داخل التطبيق (30 إلى 1000) مع توضيح أنه رقم تفضيلي وليس فتحاً فعلياً للفريمات.
- ثلاثة ملفات توصية: تنافسي، متوازن، وجودة.
- اختصارات لفتح Roblox وإعدادات الشاشة ومعلومات تطبيق Roblox.
- إرشادات عملية لتقليل التقطيع وإعداد البطارية وسلاسة الحركة.
- لا توجد إعلانات، ولا اتصال بالشبكة من داخل التطبيق، ولا جمع بيانات.

## مهم جداً عن FPS والتعديلات
- شاشة Galaxy S26 Ultra تدعم حتى 120Hz وفق مواصفات Samsung. هذا هو أقصى معدل تحديث للشاشة، وليس ضماناً أن Roblox سترسم 120 إطاراً في الثانية.
- تحديد هدف 500 أو 1000 داخل التطبيق لا يرفع أداء الجهاز ولا يغيّر Roblox؛ هو رقم محفوظ للتوضيح فقط.
- تطبيق أندرويد عادي لا يستطيع تعديل مجلد Roblox الخاص أو حقن ReShade/Motion Blur داخل اللعبة بسبب عزل التطبيقات في Android. لذلك هذه النسخة لا تدّعي تنفيذ تعديلات غير حقيقية ولا تطلب Root أو Shizuku.
- إعدادات الرسومات الفعلية تعدّلها من داخل Roblox/التجربة نفسها. ارتفاع الجودة قد يقلّل FPS ويرفع الحرارة.

## إخراج APK عبر GitHub Actions (يمكن القيام به من المتصفح)
1. فك ضغط ملف المشروع.
2. أنشئ مستودعاً جديداً في GitHub.
3. ارفع **محتويات المجلد** `MK442_Roblox_Booster_Mobile` إلى جذر المستودع، بما في ذلك مجلد `.github` المخفي.
4. افتح تبويب **Actions** وفعّل Actions إذا طلب GitHub ذلك.
5. شغّل **Build MK442 Android APK** من زر **Run workflow**، أو ادفع أي تغيير إلى فرع `main` أو `master`.
6. بعد نجاح البناء، افتح نتيجة التشغيل ونزّل Artifact باسم `MK442-Roblox-Booster-APK`. بداخله `app-debug.apk`، ثم انقله للهاتف وثبّته.

## البناء محلياً
افتح المجلد في Android Studio مع تثبيت JDK 17 وAndroid SDK Platform 35، ثم نفّذ `assembleDebug`. هذا المشروع يستخدم Android Gradle Plugin 8.9.2 وGradle 8.11.1.

## ملفات المشروع
- `app/src/main/java/com/mk442/robloxbooster/MainActivity.java`: الواجهة والمنطق.
- `app/src/main/AndroidManifest.xml`: تعريف التطبيق.
- `.github/workflows/build-apk.yml`: يبني APK تلقائياً على GitHub Actions.

## المراجع
- مواصفات Samsung Galaxy S26 Ultra: https://www.samsung.com/sa_en/business/smartphones/galaxy-s/galaxy-s26-ultra-sm-s948bzkimea/
- شرح Roblox الرسمي لإعدادات جودة الرسومات: https://en.help.roblox.com/hc/en-us/articles/203314310-Graphics-Quality
- قيود الوصول إلى ملفات التطبيقات في Android: https://source.android.com/docs/core/storage/scoped
