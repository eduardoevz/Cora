import 'package:flutter/material.dart';
import 'package:mobile/features/assistant/domain/models/assistant_models.dart';
import 'package:mobile/features/assistant/presentation/widgets/citation_chips_and_emergency_banner.dart';

class CoraAssistantChatPage extends StatefulWidget {
  const CoraAssistantChatPage({
    super.key,
    required this.initialMessages,
    this.onSendMessage,
    this.onCitationSelected,
  });

  final List<AssistantMessage> initialMessages;
  final Future<AssistantMessage> Function(String query)? onSendMessage;
  final void Function(ClinicalCitation citation)? onCitationSelected;

  @override
  State<CoraAssistantChatPage> createState() => _CoraAssistantChatPageState();
}

class _CoraAssistantChatPageState extends State<CoraAssistantChatPage> {
  late final List<AssistantMessage> _messages;
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = List<AssistantMessage>.from(widget.initialMessages);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }
    _controller.clear();
    final userMsg = AssistantMessage(
      id: 'local-user-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: 'active-conversation',
      role: 'user',
      contentMarkdown: text,
      citations: const [],
      safetyTriageCategory: 'NONE',
      isEmergencyIntercepted: false,
      disclaimerLevel: 'STANDARD',
      suggestedFollowUps: const [],
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isSending = true;
    });

    if (widget.onSendMessage != null) {
      final reply = await widget.onSendMessage!(text);
      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isSending = false;
        });
      }
    } else {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Clínico Cora'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.teal.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Orientación educativa basada en evidencia científica (OMS, ACOG, FIGO, NAMS). No reemplaza una consulta médica.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                if (msg.isEmergencyIntercepted) {
                  return EmergencyDirectiveBanner(
                    triageCategory: msg.safetyTriageCategory,
                    directiveMarkdown: msg.contentMarkdown,
                  );
                }
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.teal.shade700
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.contentMarkdown,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (!isUser && msg.citations.isNotEmpty)
                          CitationChips(
                            citations: msg.citations,
                            onCitationTap: widget.onCitationSelected,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('assistant_query_input'),
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu duda sobre tu ciclo o etapa...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: const Key('assistant_send_button'),
                  icon: const Icon(Icons.send),
                  onPressed: _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
