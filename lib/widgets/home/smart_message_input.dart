import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/message_parser_service.dart';

class SmartMessageInput extends StatefulWidget {
  final VoidCallback onTransactionAdded;
  const SmartMessageInput({super.key, required this.onTransactionAdded});

  @override
  State<SmartMessageInput> createState() => _SmartMessageInputState();
}

class _SmartMessageInputState extends State<SmartMessageInput>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;
  ParsedTransaction? _preview;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onMessageChanged(String value) {
    final parsed = MessageParserService.parseMessage(value);
    setState(() => _preview = parsed);
  }

  Future<void> _submitMessage() async {
    if (_preview == null) return;

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    final savedPreview = _preview!;

    await context.read<ExpenseProvider>().addExpense(
      userId: userId,
      amount: savedPreview.amount,
      category: savedPreview.category,
      date: DateTime.now(),
      type: savedPreview.type,
      note: savedPreview.note,
    );

    _messageController.clear();
    setState(() {
      _preview = null;
      _isExpanded = false;
    });
    _animController.reverse();
    _focusNode.unfocus();

    if (mounted) {
      final isIncome = savedPreview.type == ExpenseType.income;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isIncome ? "Income" : "Expense"} of ₹${savedPreview.amount.toStringAsFixed(0)} added to ${savedPreview.category}',
                ),
              ),
            ],
          ),
          backgroundColor: isIncome ? AppTheme.secondaryColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      widget.onTransactionAdded();
    }
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animController.forward();
      _focusNode.requestFocus();
    } else {
      _animController.reverse();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        InkWell(
          onTap: _toggleExpand,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.accentColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Type a message to track...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ),
        // Expandable input area
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hint examples
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Examples:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"Received salary 50000 from company"\n'
                        '"Spent 500 on food at restaurant"\n'
                        '"Paid 2k for electricity bill"\n'
                        '"Got 10000 freelance payment"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Input field
                TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  onChanged: _onMessageChanged,
                  onSubmitted: (_) => _submitMessage(),
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'e.g. "Spent 500 on food"',
                    prefixIcon: const Icon(Icons.message_outlined, size: 20),
                    suffixIcon: _preview != null
                        ? IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: _submitMessage,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                // Preview card
                if (_preview != null) ...[
                  const SizedBox(height: 12),
                  _buildPreviewCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final isIncome = _preview!.type == ExpenseType.income;
    final color = isIncome ? AppTheme.secondaryColor : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isIncome ? 'Income Detected' : 'Expense Detected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '₹${_preview!.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildInfoChip(Icons.category_outlined, _preview!.category),
              if (_preview!.source.isNotEmpty) ...[
                const SizedBox(width: 8),
                _buildInfoChip(Icons.account_balance_outlined, _preview!.source),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitMessage,
              icon: const Icon(Icons.check, size: 18),
              label: Text('Add ${isIncome ? "Income" : "Expense"}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
