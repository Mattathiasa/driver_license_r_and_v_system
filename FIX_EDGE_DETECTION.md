# Fix edge_detection Package Build Error

## The Problem

The `edge_detection` package is outdated and doesn't have a namespace defined in its build.gradle, which is required by newer Android Gradle Plugin versions.

Error message:
```
Namespace not specified. Specify a namespace in the module's build file
```

## Solution Options

### Option 1: Automated Fix (Recommended)

Run the fix script:
```cmd
fix-edge-detection.bat
```

This will:
1. Locate the edge_detection package in your pub cache
2. Backup the original build.gradle
3. Add the required namespace
4. Rebuild your app

### Option 2: Manual Fix

1. Navigate to the package folder:
   ```cmd
   cd %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\edge_detection-1.1.3\android
   ```

2. Open `build.gradle` in a text editor

3. Find the `android {` block and add namespace right after it:
   ```gradle
   android {
       namespace 'com.sample.edgedetection'
       
       // rest of the configuration...
   ```

4. Save the file

5. Clean and rebuild:
   ```cmd
   cd C:\Users\matta\Desktop\DAFTech\mobile-flutter
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

### Option 3: Use Alternative Package

If the fix doesn't work, consider using an alternative package:

1. Remove edge_detection from `pubspec.yaml`
2. Add a maintained alternative like `cunning_document_scanner`:
   ```yaml
   dependencies:
     cunning_document_scanner: ^1.2.2
   ```

3. Update the code to use the new package

## After Applying Fix

1. Clean the build:
   ```cmd
   flutter clean
   ```

2. Get dependencies:
   ```cmd
   flutter pub get
   ```

3. Build again:
   ```cmd
   flutter build apk --debug
   ```

## Notes

- The fix modifies the package in your pub cache
- If you run `flutter pub get` or `flutter pub upgrade`, you may need to reapply the fix
- Consider switching to a maintained package for long-term stability
- The backup file is saved as `build.gradle.backup` in case you need to restore

## Verification

After applying the fix, you should see:
```
BUILD SUCCESSFUL
```

And your APK will be generated at:
```
build\app\outputs\flutter-apk\app-debug.apk
```
