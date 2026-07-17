# 👥 تقرير المستخدمين وصلاحيات نظام SASP (Users & Permissions Report)

يحتوي هذا التقرير على تفاصيل كاملة حول المستخدمين الافتراضيين (Seeders) المهيئين في نظام **SASP**، بالإضافة إلى هيكلية الأدوار والصلاحيات (Roles & Permissions) المطبقة في لوحة تحكم الويب وتطبيق الهاتف الذكي.

---

## 1. بيانات تسجيل الدخول للمستخدمين الافتراضيين (Seeded Users Accounts)

تمت تهيئة الحسابات التالية في قاعدة البيانات عبر `UserSeeder.php` لتغطية جميع الأدوار البرمجية واختبار الصلاحيات:

| الاسم الكامل | معرّف تسجيل الدخول (Login Identifier) | كلمة المرور الافتراضية | الدور البرمجي (Role) | طريقة المصادقة | ملاحظات |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **الإدارة العليا** | `superadmin@university.edu.ye` | `SuperAdmin@2026` | `SuperAdmin` | البريد الإلكتروني | يمتلك كافة صلاحيات النظام والتحكم |
| **مدير النظام** | `admin@university.edu.ye` | `Admin@2026` | `Admin` | البريد الإلكتروني | صلاحيات كاملة ما عدا الصلاحيات الحساسة |
| **د. أحمد محمد** | `dr.ahmed@university.edu.ye` | `Doctor@2026` | `Doctor` | البريد الإلكتروني | صلاحيات أكاديمية وعرض محدد للوحة التحكم |
| **طالب تجريبي** | `20261001` (الرقم الأكاديمي) | `123456` (افتراضية) | `Student` | الرقم الأكاديمي | **إجباري** تغيير كلمة المرور عند أول دخول |
| **فاطمة علي** | `20261002` (الرقم الأكاديمي) | `123456` (افتراضية) | `Student` | الرقم الأكاديمي | **إجباري** تغيير كلمة المرور عند أول دخول |

> [!IMPORTANT]
> - **للطلاب:** تسجيل الدخول يتم باستخدام **الرقم الأكاديمي** (وليس الإيميل) وكلمة المرور الافتراضية `123456`.
> - **بقية الأدوار:** يتم تسجيل الدخول باستخدام **البريد الإلكتروني** وكلمة المرور الخاصة بهم.

---

## 2. آلية حماية لوحة التحكم (Laravel Dashboard Access Control)

تم تطبيق قيود الأمان التالية لمنع الطلاب من الوصول إلى لوحة تحكم الويب:
1. **في متحكمات الدخول (Auth Controllers):**
   - تم تعديل `LoginController.php` و `LoginRequest.php` لمنع تسجيل دخول أي حساب يمتلك دور `Student` وعرض رسالة خطأ واضحة: *"الطلاب ليس لديهم صلاحية للوصول إلى لوحة التحكم."*.
2. **في مسارات الويب (web.php Routes):**
   - تم تغليف جميع مسارات لوحة التحكم تحت جدار الحماية `role:doctor|admin|super-admin` لمنع أي محاولة وصول خارجي غير مصرح بها.

---

## 3. آلية حماية تطبيق الهاتف الذكي (Mobile App Restrictions)

1. **تغيير كلمة المرور الإجباري للطالب:**
   - عند أول عملية تسجيل دخول ناجحة للطالب بكلمة المرور الافتراضية `123456`، يقوم الـ API بإرجاع الحقل `must_change_password: true`.
   - يقوم التطبيق فوراً بفتح شاشة تغيير كلمة المرور الإجبارية لمنع الطالب من المتابعة قبل تحديد كلمة مرور جديدة خاصة به.
   - عند حفظ كلمة المرور الجديدة عبر الـ API بنجاح، يتم تحديث حقل `must_change_password` إلى `false` في قاعدة البيانات ليتسنى له الدخول الاعتيادي لاحقاً.
2. **إخفاء المناهج الدراسية عن الدكتور:**
   - تم تعديل القائمة الجانبية (Navigation Drawer) والشاشة الرئيسية في تطبيق الفلاتر لإخفاء خيار **المناهج الدراسية** تماماً عندما يكون المستخدم المسجل هو `Doctor`.
3. **تحديد نطاق المراسلة للطالب:**
   - يُسمح للطالب فقط بمراسلة الدكاترة في قسم المراسلة الخاصة، ويُمنع من مراسلة بقية الطلاب أو الإدارة بشكل مباشر.
4. **تحديد نطاق مزامنة البيانات:**
   - عند قيام الطالب بالمزامنة مع السيرفر، يرجع الـ API فقط الدرجات والمدفوعات والشكاوى الخاصة به شخصياً لمنع تسريب بيانات الآخرين.

---

### ملفات مرجعية تم تحديثها وتعديلها:
* [UserSeeder.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/database/seeders/UserSeeder.php) (إعداد الحسابات الجديدة)
* [RolePermissionSeeder.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/database/seeders/RolePermissionSeeder.php) (إعداد الصلاحيات والأدوار الأربعة)
* [LoginController.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/app/Http/Controllers/Auth/LoginController.php) (منع دخول الطلاب للويب)
* [LoginRequest.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/app/Http/Requests/Auth/LoginRequest.php) (حماية دخول الويب للمصادقة البديلة)
* [web.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/routes/web.php) (تطبيق middleware الأدوار على مسارات لوحة التحكم)
* [SaspApiController.php](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_Dashbord_API/app/Http/Controllers/Sasp/SaspApiController.php) (تحديث تغيير كلمة المرور للطالب)
* [home_screen.dart](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_App_API/lib/screens/home/home_screen.dart) (إخفاء المناهج عن الدكتور)
* [navigation_drawer.dart](file:///d:/All%20My%20Project/GitHub_Project/GSP%20Projects/SASP/Dashbord/SASP_App_API/lib/core/widgets/navigation_drawer.dart) (تحديث بيانات المستخدم ديناميكياً وإخفاء المناهج)