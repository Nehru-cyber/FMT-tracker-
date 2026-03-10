import 'database_service.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';
  static const String _premiumExpiryKey = 'premium_expiry';
  
  static bool isPremium() {
    return DatabaseService.getSetting(_premiumKey, defaultValue: false) == true;
  }
  
  static DateTime? getPremiumExpiry() {
    final expiry = DatabaseService.getSetting(_premiumExpiryKey);
    if (expiry == null) return null;
    return DateTime.parse(expiry);
  }
  
  static Future<void> activatePremium({required bool isYearly}) async {
    final now = DateTime.now();
    final expiry = isYearly 
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    
    await DatabaseService.saveSetting(_premiumKey, true);
    await DatabaseService.saveSetting(_premiumExpiryKey, expiry.toIso8601String());
    
    final user = DatabaseService.getCurrentUser();
    if (user != null) {
      user.isPremium = true;
      await DatabaseService.saveUser(user);
    }
  }
  
  static Future<void> deactivatePremium() async {
    await DatabaseService.saveSetting(_premiumKey, false);
    await DatabaseService.saveSetting(_premiumExpiryKey, null);
    
    final user = DatabaseService.getCurrentUser();
    if (user != null) {
      user.isPremium = false;
      await DatabaseService.saveUser(user);
    }
  }
  
  static bool canAccessFeature(String feature) {
    const premiumFeatures = ['export', 'business', 'analytics', 'backup', 'noAds'];
    if (!premiumFeatures.contains(feature)) return true;
    return isPremium();
  }
}
