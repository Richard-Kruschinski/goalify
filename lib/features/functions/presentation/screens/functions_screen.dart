import 'package:flutter/material.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: const Text(
          'Functions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: const [
          FunctionCard(
            title: 'Distraction Blocker',
            subtitle: 'Block distracting apps and stay focused',
            icon: Icons.block,
            iconBackgroundColor: Color(0xFFE8D6F7),
          ),
          SizedBox(height: 16),
          FunctionCard(
            title: 'Music Timer',
            subtitle: 'Play music with a countdown timer',
            icon: Icons.music_note,
            iconBackgroundColor: Color(0xFFFEE8D1),
          ),
          SizedBox(height: 16),
          FunctionCard(
            title: 'Pomodoro Timer',
            subtitle: 'Work in focused intervals with breaks',
            icon: Icons.timer,
            iconBackgroundColor: Color(0xFFFFE8E8),
          ),
          SizedBox(height: 16),
          FunctionCard(
            title: 'Deep Work Mode',
            subtitle: 'Eliminate distractions and enter flow state',
            icon: Icons.psychology,
            iconBackgroundColor: Color(0xFFD6E8FF),
          ),
        ],
      ),
    );
  }
}

class FunctionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;

  const FunctionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming Soon')),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading Icon
              Container(
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: Colors.grey[800],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Trailing Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
