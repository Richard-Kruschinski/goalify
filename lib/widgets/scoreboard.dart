import 'package:flutter/material.dart';
import '../models/member.dart';

class Scoreboard extends StatelessWidget {
  final List<Member> members;
  const Scoreboard({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    final sorted = [...members]..sort((a, b) => b.score.compareTo(a.score));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final m = sorted[i];
        return ListTile(
          leading: Text('#${i + 1}'),
          title: Text(m.name),
          trailing: Text('${m.score}'),
        );
      },
    );
  }
}
