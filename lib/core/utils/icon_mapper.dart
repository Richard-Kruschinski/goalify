import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Icon Mapper - zentralisierte Verwaltung aller verfügbaren Icons
/// Wird sowohl von gym_screen als auch daily_tasks_screen verwendet
class IconMapper {
  static final List<IconData> _cache = [];
  static bool _isInitialized = false;

  /// Icons die nur für Gym Days zur Verfügung stehen
  static const List<String> _gymOnlyIcons = [
    'kitesurfing',
    'snowboarding',
    'skateboarding',
    'sledding',
  ];

  /// Alle verfügbaren Icons laden (aus assets/icons.json)
  static Future<List<IconData>> loadAvailableIcons() async {
    if (_isInitialized) return _cache;

    try {
      final jsonString = await rootBundle.loadString('assets/icons.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final iconNames = List<String>.from(jsonData['icons'] ?? []);

      _cache.clear();
      for (final name in iconNames) {
        final icon = _iconFromString(name);
        _cache.add(icon);
      }

      _isInitialized = true;
      return _cache;
    } catch (e) {
      // Fallback auf Default-Icons wenn JSON nicht geladen wird
      return _getDefaultIcons();
    }
  }

  /// Icons nur für Daily Tasks (ohne sport-spezifische)
  static Future<List<IconData>> getTaskIcons() async {
    final all = await loadAvailableIcons();
    return all; // Bei Bedarf kann hier auch gefiltert werden
  }

  /// Icons für Gym Days (komplette Liste)
  static Future<List<IconData>> getGymIcons() async {
    return await loadAvailableIcons();
  }

  /// Icon aus String-Name konvertieren
  static IconData _iconFromString(String name) {
    switch (name) {
      // Sports
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;
      case 'sports_martial_arts':
        return Icons.sports_martial_arts;
      case 'sports_kabaddi':
        return Icons.sports_kabaddi;
      case 'accessibility_new':
        return Icons.accessibility_new;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'directions_run':
        return Icons.directions_run;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'downhill_skiing':
        return Icons.downhill_skiing;
      case 'pool':
        return Icons.pool;
      case 'sports_baseball':
        return Icons.sports_baseball;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_cricket':
        return Icons.sports_cricket;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'sports_football':
        return Icons.sports_football;
      case 'sports_golf':
        return Icons.sports_golf;
      case 'sports_handball':
        return Icons.sports_handball;
      case 'sports_hockey':
        return Icons.sports_hockey;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'sports_motorsports':
        return Icons.sports_motorsports;
      case 'sports_rugby':
        return Icons.sports_rugby;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'sports_volleyball':
        return Icons.sports_volleyball;
      case 'sports':
        return Icons.sports;
      case 'rowing':
        return Icons.rowing;
      case 'kayaking':
        return Icons.kayaking;
      case 'surfing':
        return Icons.surfing;
      case 'sailing':
        return Icons.sailing;
      case 'kitesurfing':
        return Icons.kitesurfing;
      case 'snowboarding':
        return Icons.snowboarding;
      case 'skateboarding':
        return Icons.skateboarding;
      case 'sledding':
        return Icons.sledding;

      // Food & Dining
      case 'icecream':
        return Icons.icecream;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'fastfood':
        return Icons.fastfood;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_dining':
        return Icons.local_dining;

      // Shopping
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'shopping_bag':
        return Icons.shopping_bag;

      // Calendar & Time
      case 'event_note':
        return Icons.event_note;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'today':
        return Icons.today;
      case 'calendar_month':
        return Icons.calendar_month;
      case 'schedule':
        return Icons.schedule;
      case 'access_time':
        return Icons.access_time;
      case 'timer':
        return Icons.timer;
      case 'alarm':
        return Icons.alarm;

      // Rating & Achievement
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'grade':
        return Icons.grade;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'military_tech':
        return Icons.military_tech;
      case 'workspace_premium':
        return Icons.workspace_premium;

      // Science & Status
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'bolt':
        return Icons.bolt;
      case 'flash_on':
        return Icons.flash_on;

      // Others
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'nights_stay':
        return Icons.nights_stay;
      case 'diamond':
        return Icons.diamond;
      case 'verified':
        return Icons.verified;
      case 'shield':
        return Icons.shield;
      case 'security':
        return Icons.security;
      case 'lock':
        return Icons.lock;
      case 'vpn_key':
        return Icons.vpn_key;
      case 'flag':
        return Icons.flag;
      case 'outlined_flag':
        return Icons.outlined_flag;
      case 'assistant_photo':
        return Icons.assistant_photo;
      case 'api':
        return Icons.api;
      case 'adb':
        return Icons.adb;
      case 'power':
        return Icons.power;
      case 'power_settings_new':
        return Icons.power_settings_new;
      case 'label':
        return Icons.label;
      case 'label_important':
        return Icons.label_important;
      case 'bookmark':
        return Icons.bookmark;
      case 'push_pin':
        return Icons.push_pin;
      case 'whatshot':
        return Icons.whatshot;
      case 'where_to_vote':
        return Icons.where_to_vote;
      case 'trip_origin':
        return Icons.trip_origin;
      case 'adjust':
        return Icons.adjust;
      case 'animation':
        return Icons.animation;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'attractions':
        return Icons.attractions;
      case 'celebration':
        return Icons.celebration;

      // People
      case 'account_circle':
        return Icons.account_circle;
      case 'face':
        return Icons.face;
      case 'mood':
        return Icons.mood;
      case 'sentiment_very_satisfied':
        return Icons.sentiment_very_satisfied;
      case 'psychology':
        return Icons.psychology;

      // Analytics
      case 'trending_up':
        return Icons.trending_up;
      case 'show_chart':
        return Icons.show_chart;
      case 'insights':
        return Icons.insights;
      case 'analytics':
        return Icons.analytics;

      // Education & Learning
      case 'school':
        return Icons.school;
      case 'library_books':
        return Icons.library_books;
      case 'book':
        return Icons.book;

      // Nature
      case 'local_florist':
        return Icons.local_florist;

      // Sleep & Wellness
      case 'bedtime':
        return Icons.bedtime;
      case 'spa':
        return Icons.spa;

      default:
        return Icons.check_circle_outline;
    }
  }

  /// Fallback Icons wenn JSON nicht geladen wird
  static List<IconData> _getDefaultIcons() {
    return [
      Icons.fitness_center,
      Icons.sports_gymnastics,
      Icons.sports_martial_arts,
      Icons.accessibility_new,
      Icons.self_improvement,
      Icons.directions_run,
      Icons.directions_walk,
      Icons.pool,
      Icons.sports_baseball,
      Icons.sports_basketball,
      Icons.sports_soccer,
      Icons.sports_tennis,
      Icons.favorite,
      Icons.star,
      Icons.schedule,
      Icons.shopping_cart,
      Icons.local_cafe,
      Icons.book,
      Icons.school,
      Icons.mood,
      Icons.emoji_events,
      Icons.trending_up,
    ];
  }

  /// Icon aus IconData zurück zu String-Name
  static String? iconToString(IconData icon) {
    final codePoint = icon.codePoint;
    // Diese Mapping müssten alle Icons aus der JSON abdecken
    // Für Vereinfachung kann man auch nur die codePoints vergleichen
    final allIcons = _cache.isNotEmpty ? _cache : _getDefaultIcons();
    for (int i = 0; i < allIcons.length; i++) {
      if (allIcons[i].codePoint == codePoint) {
        return 'icon_$i';
      }
    }
    return null;
  }

  /// Cache zurücksetzen (z.B. nach Theme-Wechsel)
  static void reset() {
    _cache.clear();
    _isInitialized = false;
  }
}
