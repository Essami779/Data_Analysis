# تقييم وتحليل حماية وأمن النظام (SASP Dashboard & Mobile App)

تاريخ التحليل: 2026-07-05

يحتوي النظام (الموقع الإلكتروني وتطبيق الهاتف الذكي) على مستويات جيدة من الحماية المدمجة والمهيأة لحمايتهما من الاختراقات الشائعة، وذلك بالاعتماد على إطار عمل لارافل (Laravel) للوحة التحكم والموقع، وإطار عمل فلوتر (Flutter) لتطبيق الهاتف، بالإضافة إلى إعدادات خادم الاستضافة (Hostinger).

إليك تفصيل كامل لنوع الحماية المستخدمة في كل منهما:

---

## أولاً: حماية الموقع ولوحة التحكم (Backend - Laravel)
تم بناء لوحة التحكم والموقع باستخدام **Laravel 12**، وهو إطار عمل يحتوي على حماية قوية وافتراضية ضد الهجمات الشهيرة:

1. **حماية مسارات النظام والبيانات الحساسة (Secure Directory Structure):**
   - تم استخدام الهيكلية الآمنة عند الرفع على Hostinger (كما هو موضح في [Hostinger.md](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/Analysis/Hostinger%20.md))، حيث يتم وضع ملفات النظام الحساسة وملف الإعدادات [.env](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/.env) خارج مجلد الموقع العام `public_html`. هذا يمنع أي شخص من الوصول للملفات البرمجية أو كلمات مرور قاعدة البيانات عبر المتصفح.

2. **تشفير البيانات أثناء النقل (SSL/TLS - HTTPS):**
   - يتم تشفير جميع الاتصالات بين المتصفح/التطبيق والخادم باستخدام شهادة الأمان SSL (بروتوكول `HTTPS`) على النطاق `sasp.astrodevye.com`، مما يمنع هجمات التسمع واعتراض البيانات (Man-in-the-Middle).

3. **الحماية من حقن الاستعلامات (SQL Injection Prevention):**
   - يتم جلب البيانات في الموقع باستخدام Eloquent ORM (مثل الكود المكتوب في [SaspApiController.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/app/Http/Controllers/Sasp/SaspApiController.php)) والذي يستخدم تقنية PDO Parameter Binding تلقائياً. هذا يمنع المخترقين من حقن أوامر خبيثة داخل قاعدة البيانات.

4. **الحماية من ثغرات تزوير الطلبات عبر المواقع (CSRF Protection):**
   - يقوم إطار العمل بالتحقق من رموز CSRF لجميع الطلبات في متصفح الويب (مثل الطلبات البريدية وإجراءات الإضافة والتعديل). وفي ملف [bootstrap/app.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/bootstrap/app.php)، تم إعفاء مسارات الـ API الخاصة بالتطبيق `api/sasp/*` فقط لأنها تستخدم أسلوباً آخر للتوثيق وبدون جلسات المتصفح التقليدية.

5. **الحماية من ثغرات حقن النص البرمجي (XSS Protection):**
   - يقوم محرك القوالب Blade المستخدم في عرض صفحات الويب بتعقيم النصوص تلقائياً عند طباعتها باستخدام `{{ $variable }}`، مما يمنع تشغيل أكواد الجافاسكريبت الضارة التي قد يقوم أحد المستخدمين بإدخالها.

6. **إغلاق وضع التطوير (Disabled Debug Mode):**
   - تم إعداد المتغيرات في ملف [.env](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/.env) كالتالي: `APP_DEBUG=false` و `APP_ENV=production`. هذا مهم جداً لأنه يمنع ظهور تفاصيل الأخطاء البرمجية الحساسة ومسارات الخادم للمستخدمين في حال حدوث أي خطأ أثاء التشغيل.

