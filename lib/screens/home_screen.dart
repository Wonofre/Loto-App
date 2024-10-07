import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  final List<Map<String, String>> lotteries = [
    {'name': 'Lotofácil', 'apiName': 'lotofacil'},
    {'name': 'Mega-Sena', 'apiName': 'megasena'},
    {'name': 'Quina', 'apiName': 'quina'},
    {'name': 'Lotomania', 'apiName': 'lotomania'},
    {'name': 'Timemania', 'apiName': 'timemania'},
    {'name': 'Dupla Sena', 'apiName': 'duplasena'},
    {'name': 'Loteca', 'apiName': 'loteca'},
    {'name': 'Federal', 'apiName': 'federal'},
    {'name': 'Dia de Sorte', 'apiName': 'diadesorte'},
    {'name': 'Super Sete', 'apiName': 'supersete'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Banner Ad
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();

    // Load Interstitial Ad
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('Interstitial Ad carregado');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void _showInterstitialAd(Function onAdClosed) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          setState(() {
            _isInterstitialAdReady = false;
          });
          _loadInterstitialAd(); // Load a new ad for future use
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          setState(() {
            _isInterstitialAdReady = false;
          });
          _loadInterstitialAd(); // Load a new ad for future use
          onAdClosed(); // Proceed even if ad fails to show
        },
      );
      _interstitialAd!.show();
    } else {
      print('Interstitial Ad não está pronto');
      onAdClosed(); // Proceed if ad is not ready
    }
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loterias - Resultado Fácil'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
            tooltip: 'Ver Histórico',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.history),
              label: Text('Ver Histórico'),
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lotteries.length,
              itemBuilder: (context, index) {
                final lottery = lotteries[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(lottery['name']!),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Show Interstitial Ad before navigation
                      _showInterstitialAd(() {
                        Navigator.pushNamed(
                          context,
                          '/manual_entry',
                          arguments: lottery,
                        );
                      });
                    },
                  ),
                );
              },
            ),
          ),
          if (_isBannerAdReady)
            SizedBox(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}
