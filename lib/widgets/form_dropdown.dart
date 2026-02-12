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

  const FormDropdown({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.prefixIcon,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  prefixIcon,
                  color: AppColors.primary.withOpacity(0.5),
                  size: 20,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    icon: const Icon(Icons.arrow_drop_down),
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
