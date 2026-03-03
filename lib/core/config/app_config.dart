class AppConfig {
  /// The base URL for the backend API.
  /// 
  /// How to set this for local development:
  /// - Android emulator: 'http://10.0.2.2:8000'
  /// - iOS simulator: 'http://127.0.0.1:8000'
  /// - Physical device (same Wi-Fi): 'http://192.168.x.x:8000' (your computer's local IP)
  /// 
  /// For production:
  /// - 'https://api.yourdomain.com'
  static const String baseUrl = 'https://dave-farm-backend.onrender.com'; // Set to Local PC IP for Physical Device
}
