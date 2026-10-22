import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';
import '../config/game_config.dart';

enum AdResult { rewarded, cancelled, failed }

class AdsService {
  final AdsConfig _config;
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  final _log = Logger();

  AdsService(this._config);

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _rewardedUnitId {
    if (!isSupportedPlatform) return '';
    if (_config.testMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? _config.androidRewardedAdUnitId
        : _config.iosRewardedAdUnitId;
  }

  Future<void> initialize() async {
    if (!isSupportedPlatform) {
      _log.i('Ads not supported on this platform. Running in mock/offline mode.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      await _loadRewardedAd();
    } catch (e) {
      _log.w('Ads initialization failed: $e');
    }
  }

  Future<void> _loadRewardedAd() async {
    if (!isSupportedPlatform || _isLoading) return;
    _isLoading = true;
    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          _log.i('Rewarded ad loaded');
        },
        onAdFailedToLoad: (err) {
          _isLoading = false;
          _log.w('Rewarded ad failed to load: $err');
        },
      ),
    );
  }

  bool get isRewardedAdReady => !isSupportedPlatform || _rewardedAd != null;

  Future<AdResult> showRewardedAd() async {
    if (!isSupportedPlatform) {
      // Direct reward grant in desktop/web testing environment
      return AdResult.rewarded;
    }

    if (_rewardedAd == null) {
      await _loadRewardedAd();
      return AdResult.failed;
    }

    final completer = Completer<AdResult>();
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(AdResult.cancelled);
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        if (!completer.isCompleted) completer.complete(AdResult.failed);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        if (!completer.isCompleted) completer.complete(AdResult.rewarded);
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
  }
}
