// lib/screens/manage_categories_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/models/user_category_model.dart';
import '/core/models/transaction_model.dart';
import '/core/services/firestore_service.dart';
import '/core/utils/snackbar_utils.dart';


class ManageCategoriesPage extends StatefulWidget {
  final User user;

  const ManageCategoriesPage({Key? key, required this.user}) : super(key: key);

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Categories"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCategoryDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<UserCategory>>(
        stream: _firestoreService.getUserCategories(widget.user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No custom categories yet.",
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(
                      "Tap the '+' button to add your first custom category!",
                      style: GoogleFonts.poppins(color: Colors.grey.shade500)),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }

          final categories = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.color.withOpacity(0.1),
                    child: Icon(category.icon, color: category.color),
                  ),
                  title: Text(category.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(category.type.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                    onPressed: () =>
                        _showAddEditCategoryDialog(category: category),
                  ),
                  onLongPress: () => _confirmAndDeleteCategory(category),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddEditCategoryDialog({UserCategory? category}) {
    final bool isEditing = category != null;
    final TextEditingController nameController =
        TextEditingController(text: isEditing ? category!.name : '');
    TransactionType selectedType =
        isEditing ? category!.type : TransactionType.expense;
    Color selectedColor =
        isEditing ? category!.color : Theme.of(context).primaryColor;
    IconData selectedIcon = isEditing ? category!.icon : Icons.category;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateInDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Category' : 'Add New Category'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.4,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Category Name'),
                        validator: (value) => value == null ||
                                value.trim().isEmpty
                            ? 'Please enter a name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TransactionType>(
                        value: selectedType,
                        decoration:
                            const InputDecoration(labelText: 'Category Type'),
                        items: TransactionType.values
                            .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name.toUpperCase())))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setStateInDialog(() {
                              selectedType = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text("Select Color"),
                        trailing: CircleAvatar(backgroundColor: selectedColor),
                        onTap: () async {
                          Color? newColor = await showDialog<Color>(
                            context: ctx,
                            builder: (colorDialogCtx) => AlertDialog(
                              title: const Text('Pick a color!'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (color) {
                                    selectedColor = color;
                                  },
                                  enableAlpha: false,
                                  displayThumbColor: true,
                                  paletteType: PaletteType.hueWheel,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('DONE'),
                                  onPressed: () {
                                    Navigator.of(colorDialogCtx)
                                        .pop(selectedColor);
                                  },
                                ),
                              ],
                            ),
                          );
                          if (newColor != null) {
                            setStateInDialog(() {
                              selectedColor = newColor;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newCategory = UserCategory(
                      id: isEditing ? category!.id : null,
                      name: nameController.text.trim(),
                      type: selectedType,
                      colorHex: selectedColor.value
                          .toRadixString(16)
                          .substring(2)
                          .toUpperCase(),
                      iconCodePoint: selectedIcon.codePoint.toString(),
                    );

                    try {
                      if (isEditing) {
                        await _firestoreService.updateUserCategory(
                            widget.user.uid, newCategory);
                        showCustomSnackbar(
                            context, 'Category updated successfully!');
                      } else {
                        await _firestoreService.addUserCategory(
                            widget.user.uid, newCategory);
                        showCustomSnackbar(
                            context, 'Category added successfully!');
                      }
                      Navigator.of(ctx).pop();
                    } catch (e) {
                      showCustomSnackbar(
                          context, 'Failed to save category. Please try again.',
                          type: SnackbarType.error);
                      print('Error saving category: $e');
                    }
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteCategory(UserCategory category) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: Text(
            "Are you sure you want to delete '${category.name}'? This action cannot be undone and transactions using this category will still refer to it."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteUserCategory(
            widget.user.uid, category.id!);
        showCustomSnackbar(context, 'Category deleted successfully!');
      } catch (e) {
        showCustomSnackbar(
            context, 'Failed to delete category. Please try again.',
            type: SnackbarType.error);
        print('Error deleting category: $e');
      }
    }
  }
}