import 'package:flutter/material.dart';
import '../constants/colors.dart';

class FormDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final IconData prefixIcon;
  final bool isTablet;
  final VoidCallback? refreshBranch;

  const FormDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.prefixIcon,
    required this.isTablet,
    this.refreshBranch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                foreground: Paint()
                  ..shader = AppColors.primaryHorizontal.createShader(
                    const Rect.fromLTWH(0, 0, 200, 70),
                  ),
                fontFamily: 'Inter',
              ),
            ),
            IconButton(
              onPressed: refreshBranch,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xff0C8FB0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xff0C8FB0),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    prefixIcon,
                    color: const Color(0xff0C8FB0),
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: DropdownButton<T>(
                    value: value,
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onChanged,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.primary,
                    ),
                    iconEnabledColor: AppColors.primary.withOpacity(0.5),
                    dropdownColor: Colors.white,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
