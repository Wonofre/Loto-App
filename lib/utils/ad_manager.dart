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
          'ca-app-pub-3940256099942544/1033173712', // Substitua pelo seu Ad Unit ID
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

  static void showInterstitialAd(Function onAdClosed) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Carrega um novo anúncio para uso futuro
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _isInterstitialAdReady = false;
          loadInterstitialAd(); // Carrega um novo anúncio para uso futuro
          onAdClosed(); // Prossegue mesmo que o anúncio falhe
        },
      );
      _interstitialAd!.show();
    } else {
      print('Interstitial Ad não está pronto');
      onAdClosed(); // Prossegue se o anúncio não estiver pronto
    }
  }
}
