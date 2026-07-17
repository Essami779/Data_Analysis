# SASP AI Integration — توثيق كامل

## نظرة عامة

تم دمج نظام ذكاء اصطناعي متكامل في مشروع SASP يشمل:
- **محادثة ذكية** مع سياق المواد الدراسية (RAG)
- **بنك أسئلة ذكي** يولّد أسئلة MCQ تلقائياً
- **بحث على الإنترنت** عند الحاجة (عبر Tavily API)

---

## المكونات المضافة / المعدّلة

| الملف | النوع | الوصف |
|-------|-------|-------|
| `app/Http/Controllers/Sasp/AiController.php` | ✨ جديد | Controller رئيسي للـ AI |
| `routes/web.php` | 🔧 معدّل | إضافة routes لـ AI |
| `config/services.php` | 🔧 معدّل | إضافة Groq + Tavily config |
| `.env` | 🔧 معدّل | إضافة API keys |
| `lib/screens/ai/ai_portal_screen.dart` | 🔧 معدّل | ربط بالـ API الحقيقي |
| `lib/core/network/sync_service.dart` | 🔧 معدّل | إضافة AI methods |
| `lib/screens/secondary/ai_question_bank_screen.dart` | ✨ جديد | شاشة بنك الأسئلة |

---

## API Endpoints

```
Base: https://sasp.astrodevye.com/api/sasp/ai
```

| Endpoint | Method | الوظيفة |
|----------|--------|---------|
| `/chat` | POST | محادثة ذكية مع RAG |
| `/generate-questions` | POST | توليد أسئلة MCQ |
| `/courses` | GET | قائمة المواد للـ UI |
| `/search` | POST | بحث على الإنترنت |

---

## خطوات الإعداد

### 1. الحصول على Groq API Key (مجاني)
1. اذهب إلى [console.groq.com](https://console.groq.com)
2. سجّل حساب مجاني
3. اذهب إلى API Keys → Create API Key
4. انسخ الـ key وضعه في `.env`:
   ```
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxx
   ```

### 2. (اختياري) Tavily للبحث على الإنترنت
1. اذهب إلى [app.tavily.com](https://app.tavily.com)
2. سجّل حساب مجاني (1000 طلب/شهر)
3. ضع الـ key في `.env`:
   ```
   TAVILY_API_KEY=tvly-xxxxxxxxxxxxxxxxxxxx
   ```

### 3. تحديث Laravel Cache
```bash
php artisan config:clear
php artisan route:clear
```

### 4. تسجيل شاشة بنك الأسئلة في Flutter
أضف في ملف routes أو Navigation:
```dart
import '../screens/secondary/ai_question_bank_screen.dart';

// في Navigator:
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const AiQuestionBankScreen(),
));
```

---

## الاستخدام من Flutter

### إرسال رسالة للـ AI
```dart
final result = await SyncService.instance.sendAiMessage(
  'اشرح لي مفهوم التحليل العاملي',
  courseId: 'course_123',  // اختياري
  history: previousMessages,
);
// result['reply'] → نص الرد
// result['used_web'] → هل تم البحث على الإنترنت
```

### توليد أسئلة
```dart
final result = await SyncService.instance.generateAiQuestions(
  'course_123',
  count: 10,
  difficulty: 'medium',
  save: true,  // حفظ في قاعدة البيانات
);
// result['questions'] → List of {question, options, correct_answer, explanation}
```

---

## النموذج المستخدم

| المعلمة | القيمة |
|---------|--------|
| **النموذج** | `llama-3.1-8b-instant` |
| **المزود** | Groq (مجاني) |
| **السرعة** | ~500 token/sec |
| **اللغات** | عربي + إنجليزي |
| **الحد اليومي** | 14,400 طلب/يوم |

---

## آلية RAG (الذاكرة الأكاديمية)

عند كل سؤال، يقوم النظام بـ:
1. جلب بيانات المادة من `courses` + `educational_materials`
2. بناء **context نصي** يُمرَّر للنموذج كجزء من System Prompt
3. النموذج يجيب بناءً على هذا المحتوى أولاً
4. إذا كان السؤال يحتاج إنترنت → Tavily search ثم تمرير النتائج

---

## تطوير مستقبلي

- [ ] **PDF Reading**: قراءة ملفات PDF من `educational_materials` وتحليلها
- [ ] **Voice Chat**: تحويل الصوت لنص (Whisper API) ثم الإجابة
- [ ] **Streaming**: عرض الردود حرفاً بحرف (Server-Sent Events)
- [ ] **Quiz Mode**: اختبار تفاعلي مع تسجيل الدرجات
- [ ] **HuggingFace Switch**: إمكانية التبديل لـ `kuwaitai/llama3-arabic`
