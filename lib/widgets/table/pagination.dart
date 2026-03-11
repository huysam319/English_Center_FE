import 'dart:math';
import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  /// Trang hiện tại (bắt đầu từ 1).
  final int currentPage;

  /// Tổng số trang.
  final int totalPages;

  /// Callback khi chuyển trang.
  final ValueChanged<int> onPageChanged;

  /// Số nút trang tối đa hiển thị.
  final int maxVisiblePages;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.maxVisiblePages = 7,
  });

  @override
  Widget build(BuildContext context) {
    final pages = _getVisiblePages();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút Previous
          _buildTextButton(
            label: 'Previous',
            onPressed:
                currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          const SizedBox(width: 4),

          // Các nút số trang
          for (final page in pages) ...[
            if (page == -1)
              _buildEllipsis()
            else
              _buildPageButton(page),
            const SizedBox(width: 4),
          ],

          // Nút Next
          _buildTextButton(
            label: 'Next',
            onPressed:
                currentPage < totalPages
                    ? () => onPageChanged(currentPage + 1)
                    : null,
          ),
        ],
      ),
    );
  }

  /// Tính danh sách trang hiển thị. -1 đại diện cho dấu "...".
  List<int> _getVisiblePages() {
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final List<int> pages = [];
    final int half = (maxVisiblePages - 2) ~/ 2; // trừ first & last

    int start = max(2, currentPage - half);
    int end = min(totalPages - 1, currentPage + half);

    // Điều chỉnh nếu sát đầu hoặc cuối
    if (currentPage - half < 2) {
      end = min(totalPages - 1, maxVisiblePages - 1);
    }
    if (currentPage + half > totalPages - 1) {
      start = max(2, totalPages - maxVisiblePages + 2);
    }

    // Trang đầu
    pages.add(1);
    if (start > 2) pages.add(-1); // ellipsis

    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    if (end < totalPages - 1) pages.add(-1); // ellipsis
    // Trang cuối
    pages.add(totalPages);

    return pages;
  }

  /// Nút Previous / Next.
  Widget _buildTextButton({required String label, VoidCallback? onPressed}) {
    final bool disabled = onPressed == null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      hoverColor: const Color(0xFFE8F0FE),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: disabled ? Colors.grey.shade400 : const Color(0xFF1E40AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Nút số trang.
  Widget _buildPageButton(int page) {
    final bool isActive = page == currentPage;

    return InkWell(
      onTap: isActive ? null : () => onPageChanged(page),
      borderRadius: BorderRadius.circular(4),
      hoverColor: const Color(0xFFE8F0FE),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? const Color(0xFF1E40AF) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isActive ? const Color(0xFF1E40AF) : Colors.white,
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF1E40AF),
          ),
        ),
      ),
    );
  }

  /// Dấu "...".
  Widget _buildEllipsis() {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}
