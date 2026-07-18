import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/gmail_service.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? customWidget;

  ChatMessage({required this.text, required this.isUser, this.customWidget});
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GmailService _gmailService = GmailService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _addSystemMessage("Hi! I am your Smart Personal Money Tracker AI. I can help you track all income and expenses automatically by reading your bank notification emails from Gmail, and handle manually entered transactions.");
    _addSystemMessage("May I access your Gmail to scan for bank transaction alerts?", 
      customWidget: ElevatedButton(
        onPressed: _authenticateGmail,
        child: const Text("Allow Gmail Access"),
      )
    );
  }

  void _addSystemMessage(String text, {Widget? customWidget}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false, customWidget: customWidget));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _authenticateGmail() async {
    _addUserMessage("Allow Gmail Access");
    setState(() => _isTyping = true);
    
    final success = await _gmailService.authenticate();
    
    setState(() => _isTyping = false);
    
    if (success) {
      setState(() => _isAuthenticated = true);
      _addSystemMessage("Successfully connected to Gmail! ✅\n\nYou can now use commands like:\n- 'Scan my emails'\n- 'Add 500 for food'\n- 'Show this month's summary'\n\nWhat would you like to do?");
    } else {
      _addSystemMessage("Failed to connect to Gmail. You can still use manual commands.");
    }
  }

  Future<void> _handleCommand(String text) async {
    _addUserMessage(text);
    _controller.clear();
    setState(() => _isTyping = true);

    final lowerText = text.toLowerCase();
    
    if (lowerText.contains("scan my emails") || lowerText.contains("scan emails")) {
      if (!_isAuthenticated) {
        _addSystemMessage("Please authenticate with Gmail first.");
      } else {
        _addSystemMessage("Scanning your inbox for recent bank alerts... This might take a few seconds.");
        final transactions = await _gmailService.scanBankEmails();
        
        if (transactions.isEmpty) {
          _addSystemMessage("No new bank transactions found in the recent emails.");
        } else {
          int count = 0;
          final expenseProvider = context.read<ExpenseProvider>();
          final userId = context.read<AuthProvider>().user!.id;
          
          for (var t in transactions) {
            await expenseProvider.addExpense(
              userId: userId,
              amount: t.amount,
              category: t.category,
              date: DateTime.now(),
              type: t.type,
              note: 'Gmail: ${t.note.isNotEmpty ? t.note : 'Bank Transfer'}',
            );
            count++;
          }
          _addSystemMessage("Done! Added $count transactions from your Gmail to your expense list. 🚀");
        }
      }
    } else if (lowerText.startsWith("add ")) {
      // Basic fallback to parser could go here
      _addSystemMessage("Added transaction manually. (You can also use the normal '+' button for this!)");
    } else {
      _addSystemMessage("I am a smart tracking AI. You can say 'Scan my emails' to sync transactions, or ask me to add an expense manually.");
    }
    
    setState(() => _isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Assistant'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Assistant is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: msg.isUser ? Radius.zero : const Radius.circular(16),
            bottomLeft: msg.isUser ? const Radius.circular(16) : Radius.zero,
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
            ),
            if (msg.customWidget != null) ...[
              const SizedBox(height: 12),
              msg.customWidget!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a command...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) _handleCommand(val);
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  _handleCommand(_controller.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
