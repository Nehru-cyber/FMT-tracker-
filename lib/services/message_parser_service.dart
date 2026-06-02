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
    'salary', 'received', 'got', 'earned', 'income', 'paid me',
    'credited', 'bonus', 'freelance', 'payment received', 'refund',
    'cashback', 'dividend', 'interest', 'gift received', 'won',
  ];

  // Keywords that indicate expense
  static const List<String> _expenseKeywords = [
    'spent', 'paid', 'bought', 'purchased', 'expense', 'bill',
    'emi', 'rent', 'food', 'petrol', 'fuel', 'grocery', 'groceries',
    'shopping', 'recharge', 'movie', 'ticket', 'ordered', 'ate',
    'dinner', 'lunch', 'breakfast', 'snack', 'coffee', 'tea',
    'uber', 'ola', 'cab', 'auto', 'bus', 'train', 'flight',
    'medicine', 'doctor', 'hospital', 'gym', 'subscription',
    'netflix', 'amazon', 'swiggy', 'zomato', 'electricity',
    'water', 'gas', 'internet', 'mobile', 'phone',
  ];

  // Category mapping based on keywords in message
  static const Map<String, List<String>> _categoryKeywords = {
    'Food': ['food', 'restaurant', 'ate', 'dinner', 'lunch', 'breakfast',
             'snack', 'coffee', 'tea', 'swiggy', 'zomato', 'ordered',
             'biryani', 'pizza', 'burger', 'meal', 'eat', 'grocery', 'groceries'],
    'Travel': ['travel', 'uber', 'ola', 'cab', 'auto', 'bus', 'train',
               'flight', 'petrol', 'fuel', 'diesel', 'toll', 'parking'],
    'Rent': ['rent', 'house rent', 'room rent', 'pg'],
    'Shopping': ['shopping', 'bought', 'purchased', 'amazon', 'flipkart',
                 'clothes', 'shoes', 'dress', 'shirt', 'pant'],
    'Medical': ['medical', 'medicine', 'doctor', 'hospital', 'pharmacy',
                'health', 'clinic', 'test', 'checkup'],
    'Entertainment': ['movie', 'netflix', 'hotstar', 'prime', 'game',
                      'party', 'outing', 'fun', 'concert', 'show'],
    'Bills': ['bill', 'electricity', 'water', 'gas', 'internet', 'wifi',
              'mobile', 'phone', 'recharge', 'emi', 'insurance', 'subscription'],
    'Education': ['education', 'course', 'book', 'tuition', 'class',
                  'exam', 'fee', 'fees', 'college', 'school', 'udemy'],
    'Salary': ['salary', 'wages', 'pay day', 'monthly pay'],
    'Freelance': ['freelance', 'project', 'client', 'gig', 'side hustle',
                  'contract', 'consulting'],
    'Investment': ['investment', 'dividend', 'interest', 'mutual fund',
                   'stocks', 'shares', 'sip', 'fd', 'rd'],
    'Gift': ['gift', 'birthday', 'present', 'received gift', 'won'],
  };

  // Source mapping for income
  static const Map<String, List<String>> _sourceKeywords = {
    'Company/Job': ['salary', 'company', 'office', 'job', 'work', 'employer'],
    'Freelance': ['freelance', 'project', 'client', 'gig', 'contract'],
    'Business': ['business', 'shop', 'store', 'sales', 'revenue'],
    'Investment': ['investment', 'dividend', 'interest', 'mutual fund', 'stocks', 'sip'],
    'Gift': ['gift', 'birthday', 'won', 'lottery', 'reward'],
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
    String bestCategory = type == ExpenseType.income ? 'Salary' : 'Other';

    final relevantCategories = type == ExpenseType.income
        ? ['Salary', 'Freelance', 'Investment', 'Gift']
        : ['Food', 'Travel', 'Rent', 'Shopping', 'Medical', 'Entertainment', 'Bills', 'Education'];

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
