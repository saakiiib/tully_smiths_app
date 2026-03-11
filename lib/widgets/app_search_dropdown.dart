import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class AppSearchDropdown<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final String searchHint;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemAsString;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool Function(T, T)? compareFn;

  const AppSearchDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.itemAsString,
    required this.onChanged,
    this.label,
    this.searchHint = 'Search...',
    this.selectedItem,
    this.validator,
    this.compareFn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTextStyles.label),
          const SizedBox(height: 6),
        ],
        DropdownSearch<T>(
          items: items,
          selectedItem: selectedItem,
          itemAsString: itemAsString,
          onChanged: onChanged,
          validator: validator,
          compareFn: compareFn,
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.small,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            menuProps: MenuProps(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: AppTextStyles.small,
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}