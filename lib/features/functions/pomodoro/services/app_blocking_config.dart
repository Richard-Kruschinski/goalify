/// Configuration for app blocking feature
/// Contains list of apps to block during focus sessions
class AppBlockingConfig {
  /// List of app package names to block during work sessions
  /// Add more package names as needed
  static const List<String> blockedApps = [
    // Social Media
    'com.instagram.android',
    'com.facebook.katana',
    'com.facebook.orca',
    'com.twitter.android',
    'com.snapchat.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.reddit.frontpage',
    
    // Entertainment
    'com.google.android.youtube',
    'com.netflix.mediaclient',
    'com.spotify.music',
    'com.amazon.avod.thirdpartyclient', // Prime Video
    
    // Games (examples)
    'com.supercell.clashofclans',
    'com.king.candycrushsaga',
    'com.mojang.minecraftpe',
    
    // Browsers (optional - be careful with this)
    // 'com.android.chrome',
    // 'org.mozilla.firefox',
    
    // Messaging (optional - users might need these)
    // 'com.whatsapp',
    // 'org.telegram.messenger',
    
    // Add more package names here as needed
  ];

  /// Check if a package name should be blocked
  static bool shouldBlock(String packageName) {
    return blockedApps.contains(packageName);
  }

  /// Get the number of blocked apps
  static int get blockedAppsCount => blockedApps.length;
}
