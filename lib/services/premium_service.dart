import 'database_service.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium';
  static const String _premiumExpiryKey = 'premium_expiry';
  
  static Future<bool> isPremium() async {
    return await DatabaseService.getSetting(_premiumKey, defaultValue: false) == true;
  }
  
  static Future<DateTime?> getPremiumExpiry() async {
    final expiry = await DatabaseService.getSetting(_premiumExpiryKey);
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
    
    final user = await DatabaseService.getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(isPremium: true);
      await DatabaseService.saveUser(updatedUser);
    }
  }
  
  static Future<void> deactivatePremium() async {
    await DatabaseService.saveSetting(_premiumKey, false);
    await DatabaseService.saveSetting(_premiumExpiryKey, null);
    
    final user = await DatabaseService.getCurrentUser();
    if (user != null) {
      final updatedUser = user.copyWith(isPremium: false);
      await DatabaseService.saveUser(updatedUser);
    }
  }
  
  static Future<bool> canAccessFeature(String feature) async {
    const premiumFeatures = ['export', 'business', 'analytics', 'backup', 'noAds'];
    if (!premiumFeatures.contains(feature)) return true;
    return await isPremium();
  }
}
