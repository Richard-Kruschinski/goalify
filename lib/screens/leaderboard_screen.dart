import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboard = [
      {"name": "Joshua Garcia", "time": "1:21", "pace": "4:34/mi", "avatar": "https://i.pravatar.cc/150?img=1"},
      {"name": "Evelyn Carter", "time": "1:25", "pace": "4:40/mi", "avatar": "https://i.pravatar.cc/150?img=2"},
      {"name": "Matthew Thompson", "time": "1:29", "pace": "4:45/mi", "avatar": "https://i.pravatar.cc/150?img=3"},
      {"name": "You", "time": "1:33", "pace": "4:51/mi", "avatar": "https://i.pravatar.cc/150?img=4"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboards')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _leaderboardCard(
            leaderboard[0]["name"]!, leaderboard[0]["time"]!, leaderboard[0]["pace"]!, leaderboard[0]["avatar"]!, true,
          ),
          const SizedBox(height: 8),
          for (var i = 1; i < leaderboard.length; i++)
            _leaderboardCard(
              leaderboard[i]["name"]!, leaderboard[i]["time"]!, leaderboard[i]["pace"]!, leaderboard[i]["avatar"]!, false,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _leaderboardCard(String name, String time, String pace, String avatarUrl, bool highlight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? Colors.pink.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(avatarUrl), radius: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(pace, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
