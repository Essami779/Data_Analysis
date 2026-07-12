# خطة دمج الذكاء الاصطناعي في مشروع SASP

> **الحالة: ✅ مُنفَّذ بالكامل** — آخر تحديث: 2026-07-07

---

## البنية قبل التنفيذ وبعده

| المكوّن | الملف | قبل | بعد |
|--------|-------|-----|-----|
| شاشة SASP AI | `ai_portal_screen.dart` | ❌ ردود hardcoded | ✅ Groq API حقيقي |
| محادثة بالسياق | `ai_portal_screen.dart` | ❌ لا سياق | ✅ RAG من DB |
| بنك الأسئلة | `Question` model | ❌ لا توليد AI | ✅ توليد MCQ تلقائي |
| المواد الدراسية | `EducationalMaterial` | ❌ لا RAG | ✅ context يُمرَّر للنموذج |
| بحث الإنترنت | — | ❌ غير موجود | ✅ Tavily API |
| تاريخ المحادثات | — | ❌ غير موجود | ✅ Session history |
| heredoc PHP | `AiController.php` | ❌ خطأ `??` داخل heredoc | ✅ متغير مسبق `$courseDepartment` |
| بيئة التطوير | Flutter/Android | ❌ production URL ثابت | ✅ `localhost:8000` عبر USB |
| HTTP محلي | `AndroidManifest.xml` | ❌ HTTP محجوب | ✅ `network_security_config` |
| Dio Timeout | `sync_service.dart` | ❌ 5s (قصير جداً) | ✅ 15s (مناسب لـ ADB) |

---

## ما تم تنفيذه فعلياً

### 🔵 Backend — Laravel

#### ✅ 1. `AiController.php` — منشأ جديداً
**المسار:** `app/Http/Controllers/Sasp/AiController.php`

يحتوي على **4 دوال رئيسية**:

| الدالة | الوصف |
|--------|-------|
| `chat()` | محادثة ذكية مع RAG من `EducationalMaterial` + `Course` |
| `generateQuestions()` | توليد أسئلة MCQ بمستويات صعوبة (easy/medium/hard) |
| `courses()` | إرجاع قائمة المواد لواجهة الـ Flutter |
| `search()` | بحث على الإنترنت عبر Tavily API |

**الميزات المطبّقة داخل `AiController.php`:**
- **RAG**: `buildContext()` تجلب بيانات المادة من DB وتبني سياق نصي
- **System Prompt**: `buildSystemPrompt()` يضم التاريخ + السياق الأكاديمي + نتائج الويب
- **Web Detection**: `needsWebSearch()` تحدد تلقائياً إذا السؤال يحتاج إنترنت
- **JSON Parser**: `extractJsonArray()` يستخرج JSON من ردود النموذج بأمان
- **حفظ الأسئلة**: خيار `save=true` يحفظ الأسئلة المولّدة في جدول `questions`

#### ✅ 2. `routes/web.php` — معدّل
أُضيفت المجموعة التالية تحت `api/sasp`:

```php
Route::prefix('ai')->group(function () {
    Route::post('/chat',               [AiController::class, 'chat']);
    Route::post('/generate-questions', [AiController::class, 'generateQuestions']);
    Route::get('/courses',             [AiController::class, 'courses']);
    Route::post('/search',             [AiController::class, 'search']);
});
```

#### ✅ 3. `.env` — معدّل
```env
GROQ_API_KEY=your_groq_api_key_here
TAVILY_API_KEY=               # اختياري — للبحث على الإنترنت
```

#### ✅ 4. `config/services.php` — معدّل
```php
'groq'   => ['key' => env('GROQ_API_KEY'), 'model' => 'llama-3.1-8b-instant'],
'tavily' => ['key' => env('TAVILY_API_KEY')],
```

---

### 🟢 Frontend — Flutter

#### ✅ 5. `ai_portal_screen.dart` — أُعيد كتابته كاملاً
**المسار:** `lib/screens/ai/ai_portal_screen.dart`

