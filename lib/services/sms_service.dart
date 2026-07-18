import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'message_parser_service.dart';

@pragma('vm:entry-point')
backgroundMessageHandler(SmsMessage message) async {
  // Background processing could be implemented with Hive directly, 
  // without relying on context/providers.
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<bool> requestPermissions() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == null || !permissionsGranted) {
       var status = await Permission.sms.request();
       return status.isGranted;
    }
    return permissionsGranted;
  }

  static void startListening(BuildContext context, String userId) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _processMessage(message, context, userId);
      },
      onBackgroundMessage: backgroundMessageHandler,
    );
  }

  static Future<void> readInbox(BuildContext context, String userId) async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS permission denied')),
        );
      }
      return;
    }

    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
    );

    int count = 0;
    for (var msg in messages.take(50)) {
      if (msg.body != null && _isBankMessage(msg.body!)) {
        if (await _processMessage(msg, context, userId, isBulk: true)) {
          count++;
        }
      }
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count transactions from SMS')),
      );
    }
  }

  static bool _isBankMessage(String body) {
    final lower = body.toLowerCase();
    return (lower.contains('debited') || lower.contains('credited') || lower.contains('spent') || lower.contains('sent')) &&
           (lower.contains('a/c') || lower.contains('acct') || lower.contains('bank') || lower.contains('rs'));
  }

  static Future<bool> _processMessage(SmsMessage message, BuildContext context, String userId, {bool isBulk = false}) async {
    if (message.body == null) return false;
    
    final parsed = MessageParserService.parseMessage(message.body!);
    if (parsed != null) {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      final date = message.date != null 
          ? DateTime.fromMillisecondsSinceEpoch(message.date!) 
          : DateTime.now();

      await expenseProvider.addExpense(
        userId: userId,
        amount: parsed.amount,
        category: parsed.category,
        date: date,
        type: parsed.type,
        note: 'SMS: ${parsed.note.length > 30 ? parsed.note.substring(0, 30) + '...' : parsed.note}',
      );
      
      if (!isBulk && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-added ${parsed.type == ExpenseType.income ? "Income" : "Expense"}: ₹${parsed.amount}')),
        );
      }
      
      return true;
    }
    return false;
  }
}
