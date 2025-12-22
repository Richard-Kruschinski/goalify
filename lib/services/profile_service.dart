import 'package:flutter/material.dart';
import '../models/profile_model.dart';

// Service: Enthält die gesamte Geschäftslogik
// Keine UI-Elemente, nur Business-Logik und Datenoperationen
class ProfileService {
  // Singleton-Pattern für globalen Zugriff
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Aktuelles Benutzerprofil
  UserProfile? _currentProfile;

  // Getter für das aktuelle Profil
  UserProfile get currentProfile => _currentProfile ?? UserProfile.empty();

  // Geschäftslogik: Benutzerprofil laden
  // In einer echten App würde hier ein API-Call erfolgen
  Future<UserProfile> loadUserProfile() async {
    // Simuliere API-Call
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Echten API-Call implementieren
    _currentProfile = UserProfile.empty();
    return _currentProfile!;
  }

  // Geschäftslogik: Profil aktualisieren
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      // Simuliere API-Call
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: Echten API-Call implementieren
      _currentProfile = profile;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Geschäftslogik: Logout-Prozess
  Future<void> logout(BuildContext context) async {
    try {
      // Simuliere Logout-Logik
      await Future.delayed(const Duration(milliseconds: 300));
      
      // TODO: Echte Logout-Logik implementieren
      // - Token löschen
      // - Lokale Daten bereinigen
      // - Navigation zur Login-Seite
      
      _currentProfile = null;
      
      if (context.mounted) {
        // Zeige Bestätigung
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigation zur Login-Seite (falls vorhanden)
        // Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Geschäftslogik: Menüeinträge definieren und zurückgeben
  // Hier ist die Definition der Menüstruktur zentral verwaltet
  List<ProfileMenuItem> getMenuItems() {
    return const [
      ProfileMenuItem(
        id: 'account',
        title: 'Account',
        subtitle: 'Manage your account settings',
        iconName: 'person_outline',
      ),
      ProfileMenuItem(
        id: 'privacy',
        title: 'Privacy',
        subtitle: 'Privacy and security settings',
        iconName: 'lock_outline',
      ),
      ProfileMenuItem(
        id: 'notifications',
        title: 'Notifications',
        subtitle: 'Customize your notifications',
        iconName: 'notifications_outlined',
      ),
      ProfileMenuItem(
        id: 'settings',
        title: 'Settings',
        subtitle: 'App preferences and options',
        iconName: 'settings_outlined',
      ),
      ProfileMenuItem(
        id: 'help',
        title: 'Help & Support',
        subtitle: 'Get help and contact support',
        iconName: 'help_outline',
      ),
      ProfileMenuItem(
        id: 'about',
        title: 'About',
        subtitle: 'App version and information',
        iconName: 'info_outline',
      ),
    ];
  }

  // Geschäftslogik: Menüaktion ausführen
  void handleMenuAction(BuildContext context, String menuId) {
    // Hier würde die Navigation oder Aktion für jeden Menüpunkt erfolgen
    switch (menuId) {
      case 'account':
        // Navigator.of(context).pushNamed('/account');
        _showComingSoon(context, 'Account Settings');
        break;
      case 'privacy':
        // Navigator.of(context).pushNamed('/privacy');
        _showComingSoon(context, 'Privacy Settings');
        break;
      case 'notifications':
        // Navigator.of(context).pushNamed('/notifications');
        _showComingSoon(context, 'Notification Settings');
        break;
      case 'settings':
        // Navigator.of(context).pushNamed('/settings');
        _showComingSoon(context, 'Settings');
        break;
      case 'help':
        // Navigator.of(context).pushNamed('/help');
        _showComingSoon(context, 'Help & Support');
        break;
      case 'about':
        // Navigator.of(context).pushNamed('/about');
        _showComingSoon(context, 'About');
        break;
    }
  }

  // Hilfsmethode für temporäre "Coming Soon" Meldung
  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Icon-Name zu IconData konvertieren
  // Diese Methode wird von den Widgets verwendet
  IconData getIconData(String iconName) {
    switch (iconName) {
      case 'person_outline':
        return Icons.person_outline;
      case 'lock_outline':
        return Icons.lock_outline;
      case 'notifications_outlined':
        return Icons.notifications_outlined;
      case 'settings_outlined':
        return Icons.settings_outlined;
      case 'help_outline':
        return Icons.help_outline;
      case 'info_outline':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }
}
