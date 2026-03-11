import 'package:flutter/material.dart';

import 'section_navbar.dart';

class SectionNavbarRow extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onChanged;

  const SectionNavbarRow({
    super.key,
    required this.activeSection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 1; i <= 3; i++)
          Expanded(
            child: SectionNavbar(
              isActive: activeSection == i,
              label: "Passage",
              number: i,
              onChanged: () => onChanged(i),
            ),
          ),
      ],
    );
  }
}