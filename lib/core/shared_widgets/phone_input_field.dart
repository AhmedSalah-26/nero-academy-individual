import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:lms_platform/core/theme/app_colors.dart';

/// Unified Phone Input Field with Country Picker
/// Supports both light and dark themes
class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String initialCountryCode;
  final List<String> favoriteCountries;
  final ValueChanged<String>? onCountryCodeChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.initialCountryCode = 'EG',
    this.favoriteCountries = const ['EG', 'SA', 'AE', 'KW', 'QA'],
    this.onCountryCodeChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => PhoneInputFieldState();
}

class PhoneInputFieldState extends State<PhoneInputField> {
  late Country _selectedCountry;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry =
        CountryParser.parseCountryCode(widget.initialCountryCode);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _showCountryPicker() {
    if (!widget.enabled) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: widget.favoriteCountries,
      countryListTheme: CountryListThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
        textStyle: TextStyle(
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
        searchTextStyle: TextStyle(
          color: isDark ? AppColors.white : AppColors.textMainLight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        inputDecoration: InputDecoration(
          hintText: 'common.search'.tr(),
          hintStyle: TextStyle(
            color: isDark ? AppColors.grey500 : AppColors.grey400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppColors.grey400 : AppColors.grey500,
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : AppColors.grey50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
        widget.onCountryCodeChanged?.call('+${country.phoneCode}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : (isDark ? AppColors.grey700 : AppColors.grey200),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Country Code Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showCountryPicker,
                  borderRadius: context.locale.languageCode == 'ar'
                      ? const BorderRadius.only(
                          topRight: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${_selectedCountry.phoneCode}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.white
                                : AppColors.textMainLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.phone,
                  enabled: widget.enabled,
                  validator: widget.validator,
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.textMainLight,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'auth.phone_placeholder'.tr(),
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.grey500 : AppColors.grey400,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    errorStyle: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
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

  /// Get the current full phone number with country code
  String get fullPhoneNumber =>
      '+${_selectedCountry.phoneCode}${widget.controller.text}';

  /// Get the current country dial code
  String get countryDialCode => '+${_selectedCountry.phoneCode}';
}
