import 'package:flutter/material.dart';

class QuestDetailScreen extends StatelessWidget {
  const QuestDetailScreen({super.key, required this.questId});

  final String questId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quest $questId')),
      body: const Center(child: Text('Quest detail (stub)')),
    );
  }
}
