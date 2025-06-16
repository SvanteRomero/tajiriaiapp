import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

Future<void> getCategoryCreation(BuildContext context) {
  bool isExpanded = false;
  String iconSelected = '';
  Color categoryColor = Colors.white;
  TextEditingController categoryNameController = TextEditingController();

  List<String> myCategoriesIcons = ['entertainment', 'food', 'home', 'pet', 'shopping', 'tech', 'travel'];

  return showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Create a Category'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: categoryNameController,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                onTap: () {
                  isExpanded = !isExpanded;
                  Navigator.of(ctx).pop(); // Close the dialog to refresh
                  showDialog(
                    context: ctx,
                    builder: (ctx2) {
                      return AlertDialog(
                        title: const Text('Select an Icon'),
                        content: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 200,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 5,
                              crossAxisSpacing: 5,
                            ),
                            itemCount: myCategoriesIcons.length,
                            itemBuilder: (context, int i) {
                              return GestureDetector(
                                onTap: () {
                                  iconSelected = myCategoriesIcons[i];
                                  Navigator.of(ctx2).pop(); // Close icon selection dialog
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 3, color: iconSelected == myCategoriesIcons[i] ? Colors.green : Colors.grey),
                                    borderRadius: BorderRadius.circular(12),
                                    image: DecorationImage(image: AssetImage('assets/${myCategoriesIcons[i]}.png')),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Icon',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx2) {
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColorPicker(
                              pickerColor: categoryColor,
                              onColorChanged: (value) {
                                categoryColor = value;
                              },
                            ),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx2);
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Save Color',
                                  style: TextStyle(fontSize: 22, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: categoryColor,
                  hintText: 'Color',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    // Pure UI only - no backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Category created (UI only)')),
                    );
                    Navigator.of(ctx).pop(); // Close the dialog
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}