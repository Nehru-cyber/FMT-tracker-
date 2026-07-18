import '../models/expense.dart';

class ParsedTransaction {
  final double amount;
  final String category;
  final ExpenseType type;
  final String source; // where the money came from (for income)
  final String note;

  ParsedTransaction({
    required this.amount,
    required this.category,
    required this.type,
    this.source = '',
    this.note = '',
  });
}

class MessageParserService {
  // Keywords that indicate income
  static const List<String> _incomeKeywords = [
    'credited', 'received', 'deposited', 'refund', 'cashback', 'added',
    'salary', 'income'
  ];

  // Keywords that indicate expense
  static const List<String> _expenseKeywords = [
    'debited', 'sent', 'paid', 'withdrawn', 'deducted', 'transferred to',
    'spent', 'purchased', 'expense', 'bill'
  ];

  // Category mapping based on keywords in message
  static const Map<String, List<String>> _categoryKeywords = {
    'Food & Dining': ['zomato', 'swiggy', 'blinkit', 'dunzo', 'restaurant', 'cafe', 'food', 'pizza', 'burger', 'meal', 'eat'],
    'Transport': ['uber', 'ola', 'rapido', 'irctc', 'makemytrip', 'petrol', 'fuel', 'cab', 'auto', 'bus', 'train', 'flight'],
    'Shopping': ['amazon', 'flipkart', 'myntra', 'meesho', 'nykaa', 'shopping', 'bought', 'purchased', 'clothes'],
    'Subscriptions': ['netflix', 'spotify', 'hotstar', 'youtube', 'jio', 'airtel', 'subscription', 'prime'],
    'Health': ['apollo', 'pharmeasy', 'hospital', 'clinic', 'medicine', 'medical', 'doctor', 'pharmacy', 'health'],
    'Utilities': ['electricity', 'water', 'gas', 'bescom', 'mseb', 'bses', 'bill', 'internet', 'wifi', 'recharge'],
    'Salary / Income': ['salary', 'stipend', 'wages', 'pay day', 'monthly pay'],
    'ATM Withdrawal': ['atm', 'cash withdrawal'],
    'Friends & Family': [], // Handled via special logic
    'Other': ['misc']
  };

  // Source mapping for income
  static const Map<String, List<String>> _sourceKeywords = {
    'Salary / Income': ['salary', 'employer'],
    'Refund': ['refund', 'cashback', 'return'],
    'Other': ['other', 'misc'],
  };

  /// Parse a user message and extract transaction details
  static ParsedTransaction? parseMessage(String message) {
    if (message.trim().isEmpty) return null;

    final lowerMessage = message.toLowerCase().trim();

    // Extract amount from message
    final amount = _extractAmount(lowerMessage);
    if (amount == null || amount <= 0) return null;

    // Determine if income or expense
    final type = _determineType(lowerMessage);

    // Determine category
    final category = _determineCategory(lowerMessage, type);

    // Determine source (for income)
    final source = type == ExpenseType.income ? _determineSource(lowerMessage) : '';

    // Build note from original message
    final note = message.trim();

    return ParsedTransaction(
      amount: amount,
      category: category,
      type: type,
      source: source,
      note: note,
    );
  }

  /// Extract numeric amount from message
  static double? _extractAmount(String message) {
    // Match patterns like: 500, 1000, 5000.50, ₹500, rs 500, rs.500, 5k, 10k, 1.5k
    final patterns = [
      RegExp(r'(?:₹|rs\.?|inr)\s*(\d+(?:\.\d+)?)\s*(?:k|K)?', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:₹|rs|rupees|inr)', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:k|K)\b'),
      RegExp(r'(?:^|\s)(\d+(?:\.\d+)?)(?:\s|$|[,.\!\?])'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        var amountStr = match.group(1)!;
        var amount = double.tryParse(amountStr);
        if (amount == null) continue;

        // Check if 'k' suffix (thousands)
        final fullMatch = match.group(0)!;
        if (fullMatch.toLowerCase().contains('k')) {
          amount *= 1000;
        }

        if (amount > 0) return amount;
      }
    }

    return null;
  }

  /// Determine if the message describes income or expense
  static ExpenseType _determineType(String message) {
    int incomeScore = 0;
    int expenseScore = 0;

    for (final keyword in _incomeKeywords) {
      if (message.contains(keyword)) incomeScore++;
    }

    for (final keyword in _expenseKeywords) {
      if (message.contains(keyword)) expenseScore++;
    }

    return incomeScore > expenseScore ? ExpenseType.income : ExpenseType.expense;
  }

  /// Determine category based on message content
  static String _determineCategory(String message, ExpenseType type) {
    int bestScore = 0;
    String bestCategory = type == ExpenseType.income ? 'Salary / Income' : 'Other';

    // 1. Friends & Family check (Special Logic)
    if (type == ExpenseType.expense) {
      // Look for "sent to [name]", "paid [name]", "transferred to [name]"
      if (RegExp(r'(sent|paid|transferred to)\s+(?:rs\.?|inr|₹)?\s*\d+(?:\.\d+)?\s+(?:to\s+)?([a-z]+)', caseSensitive: false).hasMatch(message)) {
        // We can't perfectly know if it's a name, but if it doesn't match business rules below, it's a strong indicator.
        // Also check for personal UPI IDs (name@bank)
        if (RegExp(r'\b[a-z]{3,}@(okaxis|ybl|ibl|sbi|icici|hdfcbank|paytm|axl)\b', caseSensitive: false).hasMatch(message)) {
          // Exclude known business upi ids
          if (!RegExp(r'(zomato|swiggy|amazon|netflix|flipkart|uber|ola)@', caseSensitive: false).hasMatch(message)) {
            return 'Friends & Family';
          }
        }
      }
      if (message.contains("paid ") && !message.contains("zomato") && !message.contains("swiggy") && !message.contains("amazon") && !message.contains("uber")) {
         // basic fallback
      }
    }

    final relevantCategories = type == ExpenseType.income
        ? ['Salary / Income', 'Refund', 'Other']
        : ['Food & Dining', 'Transport', 'Shopping', 'Subscriptions', 'Health', 'Utilities', 'ATM Withdrawal', 'Friends & Family', 'Other'];

    for (final category in relevantCategories) {
      final keywords = _categoryKeywords[category];
      if (keywords == null) continue;

      int score = 0;
      for (final keyword in keywords) {
        if (message.contains(keyword)) score++;
      }

      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    }
    
    // Additional Friends & Family fallback if no other category matched well
    if (bestCategory == 'Other' && type == ExpenseType.expense) {
       if (RegExp(r'\b[a-z]{3,}@(okaxis|ybl|ibl|sbi|icici|hdfcbank|paytm|axl|upi)\b', caseSensitive: false).hasMatch(message)) {
         return 'Friends & Family';
       }
    }

    return bestCategory;
  }

  /// Determine income source
  static String _determineSource(String message) {
    int bestScore = 0;
    String bestSource = '';

    for (final entry in _sourceKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (message.contains(keyword)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestSource = entry.key;
      }
    }

    return bestSource;
  }
}
