# دليل أي خدمة — Daliil Ay Khidma

منصة عربية لاكتشاف المحلات ومقدمي الخدمات والمنتجات والعروض حسب التصنيف والموقع، مع تطبيق مستخدم مبني بـFlutter وواجهة خلفية مبنية بـDjango REST Framework.

> هذا المستودع هو نسخة العمل المنظمة للمشروع. يوضح هذا الملف ما هو موجود فعليًا في الكود الحالي، بينما توجد الخطط المستقبلية في `ROADMAP.md`.

## الحالة الحالية

المشروع في مرحلة **Baseline Stabilization**: تثبيت الموجود، توثيقه، اختبار رحلات المستخدم الأساسية، ثم بدء التطوير المرحلي.

### الموجود حاليًا

- Backend باستخدام Django 5.2 وDjango REST Framework.
- مصادقة JWT وتسجيل مستخدمين وملفات شخصية.
- دليل أنشطة وتصنيفات ومواقع جغرافية.
- منتجات وخدمات وأسعار وعروض.
- بحث وفلاتر ومقارنة أسعار.
- مفضلة وتقييمات وإشعارات.
- تطبيق Flutter للمستخدم يدعم Android وiOS وWeb.
- خرائط وموقع جغرافي باستخدام MapLibre.
- تخزين وسائط إنتاجي اختياري عبر Cloudinary.
- Firebase Cloud Messaging.
- نشر Backend على Render ومعاينة Flutter Web عبر GitHub Pages.
- CI لتنسيق وتحليل واختبار Flutter وبناء Web وAndroid وiOS بدون توقيع.

### يحتاج إلى تدقيق أو استكمال

- توثيق عقود API بصورة كاملة.
- اختبار شامل للصلاحيات وملكية الموارد.
- توحيد تنسيق استجابات وأخطاء API.
- تثبيت إعدادات المشاريع الأصلية لـAndroid وiOS وWeb.
- مراجعة الأداء والأمان ورفع الملفات.
- تحديد نطاق MVP النهائي.
- بناء تطبيق الإدارة بعد تثبيت تطبيق المستخدم والـAPI.

## البنية التقنية

### Backend

- Python 3.11+
- Django 5.2
- Django REST Framework
- Simple JWT
- PostgreSQL في الإنتاج وSQLite للتطوير المحلي عند الحاجة
- django-filter وdrf-spectacular
- Cloudinary اختياري للوسائط
- Firebase Admin للإشعارات

### تطبيق المستخدم

- Flutter / Dart
- Riverpod
- Dio
- Flutter Secure Storage
- Firebase Messaging
- Geolocator
- MapLibre
- App Links
- دعم العربية والإنجليزية

## الهيكل الحالي

```text
.
├── apps/                  # تطبيقات Django والنطاقات الوظيفية
├── config/                # إعدادات Django والتوجيه والتشغيل
├── mobile/dalil_app/      # تطبيق Flutter للمستخدم
├── templates/             # واجهات Django الحالية
├── static/                # الملفات الثابتة
├── locale/                # ملفات الترجمة
├── fixtures/              # بيانات أولية وتجريبية
├── scripts/               # أدوات التشغيل والصيانة
├── docs/                  # التوثيق الهندسي والمنتجي
├── manage.py
├── requirements.txt
├── render.yaml
├── PROJECT_CONTEXT.md
└── ROADMAP.md
```

## التشغيل المحلي للـBackend

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

يجب ضبط متغيرات البيئة المناسبة قبل التشغيل الإنتاجي. راجع ملفات الإعداد و`docs/deployment/overview.md` عند اكتماله.

## تشغيل Flutter

```bash
cd mobile/dalil_app
flutter pub get
flutter gen-l10n
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

لبناء نسخة Web مرتبطة بالـBackend المنشور:

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://daliil-ay-khidma.onrender.com
```

## أسلوب العمل

- لا تعديل مباشر على `master`.
- فرع مستقل لكل مرحلة أو إصلاح مهم.
- Pull Request قبل الدمج.
- تشغيل الاختبارات والتحليل قبل الدمج.
- تحديث التوثيق عند تغيير السلوك أو المعمارية.
- تسجيل القرارات المهمة داخل `docs/adr/`.

راجع `CONTRIBUTING.md` للتفاصيل.

## وثائق المشروع

- `PROJECT_CONTEXT.md`: المرجع المختصر للحالة والقرارات.
- `ROADMAP.md`: المراحل والأولويات.
- `CHANGELOG.md`: سجل التغييرات المهمة.
- `docs/architecture/system-overview.md`: النظرة المعمارية.
- `docs/adr/`: سجل القرارات الهندسية.

## بيئات المشروع

- Backend: `https://daliil-ay-khidma.onrender.com/`
- Flutter Web preview: يتم نشره من GitHub Actions على GitHub Pages.

## الترخيص

المشروع مرخص وفق ملف `LICENSE` الموجود في المستودع.