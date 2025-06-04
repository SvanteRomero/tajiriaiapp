# Goal Model (goal_model.dart)

## Overview
This file defines the data model for financial goals in the Tajiri AI application. It includes enums for goal attributes and a comprehensive Goal class with tracking and calculation capabilities.

## Key Components

### Enumerations

#### GoalPriority
```dart
enum GoalPriority { low, medium, high }
```
- Priority levels
- Task importance
- Goal ranking

#### GoalFrequency
```dart
enum GoalFrequency { daily, weekly, monthly }
```
- Savings frequency
- Contribution schedule
- Time tracking

#### GoalStatus
```dart
enum GoalStatus { active, completed, cancelled }
```
- Goal state
- Progress tracking
- Lifecycle management

### Goal Class
```dart
class Goal {
  final String id;
  final String title;
  final int target;
  final DateTime deadline;
  final String priority;
  final String frequency;
  final String? linkedCategory;
  final String status;
  final DateTime createdAt;
}
```
- Complete goal data
- Status tracking
- Time management

## Core Functionality

### Constructor
```dart
Goal({
  this.id = '',
  required this.title,
  required this.target,
  required this.deadline,
  this.priority = 'Medium',
  this.frequency = 'weekly',
  this.linkedCategory,
  this.status = 'active',
  DateTime? createdAt,
})
```
- Required fields
- Default values
- Validation checks

### Progress Calculation
```dart
double calculateProgress(double currentSavings) {
  return (currentSavings / target).clamp(0.0, 1.0);
}
```
- Progress tracking
- Range clamping
- Percentage calculation

### Achievability Check
```dart
bool isAchievable(double currentSavings) {
  final daysRemaining = deadline.difference(DateTime.now()).inDays;
  // ... calculation logic
}
```
- Time analysis
- Amount checking
- Feasibility assessment

### Required Rate
```dart
double calculateRequiredDailyRate(double currentSavings) {
  // ... calculation logic
}
```
- Daily target
- Rate calculation
- Goal planning

## Best Practices Implemented

1. **Data Validation**
   - Positive targets
   - Future deadlines
   - Type checking

2. **Immutability**
   - Final fields
   - Copy operations
   - Safe updates

3. **Calculations**
   - Progress tracking
   - Rate calculation
   - Achievability check

4. **Storage**
   - Clean conversion
   - Complete mapping
   - Type safety

## Technical Considerations

1. **Performance**
   - Efficient calculations
   - Quick conversions
   - Clean updates

2. **Data Safety**
   - Type checking
   - Null safety
   - Value validation

3. **Usability**
   - Clear API
   - Easy tracking
   - Simple updates

## Implementation Notes

1. **Data Structure**
   ```dart
   // Goal definition
   final String title;
   final int target;
   final DateTime deadline;
   ```
   - Clear fields
   - Proper types
   - Good organization

2. **Validation**
   ```dart
   assert(target > 0, 'Target amount must be positive');
   assert(deadline.isAfter(DateTime.now()), 'Deadline must be in future');
   ```
   - Clear rules
   - Strong checks
   - Good messages

3. **Calculations**
   ```dart
   // Progress calculation
   currentSavings / target
   
   // Daily rate calculation
   remainingAmount / daysRemaining
   ```
   - Clean math
   - Clear logic
   - Good accuracy

## Notes
- Core goal model
- Complete tracking
- Clean calculations
- Good practices
