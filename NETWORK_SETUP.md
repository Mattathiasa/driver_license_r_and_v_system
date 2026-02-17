# Local Network Setup (No ngrok needed!)

## Quick Start

1. **Make sure your phone and computer are on the same WiFi network**

2. **Run the server:**
   ```cmd
   run-on-network.bat
   ```

3. **Copy the network URL shown** (e.g., `http://192.168.1.100:5182`)

4. **Update your Flutter app:**
   - Open your Flutter app's API configuration
   - Replace the base URL with the network URL from step 3
   - Rebuild and run your app

## Advantages
- No account signup needed
- No external service required
- Faster (no internet routing)
- Works offline (just needs local WiFi)

## Requirements
- Phone and computer on same WiFi network
- Windows Firewall may need to allow the connection

## Troubleshooting

### Can't connect from phone
1. Check if both devices are on the same WiFi
2. Try disabling Windows Firewall temporarily to test
3. Add firewall rule:
   ```cmd
   netsh advfirewall firewall add rule name="DotNet API" dir=in action=allow protocol=TCP localport=5182
   ```

### Wrong IP address shown
- The script shows your first IPv4 address
- If you have multiple network adapters, you may need to check manually:
  ```cmd
  ipconfig
  ```
- Look for the "Wireless LAN adapter" or "Ethernet adapter" section

## When to use ngrok instead
- Testing from a different network
- Sharing with someone not on your WiFi
- Testing webhooks from external services
- Need a public HTTPS URL
