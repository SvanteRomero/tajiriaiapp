// lib/core/data/default_categories.dart
import 'package:flutter/material.dart';
import '/core/models/transaction_model.dart';
import '/core/models/user_category_model.dart';

List<UserCategory> defaultCategories = [
  // Income Categories
  UserCategory(
    name: 'Salary',
    type: TransactionType.income,
    colorHex: '4CAF50', // Green
    iconCodePoint: Icons.work.codePoint.toString(),
  ),
  UserCategory(
    name: 'Business',
    type: TransactionType.income,
    colorHex: '2196F3', // Blue
    iconCodePoint: Icons.business.codePoint.toString(),
  ),
  UserCategory(
    name: 'Investments',
    type: TransactionType.income,
    colorHex: 'FFC107', // Amber
    iconCodePoint: Icons.trending_up.codePoint.toString(),
  ),
  UserCategory(
    name: 'Freelance / Side Hustle',
    type: TransactionType.income,
    colorHex: 'FF5722', // Deep Orange
    iconCodePoint: Icons.computer.codePoint.toString(),
  ),
  UserCategory(
    name: 'Gifts & Donations',
    type: TransactionType.income,
    colorHex: 'E91E63', // Pink
    iconCodePoint: Icons.card_giftcard.codePoint.toString(),
  ),
  UserCategory(
    name: 'Rental Income',
    type: TransactionType.income,
    colorHex: '795548', // Brown
    iconCodePoint: Icons.home.codePoint.toString(),
  ),
  UserCategory(
    name: 'Refunds & Reimbursements',
    type: TransactionType.income,
    colorHex: '607D8B', // Blue Grey
    iconCodePoint: Icons.refresh.codePoint.toString(),
  ),
  UserCategory(
    name: 'Government Support',
    type: TransactionType.income,
    colorHex: '00BCD4', // Cyan
    iconCodePoint: Icons.account_balance.codePoint.toString(),
  ),
  UserCategory(
    name: 'Other Income',
    type: TransactionType.income,
    colorHex: '9E9E9E', // Grey
    iconCodePoint: Icons.category.codePoint.toString(),
  ),

  // Expense Categories
  UserCategory(
    name: 'Rent / Mortgage',
    type: TransactionType.expense,
    colorHex: 'F44336', // Red
    iconCodePoint: Icons.home_work.codePoint.toString(),
  ),
  UserCategory(
    name: 'Utilities',
    type: TransactionType.expense,
    colorHex: '03A9F4', // Light Blue
    iconCodePoint: Icons.electrical_services.codePoint.toString(),
  ),
  UserCategory(
    name: 'Groceries',
    type: TransactionType.expense,
    colorHex: '8BC34A', // Light Green
    iconCodePoint: Icons.local_grocery_store.codePoint.toString(),
  ),
  UserCategory(
    name: 'Transportation',
    type: TransactionType.expense,
    colorHex: '673AB7', // Deep Purple
    iconCodePoint: Icons.commute.codePoint.toString(),
  ),
  UserCategory(
    name: 'Insurance',
    type: TransactionType.expense,
    colorHex: '3F51B5', // Indigo
    iconCodePoint: Icons.shield.codePoint.toString(),
  ),
  UserCategory(
    name: 'Healthcare',
    type: TransactionType.expense,
    colorHex: '009688', // Teal
    iconCodePoint: Icons.local_hospital.codePoint.toString(),
  ),
  UserCategory(
    name: 'Loan Payments',
    type: TransactionType.expense,
    colorHex: 'FF9800', // Orange
    iconCodePoint: Icons.payment.codePoint.toString(),
  ),
  UserCategory(
    name: 'Dining Out / Restaurants',
    type: TransactionType.expense,
    colorHex: 'FF5722', // Deep Orange
    iconCodePoint: Icons.restaurant.codePoint.toString(),
  ),
  UserCategory(
    name: 'Entertainment',
    type: TransactionType.expense,
    colorHex: 'E91E63', // Pink
    iconCodePoint: Icons.movie.codePoint.toString(),
  ),
  UserCategory(
    name: 'Shopping',
    type: TransactionType.expense,
    colorHex: '9C27B0', // Purple
    iconCodePoint: Icons.shopping_bag.codePoint.toString(),
  ),
  UserCategory(
    name: 'Subscriptions',
    type: TransactionType.expense,
    colorHex: '2196F3', // Blue
    iconCodePoint: Icons.subscriptions.codePoint.toString(),
  ),
  UserCategory(
    name: 'Travel / Vacations',
    type: TransactionType.expense,
    colorHex: '4CAF50', // Green
    iconCodePoint: Icons.flight.codePoint.toString(),
  ),
  UserCategory(
    name: 'Savings & Investments',
    type: TransactionType.expense,
    colorHex: '00BCD4', // Cyan
    iconCodePoint: Icons.savings.codePoint.toString(),
  ),
  UserCategory(
    name: 'Emergency Fund',
    type: TransactionType.expense,
    colorHex: 'F44336', // Red
    iconCodePoint: Icons.emergency.codePoint.toString(),
  ),
  UserCategory(
    name: 'Debt Repayment',
    type: TransactionType.expense,
    colorHex: 'FFC107', // Amber
    iconCodePoint: Icons.credit_card_off.codePoint.toString(),
  ),
  UserCategory(
    name: 'Bank Fees',
    type: TransactionType.expense,
    colorHex: '607D8B', // Blue Grey
    iconCodePoint: Icons.account_balance_wallet.codePoint.toString(),
  ),
  UserCategory(
    name: 'Education',
    type: TransactionType.expense,
    colorHex: '795548', // Brown
    iconCodePoint: Icons.school.codePoint.toString(),
  ),
  UserCategory(
    name: 'Childcare / School Fees',
    type: TransactionType.expense,
    colorHex: '8BC34A', // Light Green
    iconCodePoint: Icons.child_care.codePoint.toString(),
  ),
  UserCategory(
    name: 'Gifts',
    type: TransactionType.expense,
    colorHex: 'E91E63', // Pink
    iconCodePoint: Icons.cake.codePoint.toString(),
  ),
  UserCategory(
    name: 'Donations / Tithes',
    type: TransactionType.expense,
    colorHex: '4CAF50', // Green
    iconCodePoint: Icons.volunteer_activism.codePoint.toString(),
  ),
  UserCategory(
    name: 'Pets',
    type: TransactionType.expense,
    colorHex: 'FF9800', // Orange
    iconCodePoint: Icons.pets.codePoint.toString(),
  ),
  UserCategory(
    name: 'Miscellaneous',
    type: TransactionType.expense,
    colorHex: '9E9E9E', // Grey
    iconCodePoint: Icons.category.codePoint.toString(),
  ),
];