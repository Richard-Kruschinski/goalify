import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_blocking_config.dart';

/// Service for managing app blocking via platform channels
/// Android: real app blocking via AccessibilityService and ForegroundService
/// iOS: Apple's Screen Time API (FamilyControls + ManagedSettings, iOS 16+)
class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.goalify/app_blocking');
  
  bool _isBlockingActive = false;
  
  /// Check if the current platform is Android
  bool get isAndroid => Platform.isAndroid;
  
  /// Check if the current platform is iOS
  bool get isIOS => Platform.isIOS;
  
  /// Get the current blocking state
  bool get isBlockingActive => _isBlockingActive;

  /// Start app blocking
  /// Android: sends the static blocklist to the AccessibilityService
  /// iOS: shields the apps the user picked via the Screen Time app picker
  /// Returns true if successful, false if there's an error or not supported
  Future<bool> startAppBlocking() async {
    if (!isAndroid && !isIOS) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('startAppBlocking', {
        if (isAndroid) 'blockedApps': AppBlockingConfig.blockedApps,
      });

      _isBlockingActive = result == true;
      return _isBlockingActive;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformException while starting app blocking: ${e.code} - ${e.message}');
      }
      _isBlockingActive = false;
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting app blocking: $e');
      }
      _isBlockingActive = false;
      return false;
    }
  }

  /// Stop app blocking
  /// Returns true if successful, false if there's an error
  Future<bool> stopAppBlocking() async {
    if (!isAndroid && !isIOS) {
      return true; // Nothing to stop on other platforms
    }

    try {
      final result = await _channel.invokeMethod('stopAppBlocking');
      _isBlockingActive = !(result == true);
      return result == true;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if app blocking is supported on this platform
  /// Note: on iOS blocking additionally requires iOS 16+; use
  /// [isAppBlockingAvailable] for the runtime check.
  bool isAppBlockingSupported() {
    return isAndroid || isIOS;
  }

  /// Runtime check whether blocking is actually available on this device
  /// (on iOS this verifies the OS version is 16 or newer)
  Future<bool> isAppBlockingAvailable() async {
    if (isAndroid) return true;
    if (!isIOS) return false;

    try {
      final result = await _channel.invokeMethod('isAppBlockingSupported');
      return result == true;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Request Screen Time (Family Controls) authorization (iOS only)
  /// Returns true if the user granted access
  Future<bool> requestScreenTimeAuthorization() async {
    if (!isIOS) return isAndroid;

    try {
      final result = await _channel.invokeMethod('requestScreenTimeAuthorization');
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformException requesting Screen Time authorization: ${e.code}');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Current Screen Time authorization status (iOS only):
  /// "approved", "denied" or "notDetermined"
  Future<String> getScreenTimeAuthorizationStatus() async {
    if (!isIOS) return 'approved';

    try {
      final result = await _channel.invokeMethod('getScreenTimeAuthorizationStatus');
      return result is String ? result : 'notDetermined';
    } on PlatformException catch (_) {
      return 'notDetermined';
    } catch (_) {
      return 'notDetermined';
    }
  }

  /// Open Apple's system app picker so the user chooses which apps to block
  /// (iOS only). Returns the new selection count, or null if cancelled.
  Future<int?> selectAppsToBlock({
    required String doneLabel,
    required String cancelLabel,
  }) async {
    if (!isIOS) return null;

    try {
      final result = await _channel.invokeMethod('selectAppsToBlock', {
        'doneLabel': doneLabel,
        'cancelLabel': cancelLabel,
      });
      if (result is int) {
        return result >= 0 ? result : null; // -1 = cancelled
      }
      return null;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformException while selecting apps: ${e.code} - ${e.message}');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Number of apps/categories the user selected for blocking (iOS only)
  Future<int> getBlockedSelectionCount() async {
    if (!isIOS) return 0;

    try {
      final result = await _channel.invokeMethod('getBlockedSelectionCount');
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } on PlatformException catch (_) {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Check if accessibility service is enabled (Android only)
  Future<bool> isAccessibilityServiceEnabled() async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result == true;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Open accessibility settings (Android only)
  /// Helps user enable the accessibility service
  Future<void> openAccessibilitySettings() async {
    if (!isAndroid) {
      return;
    }

    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (_) {
      // Accessibility settings error
    } catch (_) {
      // Accessibility settings error
    }
  }

  /// Get how many blocked-app launch attempts were prevented (Android only)
  Future<int> getBlockedAttemptsCount() async {
    if (!isAndroid) {
      return 0;
    }

    try {
      final result = await _channel.invokeMethod('getBlockedAttemptsCount');
      if (result is int) {
        return result;
      }
      if (result is num) {
        return result.toInt();
      }
      return 0;
    } on PlatformException catch (_) {
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Pause currently playing music (Android only)
  /// Works with any music app (YouTube, Spotify, etc.)
  /// Fades volume to zero, pauses playback, then restores previous volume
  /// Returns true if successful
  Future<bool> pauseMusic() async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('pauseMusic', {
        'fadeDurationMs': 4000,
        'restoreDelayMs': 800,
      });
      return result == true;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('PlatformException while pausing music: ${e.code} - ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing music: $e');
      }
      return false;
    }
  }

  /// Check if music is currently playing (Android only)
  Future<bool> isMusicPlaying() async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('isMusicPlaying');
      return result == true;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
