import 'package:flutter/material.dart';

class SectionNavbar extends StatefulWidget {
  final bool isActive;
  final String label;
  final int number;
  final VoidCallback onChanged;
  
  const SectionNavbar({super.key, required this.isActive, required this.label, required this.number, required this.onChanged});

  @override
  State<SectionNavbar> createState() => _SectionNavbarState();
}

class _SectionNavbarState extends State<SectionNavbar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isActive;
    final Color backgroundColor = isActive
        ? const Color(0xFF1E40AF)
        : _isHovered
            ? const Color(0xFFE2E8F0)
            : const Color(0xFFF8FAFC);
    final Color borderColor = isActive ? const Color(0xFF1E40AF) : const Color(0xFFCBD5E1);
    final Color textColor = isActive ? Colors.white : const Color(0xFF0F172A);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() {
            _isHovered = false;
          });
        }
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _isHovered && !isActive ? 1.02 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? const Color(0xFF1E40AF).withOpacity(_isHovered ? 0.22 : 0.16)
                    : Colors.black.withOpacity(_isHovered ? 0.10 : 0.05),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onChanged,
              splashColor: const Color(0xFF1E40AF).withOpacity(0.10),
              highlightColor: const Color(0xFF1E40AF).withOpacity(0.05),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                  child: Text('${widget.label} ${widget.number}'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}