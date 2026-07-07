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
    'com.amazon.avod.thirdpartyclient', // Prime Video
    'com.crunchyroll.crunchyroid', // Crunchyroll
    
    // Games
    'com.supercell.clashofclans', // Clash of Clans
    'com.supercell.clashroyale', // Clash Royale
    'com.supercell.brawlstars', // Brawl Stars
    'com.king.candycrushsaga', // Candy Crush
    'com.mojang.minecraftpe', // Minecraft
    'com.tencent.ig', // PUBG Mobile
    'com.dts.freefireth', // Free Fire
    'com.innersloth.spacemafia', // Among Us
    'com.roblox.client', // Roblox
    'com.miHoYo.GenshinImpact', // Genshin Impact
    'com.activision.callofduty.shooter', // Call of Duty Mobile
    'com.ea.gp.fifamobile', // FIFA Mobile
    'com.riotgames.league.wildrift', // League of Legends: Wild Rift
    'com.garena.game.codm', // COD Mobile (Garena)
    'com.supercell.hayday', // Hay Day
    'com.playrix.homescapes', // Homescapes
    'com.playrix.gardenscapes', // Gardenscapes
    'com.king.candycrushsodasaga', // Candy Crush Soda
    'com.ea.game.simcitymobile_row', // SimCity BuildIt
    'com.scopely.monopolygo', // Monopoly GO!
    'com.chess', // Chess.com
    
    // Shopping
    'com.ebay.mobile', // eBay
    'com.amazon.mShop.android.shopping', // Amazon Shopping
    
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
