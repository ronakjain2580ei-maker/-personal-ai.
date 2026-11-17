import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const PersonalAIApp());

class PersonalAIApp extends StatelessWidget {
  const PersonalAIApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Personal AI',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6688FF), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      useMaterial3: true,
    ),
    home: const ChatPage(),
  );
}

class Message {
  Message(this.role, this.text);
  final String role;
  final String text;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _messages = [
    Message('assistant', 'Hello! I am Personal AI. I can help with general questions, programming, debugging and app development. Add your AI provider settings to start chatting.')
  ];
  bool _busy = false;
  String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  String _apiKey = '';
  String _model = 'openai/gpt-4o-mini';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _apiUrl = p.getString('apiUrl') ?? _apiUrl;
      _apiKey = p.getString('apiKey') ?? '';
      _model = p.getString('model') ?? _model;
    });
  }

  Future<void> _settings() async {
    final url = TextEditingController(text: _apiUrl);
    final key = TextEditingController(text: _apiKey);
    final model = TextEditingController(text: _model);
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('AI provider settings'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: url, decoration: const InputDecoration(labelText: 'Chat completions URL')),
        TextField(controller: model, decoration: const InputDecoration(labelText: 'Model name')),
        TextField(controller: key, obscureText: true, decoration: const InputDecoration(labelText: 'API key')),
        const SizedBox(height: 8),
        const Text('Use an OpenAI-compatible provider. Your key is stored on this device. Never share it.', style: TextStyle(fontSize: 12, color: Colors.white70)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final p = await SharedPreferences.getInstance();
          await p.setString('apiUrl', url.text.trim());
          await p.setString('apiKey', key.text.trim());
          await p.setString('model', model.text.trim());
          setState(() { _apiUrl = url.text.trim(); _apiKey = key.text.trim(); _model = model.text.trim(); });
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    _controller.clear();
    setState(() { _messages.add(Message('user', text)); _busy = true; });
    _jump();
    if (_apiKey.isEmpty) {
      setState(() { _messages.add(Message('assistant', 'To activate AI responses, open the settings (top-right), choose an OpenAI-compatible provider, and add your API URL, model and API key.')); _busy = false; });
      _jump();
      return;
    }
    try {
      final history = _messages.where((m) => m.role == 'user' || m.role == 'assistant')
        .map((m) => {'role': m.role, 'content': m.text}).toList();
      final response = await http.post(Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'You are Personal AI, a knowledgeable, accurate assistant. You are especially strong at programming and app development. Explain clearly, ask clarifying questions when needed, and never claim to have run code unless you actually have.'},
            ...history,
          ],
          'temperature': 0.4,
        })).timeout(const Duration(seconds: 90));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Provider returned HTTP ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final answer = data['choices'][0]['message']['content']?.toString() ?? 'I could not read the response.';
      setState(() => _messages.add(Message('assistant', answer)));
    } catch (e) {
      setState(() => _messages.add(Message('assistant', 'I could not reach the AI service. Check your internet, API URL, model and API key. Details: $e')));
    } finally {
      setState(() => _busy = false);
      _jump();
    }
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [Icon(Icons.auto_awesome, color: Color(0xFF91A8FF)), SizedBox(width: 10), Text('Personal AI')]),
      actions: [IconButton(onPressed: _settings, icon: const Icon(Icons.tune), tooltip: 'AI settings')],
    ),
    body: Column(children: [
      Expanded(child: ListView.builder(
        controller: _scroll, padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        itemCount: _messages.length + (_busy ? 1 : 0),
        itemBuilder: (context, i) {
          if (_busy && i == _messages.length) return const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.all(12), child: Text('Personal AI is thinking…', style: TextStyle(color: Colors.white60))));
          final m = _messages[i];
          final user = m.role == 'user';
          return Align(alignment: user ? Alignment.centerRight : Alignment.centerLeft, child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: user ? const Color(0xFF344C91) : const Color(0xFF1B2438), borderRadius: BorderRadius.circular(18)),
            child: SelectableText(m.text, style: const TextStyle(fontSize: 15, height: 1.4)),
          ));
        },
      )),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: Row(children: [
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 5, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
          decoration: InputDecoration(hintText: 'Ask anything or paste code…', filled: true, fillColor: const Color(0xFF182238), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _busy ? null : _send, icon: const Icon(Icons.arrow_upward), tooltip: 'Send'),
      ]))),
    ]),
  );

  @override
  void dispose() { _controller.dispose(); _scroll.dispose(); super.dispose(); }
}
