/// Predefined transaction categories for both income and expenses
class TransactionCategories {
  static const Map<String, List<String>> incomeCategories = {
    'Salary': ['Regular Income', 'Bonus', 'Overtime'],
    'Business': ['Profit', 'Sales', 'Commission'],
    'Investments': ['Dividends', 'Interest', 'Capital Gains'],
    'Gifts': ['Cash Gifts', 'Rewards'],
    'Other Income': ['Rental', 'Freelance', 'Miscellaneous'],
  };

  static const Map<String, List<String>> expenseCategories = {
    'Housing': ['Rent', 'Mortgage', 'Utilities', 'Maintenance'],
    'Transportation': ['Fuel', 'Public Transport', 'Vehicle Maintenance', 'Parking'],
    'Food': ['Groceries', 'Dining Out', 'Snacks'],
    'Healthcare': ['Medical Bills', 'Medicines', 'Insurance'],
    'Education': ['Tuition', 'Books', 'Courses'],
    'Entertainment': ['Movies', 'Games', 'Hobbies'],
    'Shopping': ['Clothing', 'Electronics', 'Household Items'],
    'Bills': ['Phone', 'Internet', 'Subscriptions'],
    'Personal Care': ['Grooming', 'Fitness', 'Health Products'],
    'Savings': ['Emergency Fund', 'Investments', 'Goals'],
    'Other': ['Miscellaneous', 'Unspecified'],
  };

  /// Get all main categories for a transaction type
  static List<String> getMainCategories(bool isIncome) {
    return isIncome 
        ? incomeCategories.keys.toList()
        : expenseCategories.keys.toList();
  }

  /// Get subcategories for a main category
  static List<String> getSubcategories(String mainCategory, bool isIncome) {
    return isIncome
        ? incomeCategories[mainCategory] ?? []
        : expenseCategories[mainCategory] ?? [];
  }

  /// Check if a category combination is valid
  static bool isValidCategory(String mainCategory, String subCategory, bool isIncome) {
    final categories = isIncome ? incomeCategories : expenseCategories;
    return categories[mainCategory]?.contains(subCategory) ?? false;
  }
}
