import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages AdMob banner and interstitial ads for free-tier users
class AdManager {
  static bool _initialized = false;
  static DateTime? _lastInterstitialTime;

  // TODO: Replace with real ad unit IDs
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Create a banner ad for display on main screens
  static BannerAd createBannerAd({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: _testBannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Load and show an interstitial ad (max 1 per 3 minutes)
  static Future<void> showInterstitial() async {
    if (_lastInterstitialTime != null &&
        DateTime.now().difference(_lastInterstitialTime!) < const Duration(minutes: 3)) {
      return; // Cooldown not elapsed
    }

    await InterstitialAd.load(
      adUnitId: _testInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _lastInterstitialTime = DateTime.now();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, _) => ad.dispose(),
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {},
      ),
    );
  }
}
