import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:polarity/core/constants.dart';

/// AdMob wrapper with UMP consent, interstitial, and rewarded ad support.
/// Uses Google Test Ad Unit IDs — swap with production IDs before release.
///
/// Interstitial Policy (time-only, monotonic clock):
///   An interstitial is shown on death ONLY when ALL conditions are true:
///     1. >= [interstitialMinIntervalSeconds] monotonic seconds have elapsed
///        since the last ad dismiss (or since app launch if no ad yet).
///     2. No interstitial is currently on-screen.
///     3. Ads are enabled and an interstitial is loaded.
///   The timer resets ONLY when the user dismisses a successfully shown ad.
///
///   Anti-bypass:
///     - Uses Stopwatch (monotonic) — immune to system clock manipulation.
///     - Cold-start grace: first ad requires 70s of actual app runtime.
///     - App kill mid-ad → on restart, 70s grace period applies again.
///     - Double-fire guard via _interstitialOnScreen flag.
///
///   Policy compliance:
///     - UMP/GDPR consent awaited before any ad SDK initialization.
///     - Interstitials only at natural breaks (death screen).
///     - Rewarded ads are user-initiated only.
///     - 70s minimum interval (well above recommended thresholds).
class AdService {
  static const String _googleTestPublisherPrefix = 'ca-app-pub-3940256099942544';

  bool _initialized = false;
  bool _sdkInitialized = false;
  bool _adsEnabled = true;
  bool _consentRefreshInFlight = false;

  static const Duration _consentRetryDelay = Duration(seconds: 45);
  Timer? _consentRetryTimer;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  // ── Monotonic timer (Stopwatch) — immune to clock manipulation ──
  // Starts when init() is called. _lastAdDismissedMs starts at 0, so the
  // first interstitial requires 70 real seconds of runtime after app launch.
  final Stopwatch _sessionClock = Stopwatch();
  int _lastAdDismissedMs = 0;

  // Guard: true while an interstitial is on-screen (between .show() and
  // dismiss/fail callback). Prevents double-fire from rapid death events.
  bool _interstitialOnScreen = false;

