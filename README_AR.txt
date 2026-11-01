# مكتبة كتب المرحلة الأولى - مشروع Flutter

هذا مجلد مصدر Flutter مبدئي يحتوي على:
- `lib/main.dart`: التطبيق بعد تحسين الواجهة وإضافة إيقاف التحميل وإعادة فتح الملف بعد تنزيله.
- `pubspec.yaml`: الحزم المطلوبة.

## مهم
هذا **ليس ملف APK جاهزاً**. يلزم توليد ملفات منصة Android وبناء التطبيق باستخدام Flutter SDK.

من داخل مجلد المشروع شغّل:
```bash
flutter create --platforms=android .
flutter pub get
flutter build apk --release
```

سيكون ملف APK عادةً في:
`build/app/outputs/flutter-apk/app-release.apk`

إذا استخدمت خدمة بناء سحابية مثل Codemagic، ارفع المشروع بعد توليد مجلد Android.
