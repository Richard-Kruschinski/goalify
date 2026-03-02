import 'dart:io';
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
    } on PlatformException catch (_) {
      _isBlockingActive = false;
      return false;
    } catch (_) {
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
}
