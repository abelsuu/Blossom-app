import 'package:flutter/material.dart';

class MultiSelectDropdownWithChips extends StatelessWidget {
  final List<String> allItems;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;
  final String hint;
  final int maxSelection;

  const MultiSelectDropdownWithChips({
    super.key,
    required this.allItems,
    required this.selectedItems,
    required this.onChanged,
    this.hint = 'Select items',
    this.maxSelection = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint),
              icon: const Icon(Icons.arrow_drop_down),
              items:
                  allItems.map((item) {
                    final isSelected = selectedItems.contains(item);
                    return DropdownMenuItem<String>(
                      value: item,
                      enabled: !isSelected || selectedItems.length < maxSelection,
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: isSelected ? Colors.black : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (String? value) {
                if (value == null) return;

                final newSelected = List<String>.from(selectedItems);
                if (newSelected.contains(value)) {
                  // Already selected, do nothing or remove? 
                  // Usually dropdown click adds. Chips remove.
                  // But let's allow toggle behavior in dropdown for better UX
                  newSelected.remove(value);
                } else {
                  if (newSelected.length < maxSelection) {
                    newSelected.add(value);
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You can only select up to $maxSelection services'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                }
                onChanged(newSelected);
              },
              // Ensure the dropdown value is null so it acts as a trigger
              value: null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Selected Chips
        if (selectedItems.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedItems.map((item) {
                  return Chip(
                    label: Text(item),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onDeleted: () {
                      final newSelected = List<String>.from(selectedItems);
                      newSelected.remove(item);
                      onChanged(newSelected);
                    },
                  );
                }).toList(),
          ),
      ],
    );
  }
}
