# Home Page Container (home_page.dart)

## Overview
This file implements the main container and navigation structure for the Tajiri AI application. It manages the bottom navigation bar and handles switching between different main sections of the app.

## Key Components

### HomePage Widget
```dart
class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});
}
```
- Main container
- Navigation management
- User context

### State Management

#### Navigation State
```dart
int selectedIndex = 0;
String pageTitle = "Home";
```
- Current page
- Title updates
- Navigation tracking

## Core Functionality

### Page Management
```dart
final List<Widget> pages = [
  Home(user: widget.user),
  Analytics(user: widget.user),
  Advisory(user: widget.user),
];
```
- Main sections
- User context
- Page organization

### Navigation Control
```dart
void setIndex(int index) {
  setState(() {
    selectedIndex = index;
    switch (selectedIndex) {
      case 0: pageTitle = "Home";
      case 1: pageTitle = "Analytics";
      case 2: pageTitle = "Advisory";
    }
  });
}
```
- Page selection
- Title updates
- State management

## UI Components

### App Bar
```dart
AppBar(
  title: Text(pageTitle),
  actions: [
    IconButton(
      icon: Icon(Icons.person),
      onPressed: () => Navigator.push(...),
    ),
  ],
)
```
- Title display
- Profile access
- Clean layout

### Bottom Navigation
```dart
BottomNavigationBar(
  currentIndex: selectedIndex,
  onTap: setIndex,
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home"
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: "Analytics"
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.lightbulb),
      label: "Advisory"
    ),
  ],
)
```
- Section navigation
- Visual feedback
- Clear labels

## Best Practices Implemented

1. **Navigation**
   - Clean flow
   - Visual feedback
   - Easy access

2. **State Management**
   - Clear tracking
   - Clean updates
   - Proper context

3. **User Experience**
   - Clear layout
   - Easy navigation
   - Quick access

4. **Code Organization**
   - Clean structure
   - Clear purpose
   - Good documentation

## Technical Considerations

1. **Navigation**
   - State preservation
   - Clean transitions
   - Context passing

2. **Performance**
   - Quick switching
   - Smooth transitions
   - Efficient updates

3. **User Context**
   - Auth preservation
   - Data access
   - State management

4. **Layout**
   - Clean structure
   - Clear navigation
   - Good organization

## Implementation Notes

1. **Page Structure**
   ```dart
   Scaffold(
     appBar: AppBar(...),
     bottomNavigationBar: BottomNavigationBar(...),
     body: pages[selectedIndex],
   )
   ```
   - Clean layout
   - Clear navigation
   - Proper structure

2. **Navigation Logic**
   ```dart
   void setIndex(int index) {
     // Update index
     // Update title
     // Refresh state
   }
   ```
   - Clean updates
   - Clear flow
   - Good feedback

3. **User Context**
   ```dart
   // Pass user to all pages
   Home(user: user)
   Analytics(user: user)
   Advisory(user: user)
   ```
   - Context passing
   - Data access
   - State preservation

## Notes
- Main container page
- Navigation management
- User context handling
- Clean implementation
