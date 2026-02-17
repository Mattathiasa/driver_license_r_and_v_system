# Document Scanner - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Install Dependencies

```bash
cd mobile-flutter
flutter pub get
```

### Step 2: Configure Android Permissions

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Add these permissions before <application> -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32" />
    
    <application>
        <!-- Your existing config -->
        
        <!-- Add this activity for edge detection -->
        <activity
            android:name="com.sample.edgedetection.ScanActivity"
            android:theme="@style/Theme.AppCompat"
            android:exported="false" />
    </application>
</manifest>
```

### Step 3: Configure iOS Permissions

Edit `ios/Runner/Info.plist`:

```xml
<dict>
    <!-- Add these keys -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan driver licenses</string>
    
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need photo library access to select license images</string>
</dict>
```

### Step 4: Use in Your App

#### Option A: Full UI Screen (Easiest)

```dart
import 'package:flutter/material.dart';
import 'package:daftech_driver_license_system/screens/document_scanner_screen.dart';

// In your widget
ElevatedButton(
  onPressed: () async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const DocumentScannerScreen(),
      ),
    );

    if (result != null) {
      final data = result['extractedData'] as Map<String, String>?;
      print('License ID: ${data?['licenseId']}');
      print('Name: ${data?['fullName']}');
    }
  },
  child: const Text('Scan License'),
)
```

#### Option B: Service Only (Advanced)

```dart
import 'package:daftech_driver_license_system/services/document_scanner_service.dart';
import 'package:daftech_driver_license_system/services/ocr_service.dart';

Future<void> quickScan() async {
  // Scan
  final imagePath = await DocumentScannerService.scanDocument();
  
  if (imagePath != null) {
    // Extract
    final data = await OCRService.extractDataFromImage(imagePath);
    
    // Use
    print(data);
  }
}
```

### Step 5: Run the App

```bash
flutter run
```

## 📱 What You Get

### Features
✅ Automatic edge detection  
✅ Manual corner adjustment  
✅ Perspective correction  
✅ Image enhancement  
✅ OCR text extraction  
✅ Structured data output  

### Extracted Fields
- License ID (6 digits)
- Full Name
- Date of Birth
- Expiry Date
- License Type (A, B, C, D, E)
- Sex (M/F)
- Address
- Raw OCR text

## 🎯 Common Use Cases

### 1. Pre-fill Registration Form

```dart
Future<void> _scanAndFill() async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(builder: (context) => const DocumentScannerScreen()),
  );

  if (result != null) {
    final data = result['extractedData'] as Map<String, String>?;
    
    // Fill form fields
    setState(() {
      _licenseIdController.text = data?['licenseId'] ?? '';
      _nameController.text = data?['fullName'] ?? '';
      _dobController.text = data?['dateOfBirth'] ?? '';
    });
  }
}
```

### 2. Verify License Data

```dart
Future<bool> verifyLicense(String licenseId) async {
  // Scan license
  final imagePath = await DocumentScannerService.scanDocument();
  
  if (imagePath != null) {
    // Extract data
    final data = await OCRService.extractDataFromImage(imagePath);
    
    // Verify
    return data['licenseId'] == licenseId;
  }
  
  return false;
}
```

### 3. Batch Processing

```dart
Future<List<Map<String, String>>> scanMultiple(int count) async {
  final results = <Map<String, String>>[];
  
  for (int i = 0; i < count; i++) {
    final imagePath = await DocumentScannerService.scanDocument();
    
    if (imagePath != null) {
      final data = await OCRService.extractDataFromImage(imagePath);
      results.add(data);
    }
  }
  
  return results;
}
```

## 🔧 Troubleshooting

### Camera not opening?
- Check permissions in AndroidManifest.xml / Info.plist
- Run `flutter clean && flutter pub get`
- Restart the app

### OCR not accurate?
- Ensure good lighting
- Hold camera steady
- Use manual corner adjustment
- Ensure license is flat (not wrinkled)

### App crashes?
- Check Android minSdkVersion (should be 21+)
- Verify all dependencies are installed
- Check device has camera

## 📚 Next Steps

- Read full documentation: `docs/DOCUMENT_SCANNER_IMPLEMENTATION.md`
- Check integration examples: `lib/examples/scanner_integration_example.dart`
- Customize UI in: `lib/screens/document_scanner_screen.dart`
- Adjust OCR parsing in: `lib/services/ocr_service.dart`

## 💡 Tips

1. **Test on real device** - Camera features don't work well in emulator
2. **Good lighting** - Natural daylight works best
3. **Flat surface** - Place license on flat, contrasting background
4. **Hold steady** - Keep camera still during capture
5. **Manual adjustment** - Use corner adjustment for better results

## 🎨 Customization

### Change Scanner UI Colors

Edit `lib/screens/document_scanner_screen.dart`:

```dart
// Change primary color
backgroundColor: Colors.blue[700], // Change to your color

// Change button colors
ElevatedButton.styleFrom(
  backgroundColor: Colors.green[600], // Your color
)
```

### Adjust Image Enhancement

Edit `lib/services/document_scanner_service.dart`:

```dart
// In _enhanceImage method
image = img.adjustColor(
  image,
  contrast: 1.5,    // Increase for more contrast
  brightness: 1.1,  // Increase for brighter image
  saturation: 0.7,  // Decrease for less color
);
```

### Customize OCR Parsing

Edit `lib/services/ocr_service.dart`:

```dart
// Add custom patterns in _parseWithFieldAnchors
final customPattern = RegExp(r'YourPattern');
```

## ✅ Checklist

Before deploying:

- [ ] Permissions configured (Android + iOS)
- [ ] Tested on real device
- [ ] Error handling implemented
- [ ] Loading indicators added
- [ ] User feedback messages
- [ ] Temp file cleanup scheduled
- [ ] OCR accuracy validated
- [ ] Edge cases handled

## 🆘 Need Help?

1. Check `docs/DOCUMENT_SCANNER_IMPLEMENTATION.md` for detailed guide
2. Review example code in `lib/examples/`
3. Test with sample images
4. Verify platform configurations

---

**Ready to scan!** 📸
