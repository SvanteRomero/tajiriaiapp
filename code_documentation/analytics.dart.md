# Analytics Page (analytics.dart)

## Overview
This file implements the financial analytics interface for the Tajiri AI application. It provides visual representations of transaction data through charts and metrics, helping users understand their financial patterns.

## Key Components

### CategoryData Class
```dart
class CategoryData {
  final String category;
  final double value;
  CategoryData({required this.category, required this.value});
}
```
- Data structure
- Category totals
- Value tracking

### Analytics Widget
```dart
class Analytics extends StatelessWidget {
  final User user;
  const Analytics({Key? key, required this.user}) : super(key: key);
}
```
- Visual analytics
- Real-time data
- Interactive charts

## Core Functionality

### Data Processing
```dart
List<CategoryData> _topCategories(List<Transaction> txs, {
  required bool isIncome,
  int topN = 3
}) {
  // Calculate totals
  // Sort categories
  // Return top N
}
```
- Category analysis
- Data aggregation
- Top metrics

### Time Analysis
```dart
List<Map<String, double>> _aggregateByDayOfWeek(List<Transaction> txs) {
  // Group by day
  // Calculate totals
  // Format data
}
```
- Daily trends
- Weekly patterns
- Clear visualization

## UI Components

### Metric Cards
```dart
Widget _styledMetricCard(String title, String value, String label, Color accent) {
  return Card(
    // Visual styling
    // Data display
    // Color theming
  );
}
```
- Key metrics
- Visual emphasis
- Clear data

### Charts

1. **Line Chart**
   ```dart
   LineChart(
     LineChartData(
       // Weekly trends
       // Income/Expense lines
       // Clear labels
     ),
   )
   ```
   - Time trends
   - Dual metrics
   - Visual patterns

2. **Pie Charts**
   ```dart
   Widget _styledChartCard(String title, List<CategoryData> data, {
     required bool isExpense
   }) {
     // Category breakdown
     // Visual proportions
     // Clear labels
   }
   ```
   - Category splits
   - Visual ratios
   - Clear segments

## Best Practices Implemented

1. **Data Processing**
   - Clean aggregation
   - Efficient sorting
   - Clear structure

2. **Visualization**
   - Clear charts
   - Good colors
   - Proper labels

3. **User Experience**
   - Interactive elements
   - Visual feedback
   - Clear data

4. **Performance**
   - Efficient updates
   - Smooth rendering
   - Quick calculations

## Technical Considerations

1. **Data Handling**
   - Real-time updates
   - Clean aggregation
   - Error handling

2. **Chart Rendering**
   - Smooth drawing
   - Clear labels
   - Good performance

3. **State Management**
   - Data sync
   - Clean updates
   - Error recovery

4. **Layout**
   - Responsive design
   - Clear sections
   - Good organization

## Implementation Notes

1. **Data Structure**
   ```dart
   // Category data
   Map<String, double> totals = {};
   
   // Time series
   List<Map<String, double>> dailyData;
   ```
   - Clean organization
   - Efficient tracking
   - Easy updates

2. **Chart Setup**
   ```dart
   // Line chart
   LineChartData(
     gridData: FlGridData(...),
     titlesData: FlTitlesData(...),
     lineBarsData: [...],
   )
   
   // Pie chart
   PieChartData(
     sections: [...],
     centerSpaceRadius: 40,
   )
   ```
   - Clear configuration
   - Good defaults
   - Easy customization

3. **Layout Structure**
   ```dart
   CustomScrollView(
     slivers: [
       // Metrics grid
       // Weekly trends
       // Category breakdown
     ],
   )
   ```
   - Clean sections
   - Clear flow
   - Good organization

## Notes
- Financial analytics
- Visual insights
- Real-time updates
- Good practices
