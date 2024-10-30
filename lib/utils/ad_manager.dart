// lib/utils/ad_manager.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static void initialize() {
    MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId:
          'ca-app-pub-8214909818712774/2799387952', // ID de anúncio interstitial
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial Ad carregado');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd falhou ao carregar: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static Future<void> showInterstitialAd(
      Future<void> Function() onAdClosed) async {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) async {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Carrega um novo anúncio para uso futuro
          await onAdClosed();
        },
        onAdFailedToShowFullScreenContent:
            (InterstitialAd ad, AdError error) async {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Carrega um novo anúncio para uso futuro
          await onAdClosed(); // Prossegue mesmo se o anúncio falhar
        },
      );
      _interstitialAd!.show();
    } else {
      print('Interstitial Ad não está pronto');
      await onAdClosed(); // Prossegue se o anúncio não estiver pronto
    }
  }
}
