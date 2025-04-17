import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ai_chat_menu.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({Key? key}) : super(key: key);

  @override
  _ChatHistoryPageState createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<List<ChatMessage>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStrings = prefs.getStringList('chat_sessions') ?? [];
    final sessions =
        sessionStrings.map((s) {
          final list = (jsonDecode(s) as List).cast<Map<String, dynamic>>();
          return list.map((m) => ChatMessage.fromJson(m)).toList();
        }).toList();
    setState(() => _sessions = sessions);
  }

  Future<void> _deleteSession(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionStrings = prefs.getStringList('chat_sessions') ?? [];
    sessionStrings.removeAt(index);
    await prefs.setStringList('chat_sessions', sessionStrings);
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body:
          _sessions.isEmpty
              ? const Center(child: Text('No saved sessions'))
              : ListView.builder(
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final timestamp =
                      session.isNotEmpty
                          ? session.first.timestamp.toLocal()
                          : null;
                  final subtitle =
                      timestamp != null
                          ? timestamp.toString()
                          : 'Session ${index + 1}';
                  return ListTile(
                    title: Text('Session ${index + 1}'),
                    subtitle: Text(subtitle),
                    onTap: () => Navigator.pop(context, session),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSession(index),
                    ),
                  );
                },
              ),
    );
  }
}