  bool get _isAdsPlatformSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _hasProductionAdUnitsForCurrentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return !GameConstants.androidAppId.startsWith(
            _googleTestPublisherPrefix,
          ) &&
          !GameConstants.androidInterstitialId.startsWith(
            _googleTestPublisherPrefix,
          ) &&
          !GameConstants.androidRewardedId.startsWith(
            _googleTestPublisherPrefix,
          );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return !GameConstants.iosAppId.startsWith(
            _googleTestPublisherPrefix,
          ) &&
          !GameConstants.iosInterstitialId.startsWith(
            _googleTestPublisherPrefix,
          ) &&
          !GameConstants.iosRewardedId.startsWith(
            _googleTestPublisherPrefix,
          );
    }
    return false;
  }

  bool get _blockAdsInRelease =>
      kReleaseMode && !_hasProductionAdUnitsForCurrentPlatform;

  // V6: Callback to notify Riverpod when rewarded ad readiness changes
  void Function(bool)? onRewardedReadyChanged;

  // Callbacks stored when an interstitial is shown; fired on close/fail.
  VoidCallback? _onInterstitialOpened;
  VoidCallback? _onInterstitialClosed;

  bool get adsEnabled => _adsEnabled;
  set adsEnabled(bool value) {
    _adsEnabled = value && _isAdsPlatformSupported && !_blockAdsInRelease;
    if (!_adsEnabled) {
      _cancelConsentRetry();
      _disposeLoadedAds();
    } else if (_initialized) {
      _kickAdRecovery();
    }
  }

  bool get isRewardedReady => _isRewardedReady && _adsEnabled;

    String get _interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.android
        ? GameConstants.androidInterstitialId
        : GameConstants.iosInterstitialId;

    String get _rewardedAdUnitId =>
      defaultTargetPlatform == TargetPlatform.android
        ? GameConstants.androidRewardedId
        : GameConstants.iosRewardedId;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!_isAdsPlatformSupported) {
      _adsEnabled = false;
      _isInterstitialReady = false;
      _isRewardedReady = false;
      onRewardedReadyChanged?.call(false);
      return;
    }

    if (_blockAdsInRelease) {
      _adsEnabled = false;
      _isInterstitialReady = false;
      _isRewardedReady = false;
      onRewardedReadyChanged?.call(false);
      return;
    }

    // Start monotonic session clock immediately
    _sessionClock.start();

    await _refreshConsentAndInitializeAds(scheduleRetryOnFail: true);
  }

  void _kickAdRecovery() {
    if (!_initialized || !_adsEnabled || !_isAdsPlatformSupported) return;
    unawaited(_refreshConsentAndInitializeAds(scheduleRetryOnFail: true));
  }

  void _cancelConsentRetry() {
    _consentRetryTimer?.cancel();
    _consentRetryTimer = null;
  }

  void _scheduleConsentRetry() {
    if (_consentRetryTimer != null || !_adsEnabled || !_isAdsPlatformSupported) {
      return;
    }
    _consentRetryTimer = Timer(_consentRetryDelay, () {
      _consentRetryTimer = null;
      if (!_initialized || !_adsEnabled || !_isAdsPlatformSupported) return;
      unawaited(_refreshConsentAndInitializeAds(scheduleRetryOnFail: true));
    });
  }

  void _disposeLoadedAds() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialReady = false;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedReady = false;
    _interstitialOnScreen = false;
    _onInterstitialOpened = null;
    _onInterstitialClosed = null;
    onRewardedReadyChanged?.call(false);
  }

  Future<void> _refreshConsentAndInitializeAds({
    required bool scheduleRetryOnFail,
  }) async {
    if (!_initialized || !_adsEnabled || !_isAdsPlatformSupported) return;
    if (_consentRefreshInFlight) return;

    _consentRefreshInFlight = true;
    try {
      // Await consent BEFORE initializing ad SDK (GDPR/UMP compliance).
      // Timeout after 5s so consent issues don't block the app forever.
      await _requestConsent().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );

      // Strictly gate ad loading on UMP state to avoid requesting ads before
      // consent is actually eligible for ad requests.
      final canRequestAds = await _canRequestAds();
      if (!canRequestAds || !_adsEnabled) {
        _disposeLoadedAds();
        if (scheduleRetryOnFail) _scheduleConsentRetry();
        return;
      }

      _cancelConsentRetry();

      if (!_sdkInitialized) {
        await MobileAds.instance.initialize();
        _sdkInitialized = true;
      }

      if (_interstitialAd == null && !_isInterstitialReady) {
        _preloadInterstitial();
      }
      if (_rewardedAd == null && !_isRewardedReady) {
        _preloadRewarded();
      }
    } catch (_) {
      if (scheduleRetryOnFail) _scheduleConsentRetry();
    } finally {
      _consentRefreshInFlight = false;
    }
  }

  /// Request UMP consent. Returns a Future that completes when consent is
  /// resolved (form shown + dismissed, no form needed, or error).
  Future<void> _requestConsent() async {
    final completer = Completer<void>();

    try {
      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            if (await ConsentInformation.instance.isConsentFormAvailable()) {
              ConsentForm.loadConsentForm(
                (form) {
                  form.show((error) {
                    // Form dismissed (with or without error) → done
                    if (!completer.isCompleted) completer.complete();
                  });
                },
                (error) {
                  // Form failed to load → proceed
                  if (!completer.isCompleted) completer.complete();
                },
              );
            } else {
              // No consent form needed → done
              if (!completer.isCompleted) completer.complete();
            }
          } catch (_) {
            if (!completer.isCompleted) completer.complete();
          }
        },
        (error) {
          // Consent info update failed → proceed
          if (!completer.isCompleted) completer.complete();
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  Future<bool> _canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      return false;
    }
  }

  void _preloadInterstitial() {
    if (!_adsEnabled || !_isAdsPlatformSupported) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              // Ad is now actually visible — safe to notify caller
              _onInterstitialOpened?.call();
              _onInterstitialOpened = null;
            },
            onAdDismissedFullScreenContent: (ad) {
              // ── THE ONLY PLACE the timer is reset ──
              // User closed the ad → record monotonic timestamp.
              _lastAdDismissedMs = _sessionClock.elapsedMilliseconds;
              _interstitialOnScreen = false;
              _onInterstitialClosed?.call();
              _onInterstitialClosed = null;
              _onInterstitialOpened = null;
              ad.dispose();
              _isInterstitialReady = false;
              _interstitialAd = null;
              _preloadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              // Ad failed to render → do NOT reset timer.
              // User never saw the ad, so next eligible death retries.
              _interstitialOnScreen = false;
              _onInterstitialClosed?.call();
              _onInterstitialClosed = null;
              _onInterstitialOpened = null;
              ad.dispose();
              _isInterstitialReady = false;
              _interstitialAd = null;
              _preloadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isInterstitialReady = false;
          // Retry after delay to recover from transient network issues
          Future.delayed(const Duration(seconds: 30), _preloadInterstitial);
        },
      ),
    );
  }

  void _preloadRewarded() {
    if (!_adsEnabled || !_isAdsPlatformSupported) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          onRewardedReadyChanged?.call(true);
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedReady = false;
              onRewardedReadyChanged?.call(false);
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isRewardedReady = false;
              onRewardedReadyChanged?.call(false);
              _preloadRewarded();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isRewardedReady = false;
          onRewardedReadyChanged?.call(false);
          Future.delayed(const Duration(seconds: 30), _preloadRewarded);
        },
      ),
    );
  }

  /// Record a player death and show an interstitial ONLY if ALL of these
  /// are true simultaneously:
  ///   1. Monotonic elapsed ms since last ad dismiss >= threshold (70s)
  ///   2. No interstitial is currently on-screen
  ///   3. Ads are enabled and an interstitial is loaded
  ///
  /// Edge cases handled:
  ///   - Ad on-screen during rapid deaths → guarded by _interstitialOnScreen
  ///   - Ad fails to show → timer NOT reset, next death retries
  ///   - Ad not loaded / no internet → returns false, timer preserved
  ///   - Multiple deaths in < 70s → waits for next death after timer elapses
  ///   - App kill mid-ad → on restart, full 70s grace period applies
  ///   - Clock manipulation → Stopwatch is monotonic, immune to system clock
  ///   - onAdOpened only fires via onAdShowedFullScreenContent callback
  ///     (after ad is actually visible), never prematurely
  ///
  /// Returns true if an ad was successfully dispatched to show.
  Future<bool> recordDeathAndShowIfEligible({
    VoidCallback? onAdOpened,
    VoidCallback? onAdClosed,
  }) async {
    if (!_adsEnabled || !_isAdsPlatformSupported) return false;

    if (_interstitialAd == null || !_isInterstitialReady) {
      _kickAdRecovery();
    }

    // Bail if an ad is already on screen
    if (_interstitialOnScreen) return false;

    final elapsedMs = _sessionClock.elapsedMilliseconds - _lastAdDismissedMs;
    final thresholdMs = GameConstants.interstitialMinIntervalSeconds * 1000;
    final timeThresholdMet = elapsedMs >= thresholdMs;

    if (timeThresholdMet) {
      // Store callbacks — onAdOpened fires only from onAdShowedFullScreenContent
      _onInterstitialOpened = onAdOpened;
      _onInterstitialClosed = onAdClosed;
      final shown = await _showInterstitial();
      if (!shown) {
        // Ad didn't actually appear — clean up and notify caller to resume
        _onInterstitialOpened = null;
        _onInterstitialClosed = null;
        onAdClosed?.call();
      }
      return shown;
    }
    return false;
  }

  /// Internal: display the interstitial. Does NOT touch the timer.
  /// Timer is reset ONLY in onAdDismissedFullScreenContent.
  Future<bool> _showInterstitial() async {
    if (!_adsEnabled ||
        !_isAdsPlatformSupported ||
        !_isInterstitialReady ||
        _interstitialAd == null) {
      return false;
    }
    if (_interstitialOnScreen) return false;

    try {
      _interstitialOnScreen = true;
      await _interstitialAd!.show();
      _isInterstitialReady = false;
      return true;
    } catch (_) {
      // .show() threw — ad never appeared on screen
      _interstitialOnScreen = false;
      _onInterstitialOpened = null;
      _onInterstitialClosed?.call();
      _onInterstitialClosed = null;
      _isInterstitialReady = false;
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _preloadInterstitial();
      return false;
    }
  }

  /// Show rewarded ad. Calls [onRewarded] ONLY if user earns the reward.
  /// Calls [onDismissed] when the ad is closed (regardless of reward).
  /// Returns true if ad was shown, false if unavailable.
  /// Does NOT grant reward on failure — caller must handle false return.
  Future<bool> showRewarded({
    required Function onRewarded,
    VoidCallback? onDismissed,
  }) async {
    if (_rewardedAd == null || !_isRewardedReady) {
      _kickAdRecovery();
    }

    if (!_adsEnabled ||
        !_isAdsPlatformSupported ||
        !_isRewardedReady ||
        _rewardedAd == null) {
      return false;
    }
    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _preloadRewarded();
          onDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _preloadRewarded();
          onDismissed?.call();
        },
      );
      await _rewardedAd!.show(
        onUserEarnedReward: (_, reward) {
          onRewarded();
        },
      );
      _rewardedAd = null;
      _isRewardedReady = false;
      onRewardedReadyChanged?.call(false);
      return true;
    } catch (_) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _isRewardedReady = false;
      onRewardedReadyChanged?.call(false);
      _preloadRewarded();
      return false;
    }
  }

  void dispose() {
    _cancelConsentRetry();
    _sessionClock.stop();
    _disposeLoadedAds();
  }
}