الميزات المنفّذة:
- **API حقيقي**: `_sendMessage()` ترسل POST لـ `/api/sasp/ai/chat`
- **تاريخ المحادثة**: `_apiHistory` يُمرَّر مع كل طلب (آخر 6 ردود)
- **Course Selector**: شريط chips لاختيار المادة وتحديد السياق
- **Typing Indicator**: 3 نقاط متحركة أثناء انتظار الرد (`_DotPulse`)
- **Session History**: حفظ المحادثات السابقة في Drawer
- **نسخ الرد**: زر copy مع `Clipboard.setData()`
- **إعادة المحاولة**: زر refresh يُعيد إرسال آخر سؤال
- **شارة الويب**: أيقونة 🌐 تظهر إذا استُخدم البحث على الإنترنت
- **Suggestions**: 4 اقتراحات سريعة في شاشة الترحيب

#### ✅ 6. `sync_service.dart` — معدّل
**المسار:** `lib/core/network/sync_service.dart`

أُضيفت 3 دوال جديدة:

```dart
// إرسال رسالة للـ AI مع التاريخ والسياق
Future<Map<String, dynamic>> sendAiMessage(String message, {
  String? courseId,
  List<Map<String, String>> history = const [],
})

// توليد أسئلة MCQ لمادة معينة
Future<Map<String, dynamic>> generateAiQuestions(String courseId, {
  int count = 5,
  String difficulty = 'medium',
  bool save = false,
})

// جلب قائمة المواد للـ UI
Future<List<Map<String, dynamic>>> getCoursesForAi()
```

#### ✅ 7. `ai_question_bank_screen.dart` — منشأ جديداً
**المسار:** `lib/screens/secondary/ai_question_bank_screen.dart`

الميزات المنفّذة:
- **Dropdown** لاختيار المادة من قاعدة البيانات
- **اختيار الصعوبة**: 3 أزرار (سهل/متوسط/صعب) بألوان مختلفة
- **Slider** لتحديد عدد الأسئلة (3 → 15)
- **Toggle** لحفظ الأسئلة في DB تلقائياً
- **بطاقات قابلة للطي** تعرض السؤال + الخيارات + الإجابة الصحيحة + الشرح
- **تلوين تلقائي** للإجابة الصحيحة باللون الأخضر
- **نسخ سؤال مفرد** أو **نسخ الكل** عبر FAB

---

## مخطط التدفق الفعلي المنفّذ

```
Flutter App
    │
    ├─ AiPortalScreen ──► POST /api/sasp/ai/chat
    │     { message, course_id?, history[] }
    │
    └─ AiQuestionBankScreen ──► POST /api/sasp/ai/generate-questions
          { course_id, count, difficulty, save }

                      ▼
              Laravel AiController
                      │
          ┌───────────┴───────────┐
          │                       │
    buildContext()          needsWebSearch()
    Course + Materials          │
    من قاعدة البيانات      إذا نعم → Tavily API
          │                       │
          └───────────┬───────────┘
                      │
              buildSystemPrompt()
              System + Context + Web
                      │
              Groq API (llama-3.1-8b-instant)
              POST api.groq.com/openai/v1/chat/completions
                      │
              { reply, used_web }
                      │
              Flutter ← JSON Response
```

---

## النموذج المستخدم فعلياً

| المعلمة | القيمة |
|---------|--------|
| **المزود** | Groq (مجاني) |
| **النموذج** | `llama-3.1-8b-instant` |
| **السرعة** | ~500 token/ثانية |
| **الحد اليومي** | 14,400 طلب |
| **اللغات** | عربي ✅ إنجليزي ✅ |
| **max_tokens (chat)** | 1024 |
| **max_tokens (questions)** | 2048 |

---

## 🛠️ إصلاحات جلسة 2026-07-07

### 🔴 إصلاح 1: خطأ PHP في `AiController.php` — مشغّل `??` داخل Heredoc

