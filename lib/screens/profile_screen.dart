import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 40),
          SizedBox(height: 16),
          Text('Your Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 24),
          ListTile(leading: Icon(Icons.person), title: Text('Account')),
          ListTile(leading: Icon(Icons.lock),   title: Text('Privacy')),
          ListTile(leading: Icon(Icons.settings), title: Text('Settings')),
        ],
      ),
    );
  }
}