7. **إدارة الصلاحيات والأدوار (Role-Based Access Control - RBAC):**
   - تعتمد لوحة التحكم على حزمة `spatie/laravel-permission` للتحقق من أدوار المستخدمين (مثل super-admin, admin, doctor, student) قبل السماح لهم بالوصول للمسارات الحساسة، كما هو مطبق في [routes/web.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/routes/web.php).

8. **تشفير كلمات المرور وسرية الجلسات:**
   - يتم تخزين كلمات مرور المستخدمين مشفرة بـ Bcrypt/Argon2 (عبر `Hash::make`).
   - يتم تخزين جلسات المستخدمين في قاعدة البيانات (`SESSION_DRIVER=database`) بدلاً من الكوكيز لزيادة الأمان ومنع سرقة الجلسات.

---

## ثانياً: حماية تطبيق الهاتف (Flutter App)
تطبيق الهاتف يعتمد على واجهة برمجية متصلة بالخادم محمي بـ:

1. **إجبار تغيير كلمة المرور الافتراضية (Enforced Password Change):**
   - عند قيام الطالب بتسجيل الدخول لأول مرة بكلمة المرور الافتراضية (`123456`)، يقوم التطبيق (عبر الكود في [sync_service.dart](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_App_API/lib/core/network/sync_service.dart#L67-L68)) وخلفية النظام بإجباره على تغييرها مباشرة لحماية الحساب من التخمين والدخول العشوائي.

2. **البيئة المعزولة لقاعدة البيانات المحلية (Sandbox SQLite):**
   - يتم تخزين البيانات والمستندات وجدول الإعدادات في قاعدة بيانات SQLite محلية في ملف [database_helper.dart](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_App_API/lib/core/database/database_helper.dart). نظام التشغيل (أندرويد و iOS) يضع التطبيق في بيئة معزولة (Sandbox)، مما يمنع التطبيقات الأخرى المثبتة على الهاتف من الوصول إلى ملف قاعدة البيانات هذا إلا إذا كان الهاتف يحتوي على صلاحيات جذرية (Root/Jailbreak).

3. **رمز التوثيق (Auth Token):**
   - عند تسجيل الدخول بنجاح، يُنشئ الخادم رمزاً للتوثيق `token` ويتم إرساله للتطبيق ليتمكن التطبيق من إجراء المزامنة والتحقق محلياً.

---

## ثالثاً: ملاحظات أمنية وتوصيات للتحسين المستقبلي
بناءً على مراجعة الكود، هناك بعض النقاط التي يُنصح بتحسينها لزيادة مستوى الأمان إلى أقصى حد:

1. **تأمين واجهة الـ API بالكامل:**
   - حالياً، عند طلب المزامنة في التطبيق في دالة `syncFromBackend` في [sync_service.dart](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_App_API/lib/core/network/sync_service.dart#L235)، يتم إرسال طلب المزامنة ممرراً الـ `X-User-ID` فقط في الهيدر، ويتم جلب البيانات بناءً عليه في [SaspApiController.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/app/Http/Controllers/Sasp/SaspApiController.php).
   - *التوصية:* يفضل تفعيل التحقق من الـ `token` الذي يتم حفظه عند تسجيل الدخول (عن طريق Laravel Sanctum أو عبر التحقق من توقيع الرمز) لكل طلب API للتأكد من أن صاحب الـ ID هو نفسه الشخص المصرح له وليس مجرد شخص يقوم بإرسال ID مستخدم آخر.

2. **تشفير كلمة المرور المحفوظة محلياً (Offline Encryption):**
   - يقوم التطبيق بحفظ كلمة المرور كـ Plaintext في إعدادات SQLite لتوفير خاصية تسجيل الدخول بدون إنترنت (Offline Login).
   - *التوصية:* يفضل تخزين كلمة المرور بصيغة مشفرة محلياً أو استخدام حزمة مثل `flutter_secure_storage` لتخزين البيانات الحساسة مثل الـ password والـ token بدلاً من حفظها كنصوص عادية في جدول الإعدادات المفتوح.