**الملف:** `app/Http/Controllers/Sasp/AiController.php` — السطر 144

**المشكلة:**
```php
// ❌ خطأ — لا يمكن استخدام عمليات مثل ?? داخل heredoc مباشرةً
$prompt = <<<PROMPT
القسم: {$course->department ?? 'غير محدد'}
PROMPT;
```

**الإصلاح:**
```php
// ✅ حساب القيمة قبل الـ heredoc في متغير مستقل
$courseDepartment = $course->department ?? 'غير محدد';

$prompt = <<<PROMPT
القسم: {$courseDepartment}
PROMPT;
```

> **السبب:** PHP heredocs تدعم فقط interpolation بسيط (`{$var}` أو `{$obj->prop}`) — لا تدعم أي عمليات أو expressions كـ `??`.

---

### 🟠 إصلاح 2: ربط التطبيق بالسيرفر المحلي عبر USB

**الهدف:** تشغيل Flutter على جهاز أندرويد حقيقي متصل بـ USB مع Laravel يعمل محلياً.

#### آلية العمل: ADB Reverse Port Forwarding

```
[Android Device] ──USB──► [PC]
localhost:8000  ◄──────── 127.0.0.1:8000 (Laravel)
```

#### الأمر المطلوب (يُنفَّذ كل مرة بعد وصل الجهاز)

```powershell
# ملاحظة: ADB غير موجود في PATH — استخدم المسار الكامل
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
```

#### التغييرات في الكود

**`lib/core/network/sync_service.dart`:**
```dart
// 🔧 LOCAL DEV (USB): http://localhost:8000/api/sasp
// 🌐 PRODUCTION:       https://sasp.astrodevye.com/api/sasp
String baseUrl = 'http://localhost:8000/api/sasp';

// رُفع من 5s إلى 15s لتعويض تأخير ADB
final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
));
```

**`lib/core/database/database_helper.dart` — L372:**
```dart
await db.rawInsert(
    "INSERT INTO settings (key, value) VALUES ('api_base_url', 'http://localhost:8000/api/sasp')");
```

---

### 🟡 إصلاح 3: Android يحجب HTTP (Cleartext Traffic)

**المشكلة:** منذ Android 9 (API 28)، يُحجب `http://` بشكل افتراضي → `DioException [receive timeout]`.

#### الملفات المضافة/المعدَّلة

**`android/app/src/main/res/xml/network_security_config.xml`** *(جديد)*:
```xml
<network-security-config>
    <!-- HTTP مسموح فقط لـ localhost عند التطوير عبر USB -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">localhost</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
        <domain includeSubdomains="false">10.0.2.2</domain>
    </domain-config>
    <!-- كل شيء آخر يبقى HTTPS فقط -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

**`android/app/src/main/AndroidManifest.xml`** — تمت إضافة:
```xml
<application
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

> **ملاحظة أمان:** `network_security_config.xml` يحصر السماح بـ HTTP على `localhost` فقط — الـ production يبقى HTTPS ولا يتأثر.

---

### 🔁 للعودة لبيئة الإنتاج

```dart
// في sync_service.dart — غيّر السطر:
String baseUrl = 'https://sasp.astrodevye.com/api/sasp';
// وأزل 'https://sasp.astrodevye.com/api/sasp' من قائمة outdatedUrls
```

```dart
// في database_helper.dart — غيّر:
"INSERT INTO settings (key, value) VALUES ('api_base_url', 'https://sasp.astrodevye.com/api/sasp')"
```

---

## تطوير مستقبلي (غير منفّذ بعد)

- [ ] **PDF Reading** — قراءة ملفات PDF من `educational_materials`
- [ ] **Streaming** — عرض الرد حرفاً بحرف (SSE)
- [ ] **Voice Input** — Whisper API لتحويل الصوت لنص
- [ ] **Quiz Mode** — اختبار تفاعلي مع تسجيل الدرجات في DB
- [ ] **HuggingFace Switch** — التبديل لـ `kuwaitai/llama3-arabic`
