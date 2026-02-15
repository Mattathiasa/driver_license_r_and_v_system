class ApiConfig {
  // IMPORTANT: Change this based on where you're running the app
  // - 'emulator' for Android Emulator
  // - 'ios' for iOS Simulator
  // - 'physical' for Physical Device via WiFi
  // - 'usb' for Physical Device via USB debugging (recommended!)
  static const String environment = 'usb';

  // For physical devices via WiFi, update this with your computer's IP address
  // Run: ipconfig (Windows) or ifconfig (Mac/Linux) to find your IP
  static const String physicalDeviceIP = '10.146.207.17'; // UPDATE THIS!

  static String get baseUrl {
    switch (environment) {
      case 'emulator':
        // Android Emulator uses special IP to reach host machine
        return 'http://10.0.2.2:5182/api';

      case 'ios':
        // iOS Simulator can use localhost
        return 'http://localhost:5182/api';

      case 'physical':
        // Physical device via WiFi needs your computer's actual IP address
        return 'http://$physicalDeviceIP:5182/api';

      case 'usb':
        // Physical device via USB with ADB port forwarding
        // Run: adb reverse tcp:5182 tcp:5182
        return 'http://localhost:5182/api';

      default:
        return 'http://10.0.2.2:5182/api';
    }
  }

  // Helper to get Swagger URL for testing
  static String get swaggerUrl {
    switch (environment) {
      case 'emulator':
        return 'http://10.0.2.2:5182/swagger';
      case 'ios':
        return 'http://localhost:5182/swagger';
      case 'physical':
        return 'http://$physicalDeviceIP:5182/swagger';
      case 'usb':
        return 'http://localhost:5182/swagger';
      default:
        return 'http://10.0.2.2:5182/swagger';
    }
  }
}
