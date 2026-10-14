# FLOUSI — Complete Android build package

This package preserves the original FLOUSI prototype and adds the missing Flutter project configuration needed to build an Android APK in GitHub Actions.

## Fix for the previous build error

The old workflow ran `flutter pub get` in a repository without `pubspec.yaml`, so Flutter reported `Expected to find project root in current working directory`. This package includes `pubspec.yaml` and `lib/main.dart`, bundles the web prototype as Flutter assets, and creates Android platform files before resolving dependencies.

## Upload to GitHub

1. Download and extract this ZIP.
2. Upload the **contents** of the `FLOUSI-Android-Complete` folder to the root of `https://github.com/iiredlx/Flousi` (not the enclosing folder itself). Replace the old workflow if prompted.
3. Commit the changes to `main`.
4. Open the repository's **Actions** tab and select **Build FLOUSI APK**.
5. When the workflow succeeds, open the run and download the `FLOUSI-Android-APK` artifact. Extract it to get `app-release.apk`.

You can also run it manually from Actions → Build FLOUSI APK → Run workflow.

## Contents

- `pubspec.yaml`: Flutter package configuration and WebView dependency.
- `lib/main.dart`: Android app shell that displays the original FLOUSI UI.
- `assets/web/`: copies of the original HTML, CSS, and JavaScript, bundled into the APK.
- `.github/workflows/build-apk.yml`: automated APK build and artifact upload.
- `index.html`, `styles.css`, `app.js`: original editable web prototype.
- `FLOUSI_SPEC.md`, `schema.sql`: original product specification and proposed database schema.

## Important limitations

This makes the current prototype buildable as an Android APK; it does not add cloud sync, authentication, or a production backend. Prototype data is still stored locally in WebView storage, and exchange rates are illustrative fixed values. Do not use it to store sensitive financial information yet.


### إصلاح خطأ Android v1 embedding

خطوة البناء تحذف مجلد `android` القديم وتولّد مجلد Android حديثًا بواسطة إصدار Flutter الحالي قبل البناء، حتى لا تبقى ملفات Android قديمة تستخدم embedding المحذوف. لا تحذف ملفات الويب أو بيانات التطبيق.
