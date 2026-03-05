import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'app_blocking_config.dart';

/// Service for managing app blocking via platform channels
/// Implements real Android app blocking via AccessibilityService and ForegroundService
class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('com.goalify/app_blocking');
  
  bool _isBlockingActive = false;
  
  /// Check if the current platform is Android
  bool get isAndroid => Platform.isAndroid;
  
  /// Check if the current platform is iOS
  bool get isIOS => Platform.isIOS;
  
  /// Get the current blocking state
  bool get isBlockingActive => _isBlockingActive;

  /// Start app blocking (Android only)
  /// On iOS, this will return false and caller should show message
  /// Returns true if successful, false if there's an error or not supported
  Future<bool> startAppBlocking() async {
    if (!isAndroid) {
      // iOS doesn't support app blocking
      return false;
    }

    try {
      // Send blocked apps list to native Android
      final result = await _channel.invokeMethod('startAppBlocking', {
        'blockedApps': AppBlockingConfig.blockedApps,
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

  /// Stop app blocking (Android only)
  /// Returns true if successful, false if there's an error
  Future<bool> stopAppBlocking() async {
    if (!isAndroid) {
      return true; // Nothing to stop on iOS
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
  bool isAppBlockingSupported() {
    return isAndroid;
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

  /// Pause currently playing music (Android only)
  /// Works with any music app (YouTube, Spotify, etc.)
  /// Returns true if successful
  Future<bool> pauseMusic() async {
    if (!isAndroid) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('pauseMusic');
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
