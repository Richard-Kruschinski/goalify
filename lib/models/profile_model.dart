// Model: Reine Datenstruktur für Benutzerprofil
// Keine Logik, keine UI - nur Daten
class UserProfile {
  final String name;
  final String email;
  final String? avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  // Factory-Konstruktor für Test/Mock-Daten
  factory UserProfile.empty() {
    return const UserProfile(
      name: 'Your Name',
      email: 'your.email@example.com',
    );
  }

  // Factory-Konstruktor für JSON-Daten (z.B. von API)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}

// Model: Menüeintrag-Datenstruktur
// Definiert die Struktur eines einzelnen Menüeintrags
class ProfileMenuItem {
  final String id;
  final String title;
  final String subtitle;
  final String iconName;

  const ProfileMenuItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
  });
}
