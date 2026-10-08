import 'package:flutter/material.dart';

class AislePicker extends StatelessWidget {
  const AislePicker({
    super.key,
    required this.aisles,
    required this.selected,
    required this.onSelected,
  });

  final List<String> aisles;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: [
        for (final aisle in aisles)
          ButtonSegment(value: aisle, label: Text(aisle)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onSelected(selection.single),
    );
  }
}
