import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleSelector extends StatefulWidget {
  const RoleSelector({super.key});

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  int selectedIndex = 0; // 0 = Học sinh, 1 = Giáo viên

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildItem(
          index: 0,
          icon: Icons.school_outlined,
          label: "Học sinh",
        ),
        _buildItem(
          index: 1,
          icon: Icons.person_outlined,
          label: "Giáo viên",
        ),
      ],
    );
  }

  Widget _buildItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: Colors.black,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Border dưới
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: double.infinity,
              color: isSelected ? Colors.blue : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}